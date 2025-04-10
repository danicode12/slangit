import Foundation
import SwiftUI
import Combine

class SlangViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var allWords: [SlangWord] = []
    @Published var topWords: [SlangWord] = []
    @Published var userWords: [SlangWord] = []
    @Published var currentWord: SlangWord?
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldRefreshDiscoverView = false
    
    // User info - in a real app, get this from authentication
    private let userId = UUID().uuidString
    private let username = "User\(Int.random(in: 1000...9999))"
    
    private let dataService = DataService.shared
    private var refreshTimer: Timer?
    private var lastWordsFetchTime: Date = .distantPast
    private let refreshInterval: TimeInterval = 60 // Refresh every minute
    
    init() {
        // Immediately load preloaded words so UI isn't empty
        allWords = dataService.getPreloadedWords().shuffled()
        currentWord = allWords.first
        
        // Fix any older documents that might be missing upvotes/downvotes fields
        dataService.prepareOldWordDocuments()
        
        // Then attempt to load from Firebase
        Task {
            await loadWords()
            await loadTopWords()
        }
        
        // Set up periodic refresh timer
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkForNewWords()
            }
        }
    }
    
    @MainActor
    func checkForNewWords() async {
        // Only check for new words if we're not already loading
        guard !isLoading else { return }
        
        do {
            // Get the newest words since our last fetch
            let newWords = try await dataService.getNewestWords(since: lastWordsFetchTime)
            lastWordsFetchTime = Date()
            
            if !newWords.isEmpty {
                print("Found \(newWords.count) new words since last refresh")
                
                // Add new words to our existing list, avoiding duplicates
                let existingIds = Set(allWords.compactMap { $0.id })
                let uniqueNewWords = newWords.filter { word in
                    guard let id = word.id else { return false }
                    return !existingIds.contains(id)
                }
                
                if !uniqueNewWords.isEmpty {
                    // Add new words and completely reshuffle the deck
                    var updatedWords = allWords
                    updatedWords.append(contentsOf: uniqueNewWords)
                    
                    // Perform complete randomization
                    allWords = randomizeWordsWithPriority(updatedWords)
                    
                    // Reset to beginning after reshuffling
                    currentIndex = 0
                    currentWord = allWords.first
                }
            }
        } catch {
            print("Error checking for new words: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadWords() async {
        isLoading = true
        
        do {
            let words = try await dataService.getWords()
            lastWordsFetchTime = Date()
            
            if !words.isEmpty {
                // Completely randomize the order with priority
                allWords = randomizeWordsWithPriority(words)
                currentIndex = 0
                currentWord = allWords.first
            } else {
                currentWord = nil
            }
        } catch {
            // If loading fails, ensure we still have preloaded words
            if allWords.isEmpty {
                let preloaded = dataService.getPreloadedWords()
                allWords = randomizeWordsWithPriority(preloaded)
                currentIndex = 0
                currentWord = allWords.first
            }
            errorMessage = "Failed to load words: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func randomizeWordsWithPriority(_ words: [SlangWord]) -> [SlangWord] {
        // Split into recent user words (last 24 hours) and older words
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400) // 24 hours ago
        
        // Recent user words get highest priority
        let recentUserWords = words.filter {
            $0.createdBy != "system" && $0.createdAt > oneDayAgo
        }
        
        // Older user words get medium priority
        let olderUserWords = words.filter {
            $0.createdBy != "system" && $0.createdAt <= oneDayAgo
        }
        
        // System words get lowest priority
        let systemWords = words.filter { $0.createdBy == "system" }
        
        // Shuffle each group individually
        let shuffledRecentUserWords = recentUserWords.shuffled()
        let shuffledOlderUserWords = olderUserWords.shuffled()
        let shuffledSystemWords = systemWords.shuffled()
        
        // For extra randomness, decide if we should intermix some words
        let shouldIntermix = Bool.random()
        
        if shouldIntermix && !shuffledOlderUserWords.isEmpty && !shuffledSystemWords.isEmpty {
            // Create a truly randomized list but with recent user words at the front
            var finalList = shuffledRecentUserWords
            
            // Combine and shuffle older user words and system words
            var remainingWords = shuffledOlderUserWords + shuffledSystemWords
            remainingWords.shuffle()
            
            finalList.append(contentsOf: remainingWords)
            return finalList
        } else {
            // Simple priority-based order with each group shuffled
            return shuffledRecentUserWords + shuffledOlderUserWords + shuffledSystemWords
        }
    }
    
    @MainActor
    func loadTopWords() async {
        do {
            topWords = try await dataService.getTopWords()
        } catch {
            // Ensure top words has data even if Firebase fails
            if topWords.isEmpty {
                let preloaded = dataService.getPreloadedWords()
                topWords = Array(preloaded.sorted(by: { $0.upvotes > $1.upvotes }).prefix(10))
            }
            errorMessage = "Failed to load top words: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadUserWords() async {
        do {
            userWords = try await dataService.getUserWords(userId: userId)
        } catch {
            errorMessage = "Failed to load your words: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func addWord(word: String, definition: String) async -> Bool {
        guard !word.isEmpty, !definition.isEmpty else {
            errorMessage = "Word and definition cannot be empty"
            return false
        }
        
        do {
            let newWordId = try await dataService.addWord(
                word: word,
                definition: definition,
                userId: userId,
                username: username
            )
            
            // Create a new word locally and add it to the array
            let newWord = SlangWord(
                id: newWordId,
                word: word,
                definition: definition,
                createdBy: userId,
                username: username,
                upvotes: 0,
                downvotes: 0,
                createdAt: Date()
            )
            
            // Insert the new word and reshuffle everything
            var updatedWords = allWords
            updatedWords.insert(newWord, at: 0) // Put new word at position 0
            allWords = randomizeWordsWithPriority(updatedWords)
            
            // Reset to show the newly added word first
            currentIndex = allWords.firstIndex(where: { $0.id == newWordId }) ?? 0
            currentWord = allWords[currentIndex]
            
            // Update lastWordsFetchTime
            lastWordsFetchTime = Date()
            
            // Trigger a refresh on the discover view
            shouldRefreshDiscoverView = true
            
            return true
        } catch {
            errorMessage = "Failed to add word: \(error.localizedDescription)"
            return false
        }
    }
    
    @MainActor
    func upvoteCurrentWord() {
        guard let currentWord = currentWord, let wordId = currentWord.id else { return }
        
        // Update local data immediately for better UX
        if let index = allWords.firstIndex(where: { $0.id == wordId }) {
            allWords[index].upvotes += 1
        }
        
        // Capture current word for the API call
        let votedWordId = wordId
        
        // Move to next card immediately for better UX
        moveToNextCard()
        
        // Make the API call after
        dataService.upvoteWord(wordId: votedWordId, userId: userId) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.errorMessage = "Failed to upvote: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    func downvoteCurrentWord() {
        guard let currentWord = currentWord, let wordId = currentWord.id else { return }
        
        // Update local data immediately for better UX
        if let index = allWords.firstIndex(where: { $0.id == wordId }) {
            allWords[index].downvotes += 1
        }
        
        // Capture current word for the API call
        let votedWordId = wordId
        
        // Move to next card immediately for better UX
        moveToNextCard()
        
        // Make the API call after
        dataService.downvoteWord(wordId: votedWordId, userId: userId) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.errorMessage = "Failed to downvote: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func moveToNextCard() {
        if currentIndex < allWords.count - 1 {
            currentIndex += 1
            currentWord = allWords[currentIndex]
            
            // If we're getting near the end, refresh to get new words
            if currentIndex > allWords.count - 5 {
                Task {
                    await checkForNewWords()
                }
            }
        } else {
            // End of deck - try to get new words
            Task {
                await checkForNewWords()
                
                // If we got new words, reset index to show them
                if allWords.count > 0 {
                    await MainActor.run {
                        // Completely reshuffle before starting again
                        allWords = randomizeWordsWithPriority(allWords)
                        currentIndex = 0
                        currentWord = allWords[currentIndex]
                    }
                } else {
                    // No new words, show end state
                    await MainActor.run {
                        currentWord = nil
                    }
                }
            }
        }
    }
    
    // Mock authentication for demonstration purposes
    func signIn() {
        // Mock sign in
        Task {
            do {
                try await dataService.createUser(userId: userId, username: username)
            } catch {
                print("Error creating user: \(error.localizedDescription)")
            }
        }
    }
}
