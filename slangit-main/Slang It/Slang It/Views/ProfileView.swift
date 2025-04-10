import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @Binding var isLoggedIn: Bool
    @State private var username: String = "Loading..."
    @State private var userWords: [WordData] = []  // To store user's slang words
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            // Notebook paper background
            ZStack {
                // Base paper color
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                // Horizontal lines - evenly spaced across the screen
                VStack(spacing: 24) {
                    ForEach(0..<30, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 36) // Offset to start lines in the right position
                
                // Red margin line
                HStack {
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 1)
                        .padding(.leading, 35)
                    Spacer()
                }
            }
            
            // Content
            VStack {
                // Profile picture
                Circle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                    .padding(.top, 80)
                
                Text(username)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text("your slang")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                
                // User's slang words
                if isLoading {
                    ProgressView()
                        .padding()
                } else if userWords.isEmpty {
                    Text("You haven't created any slang words yet!")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(userWords, id: \.id) { wordData in
                                WordRow(word: wordData.word, votes: wordData.votes)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // Logout button
                Button(action: {
                    logout()
                }) {
                    Text("Logout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
                
                Spacer()
            }
        }
        .onAppear {
            fetchUserData()  // Load username and user's words when view appears
        }
    }
    
    // Fetch user data from Firestore
    func fetchUserData() {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document, document.exists {
                if let username = document.data()?["username"] as? String {
                    self.username = username
                } else {
                    self.username = "User"  // Fallback
                }
                
                // Fetch user's created words
                if let createdWordIds = document.data()?["createdWords"] as? [String] {
                    if createdWordIds.isEmpty {
                        self.userWords = []
                        self.isLoading = false
                    } else {
                        self.fetchWords(wordIds: createdWordIds)
                    }
                } else {
                    self.userWords = []
                    self.isLoading = false
                }
            } else {
                print("User document doesn't exist")
                self.username = "User"
                self.isLoading = false
            }
        }
    }
    
    // Fetch word details based on IDs
    func fetchWords(wordIds: [String]) {
        let db = Firestore.firestore()
        let wordsCollection = db.collection("slangWords") // Using the correct collection name
        
        var fetchedWords: [WordData] = []
        let group = DispatchGroup()
        
        for wordId in wordIds {
            group.enter()
            
            wordsCollection.document(wordId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching word \(wordId): \(error)")
                    return
                }
                
                if let document = document, document.exists, let data = document.data() {
                    let word = data["word"] as? String ?? "Unknown"
                    let definition = data["definition"] as? String ?? ""
                    // Using upvotes and downvotes fields from your database
                    let upvotes = data["upvotes"] as? Int ?? 0
                    let downvotes = data["downvotes"] as? Int ?? 0
                    let votes = upvotes - downvotes
                    
                    let wordData = WordData(
                        id: wordId,
                        word: word,
                        definition: definition,
                        votes: votes
                    )
                    
                    fetchedWords.append(wordData)
                }
            }
        }
        
        group.notify(queue: .main) {
            // Sort words by votes (highest first)
            self.userWords = fetchedWords.sorted(by: { $0.votes > $1.votes })
            self.isLoading = false
        }
    }
    
    // Logout function
    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false  // Update the login state to return to login page
            print("User successfully logged out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// Model to store word data - simplified to match your structure
struct WordData {
    let id: String
    let word: String
    let definition: String
    let votes: Int
}

struct WordRow: View {
    let word: String
    let votes: Int
    
    var body: some View {
        HStack {
            Text(word)
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
            
            Text("\(votes) votes")
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color(hex: "EDD377"))
        .cornerRadius(0) // Remove corner radius to match the design of other screens
        .padding(.horizontal)
    }
}
