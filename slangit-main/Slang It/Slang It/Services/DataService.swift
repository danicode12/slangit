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
            username: username
        )
        
        let ref = db.collection(wordsCollection).document()
        try await ref.setData(newWord.toDictionary())
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
    
    func upvoteWord(wordId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let wordRef = db.collection(wordsCollection).document(wordId)
        let userRef = db.collection(usersCollection).document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let wordDocument: DocumentSnapshot
            
            do {
                wordDocument = try transaction.getDocument(wordRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let word = SlangWord(document: wordDocument) else {
                let error = NSError(
                    domain: "DataService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse word document"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            // Update upvotes count
            transaction.updateData(["upvotes": word.upvotes + 1], forDocument: wordRef)
            
            // Update user liked words
            transaction.updateData([
                "likedWords": FieldValue.arrayUnion([wordId])
            ], forDocument: userRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
    
    func downvoteWord(wordId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let wordRef = db.collection(wordsCollection).document(wordId)
        let userRef = db.collection(usersCollection).document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let wordDocument: DocumentSnapshot
            
            do {
                wordDocument = try transaction.getDocument(wordRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let word = SlangWord(document: wordDocument) else {
                let error = NSError(
                    domain: "DataService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse word document"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            // Update downvotes count
            transaction.updateData(["downvotes": word.downvotes + 1], forDocument: wordRef)
            
            // Update user disliked words
            transaction.updateData([
                "dislikedWords": FieldValue.arrayUnion([wordId])
            ], forDocument: userRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
    
    // MARK: - User Operations
    
    func createUser(userId: String, username: String) async throws {
        let newUser = User(
            id: userId,
            username: username
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
