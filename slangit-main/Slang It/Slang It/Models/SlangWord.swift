import Foundation
import FirebaseFirestore

struct SlangWord: Identifiable, Codable {
    var id: String?  // Changed to optional
    var word: String
    var definition: String
    var createdBy: String
    var username: String
    var upvotes: Int
    var downvotes: Int
    var createdAt: Date
    
    var totalVotes: Int {
        return upvotes - downvotes
    }
    
    // Initialize from Firebase document
    init?(document: DocumentSnapshot) {
        self.id = document.documentID
        
        guard let data = document.data() else { return nil }
        
        self.word = data["word"] as? String ?? ""
        self.definition = data["definition"] as? String ?? ""
        self.createdBy = data["createdBy"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.upvotes = data["upvotes"] as? Int ?? 0
        self.downvotes = data["downvotes"] as? Int ?? 0
        
        // Handle date conversion
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
    }
    
    // Initialize manually
    init(id: String? = nil, word: String, definition: String, createdBy: String, username: String, upvotes: Int = 0, downvotes: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.word = word
        self.definition = definition
        self.createdBy = createdBy
        self.username = username
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.createdAt = createdAt
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "word": word,
            "definition": definition,
            "createdBy": createdBy,
            "username": username,
            "upvotes": upvotes,
            "downvotes": downvotes,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

struct User: Identifiable, Codable {
    var id: String?  // Changed to optional
    var username: String
    var createdWords: [String] // IDs of created words
    var likedWords: [String] // IDs of liked words
    var dislikedWords: [String] // IDs of disliked words
    
    // Initialize from Firebase document
    init?(document: DocumentSnapshot) {
        self.id = document.documentID
        
        guard let data = document.data() else { return nil }
        
        self.username = data["username"] as? String ?? ""
        self.createdWords = data["createdWords"] as? [String] ?? []
        self.likedWords = data["likedWords"] as? [String] ?? []
        self.dislikedWords = data["dislikedWords"] as? [String] ?? []
    }
    
    // Initialize manually
    init(id: String? = nil, username: String, createdWords: [String] = [], likedWords: [String] = [], dislikedWords: [String] = []) {
        self.id = id
        self.username = username
        self.createdWords = createdWords
        self.likedWords = likedWords
        self.dislikedWords = dislikedWords
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "username": username,
            "createdWords": createdWords,
            "likedWords": likedWords,
            "dislikedWords": dislikedWords
        ]
    }
}
