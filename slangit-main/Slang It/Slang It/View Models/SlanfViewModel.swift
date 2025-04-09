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
    
    init() {
        // Immediately load preloaded words so UI isn't empty
        allWords = dataService.getPreloadedWords()
        currentWord = allWords.first
        
        // Then attempt to load from Firebase
        Task {
            await loadWords()
            await loadTopWords()
        }
    }
    
    @MainActor
    func loadWords() async {
        isLoading = true
        
        do {
            allWords = try await dataService.getWords()
            if !allWords.isEmpty {
                currentIndex = 0
                currentWord = allWords[currentIndex]
            } else {
                currentWord = nil
            }
        } catch {
            // If loading fails, ensure we still have preloaded words
            if allWords.isEmpty {
                allWords = dataService.getPreloadedWords()
                currentIndex = 0
                currentWord = allWords.first
            }
            errorMessage = "Failed to load words: \(error.localizedDescription)"
        }
        
        isLoading = false
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
            
            // Add to the beginning of the array
            allWords.insert(newWord, at: 0)
            
            // Reset the current index to show the new word
            currentIndex = 0
            currentWord = allWords[currentIndex]
            
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
        } else {
            // End of deck
            currentWord = nil
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
