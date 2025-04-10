import Foundation
import Firebase
import FirebaseFirestore

class DataService {
    static let shared = DataService()
    private let db = Firestore.firestore()
    
    // Collection references
    private let wordsCollection = "slangWords"
    private let usersCollection = "users"
    
    // MARK: - Word Operations
    
    func addWord(word: String, definition: String, userId: String, username: String) async throws -> String {
        let newWord = SlangWord(
            word: word,
            definition: definition,
            createdBy: userId,
            username: username,
            upvotes: 0,  // Explicitly set initial values
            downvotes: 0  // Explicitly set initial values
        )
        
        let ref = db.collection(wordsCollection).document()
        let wordData = newWord.toDictionary()
        
        // Print the data being saved for debugging
        print("Adding new word with data: \(wordData)")
        
        try await ref.setData(wordData)
        
        // Update the user's createdWords array
        do {
            try await db.collection(usersCollection).document(userId).updateData([
                "createdWords": FieldValue.arrayUnion([ref.documentID])
            ])
        } catch {
            print("Warning: Could not update user's createdWords: \(error.localizedDescription)")
            // Continue even if this fails - the word was still created
        }
        
        return ref.documentID
    }
    
    func getWords() async throws -> [SlangWord] {
        let snapshot = try await db.collection(wordsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { SlangWord(document: $0) }
    }
    
    func getTopWords(limit: Int = 10) async throws -> [SlangWord] {
        let snapshot = try await db.collection(wordsCollection)
            .order(by: "upvotes", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { SlangWord(document: $0) }
    }
    
    func debugVoteStatus(wordId: String) {
        let wordRef = db.collection(wordsCollection).document(wordId)
        
        wordRef.getDocument { document, error in
            if let error = error {
                print("Error retrieving word document: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let upvotes = document.data()?["upvotes"] as? Int ?? 0
                let downvotes = document.data()?["downvotes"] as? Int ?? 0
                print("Word ID: \(wordId)")
                print("Current upvotes in DB: \(upvotes)")
                print("Current downvotes in DB: \(downvotes)")
            } else {
                print("Document doesn't exist or couldn't be fetched")
            }
        }
    }
    
    func upvoteWord(wordId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let wordRef = db.collection(wordsCollection).document(wordId)
        
        // Log before update
        print("Attempting to upvote word: \(wordId)")
        self.debugVoteStatus(wordId: wordId)
        
        // Update only the upvotes field atomically
        wordRef.updateData([
            "upvotes": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating upvote count: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Upvote successful!")
                self.debugVoteStatus(wordId: wordId)
                
                // After successful upvote, try to update user's liked words
                let userRef = self.db.collection(self.usersCollection).document(userId)
                userRef.updateData([
                    "likedWords": FieldValue.arrayUnion([wordId])
                ]) { userError in
                    if let userError = userError {
                        print("Warning: Could not update user's liked words: \(userError.localizedDescription)")
                    }
                    // Return success even if user update failed
                    completion(nil)
                }
            }
        }
    }
    
    func downvoteWord(wordId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let wordRef = db.collection(wordsCollection).document(wordId)
        
        // Log before update
        print("Attempting to downvote word: \(wordId)")
        self.debugVoteStatus(wordId: wordId)
        
        // Update only the downvotes field atomically
        wordRef.updateData([
            "downvotes": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating downvote count: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Downvote successful!")
                self.debugVoteStatus(wordId: wordId)
                
                // After successful downvote, try to update user's disliked words
                let userRef = self.db.collection(self.usersCollection).document(userId)
                userRef.updateData([
                    "dislikedWords": FieldValue.arrayUnion([wordId])
                ]) { userError in
                    if let userError = userError {
                        print("Warning: Could not update user's disliked words: \(userError.localizedDescription)")
                    }
                    // Return success even if user update failed
                    completion(nil)
                }
            }
        }
    }
    
    // Function to fix old word documents that might be missing upvotes/downvotes fields
    func prepareOldWordDocuments() {
        let db = Firestore.firestore()
        let batch = db.batch()
        
        db.collection(wordsCollection).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }
            
            var updatedCount = 0
            
            for document in documents {
                let data = document.data()
                let docRef = self.db.collection(self.wordsCollection).document(document.documentID)
                
                // Check if upvotes or downvotes is missing or not an Integer
                if !(data["upvotes"] is Int) || !(data["downvotes"] is Int) {
                    // Initialize upvotes and downvotes as integers if they don't exist or aren't integers
                    batch.updateData([
                        "upvotes": 0,
                        "downvotes": 0
                    ], forDocument: docRef)
                    
                    updatedCount += 1
                }
            }
            
            if updatedCount > 0 {
                batch.commit { error in
                    if let error = error {
                        print("Error updating documents: \(error)")
                    } else {
                        print("Successfully updated \(updatedCount) documents")
                    }
                }
            } else {
                print("No documents needed updating")
            }
        }
    }
    
    // MARK: - User Operations
    
    func createUser(userId: String, username: String) async throws {
        let newUser = User(
            id: userId,
            username: username,
            createdWords: [],
            likedWords: [],
            dislikedWords: []
        )
        
        try await db.collection(usersCollection).document(userId).setData(newUser.toDictionary())
    }
    
    func getUserWords(userId: String) async throws -> [SlangWord] {
        let snapshot = try await db.collection(wordsCollection)
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { SlangWord(document: $0) }
    }
    
    func getNewestWords(since: Date) async throws -> [SlangWord] {
        let snapshot = try await db.collection(wordsCollection)
            .whereField("createdAt", isGreaterThan: Timestamp(date: since))
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.compactMap { SlangWord(document: $0) }
    }
    
    // MARK: - Preloaded Words
    
    func getPreloadedWords() -> [SlangWord] {
        return [
            SlangWord(id: "1", word: "Rizz", definition: "Charisma or the ability to attract a romantic partner through charm and communication", createdBy: "system", username: "SlangIt", upvotes: 125, downvotes: 15, createdAt: Date().addingTimeInterval(-86400 * 7)),
            
            SlangWord(id: "2", word: "Bussin", definition: "Extremely good, delicious, or exceptional, particularly used to describe food", createdBy: "system", username: "SlangIt", upvotes: 98, downvotes: 12, createdAt: Date().addingTimeInterval(-86400 * 6)),
            
            SlangWord(id: "3", word: "No Cap", definition: "No lie or telling the truth; used to emphasize honesty", createdBy: "system", username: "SlangIt", upvotes: 87, downvotes: 5, createdAt: Date().addingTimeInterval(-86400 * 5)),
            
            SlangWord(id: "4", word: "Tea", definition: "Gossip or juicy information worth talking about", createdBy: "system", username: "SlangIt", upvotes: 76, downvotes: 8, createdAt: Date().addingTimeInterval(-86400 * 4)),
            
            SlangWord(id: "5", word: "Slay", definition: "To do something exceptionally well or to look extremely good", createdBy: "system", username: "SlangIt", upvotes: 65, downvotes: 7, createdAt: Date().addingTimeInterval(-86400 * 3)),
            
            SlangWord(id: "6", word: "Boujee", definition: "High-class, fancy, luxurious, or associated with a higher socioeconomic status", createdBy: "system", username: "SlangIt", upvotes: 54, downvotes: 11, createdAt: Date().addingTimeInterval(-86400 * 2)),
            
            SlangWord(id: "7", word: "Bop", definition: "A song that is extremely catchy or enjoyable", createdBy: "system", username: "SlangIt", upvotes: 43, downvotes: 6, createdAt: Date().addingTimeInterval(-86400 * 1)),
            
            SlangWord(id: "8", word: "Yeet", definition: "To throw something forcefully or with great energy; can also express excitement", createdBy: "system", username: "SlangIt", upvotes: 39, downvotes: 14, createdAt: Date()),
            
            SlangWord(id: "9", word: "Flex", definition: "To show off or boast about something you have or can do", createdBy: "system", username: "SlangIt", upvotes: 32, downvotes: 4, createdAt: Date()),
            
            SlangWord(id: "10", word: "Vibe Check", definition: "An assessment of someone's mood or attitude, or the general atmosphere of a situation", createdBy: "system", username: "SlangIt", upvotes: 28, downvotes: 3, createdAt: Date())
        ]
    }
}
