import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct CreateView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var alertMessage = "your new word is out!"
    @FocusState private var isWordFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Notebook paper background
            VStack(spacing: 0) {
                // Content with notebook paper styling
                VStack {
                    Text("feeling creative?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 80)
                    
                    Spacer()
                    
                    // First text field - word input with custom styling
                    VStack(alignment: .leading, spacing: 15) {
                        // Custom text field implementation for better placeholder visibility
                        ZStack(alignment: .leading) {
                            if word.isEmpty {
                                Text("type a new word...")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            TextField("", text: $word)
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.black)
                                .focused($isWordFocused)
                                .submitLabel(.done) // Changes return key to "Done"
                                .onSubmit {
                                    isWordFocused = false
                                }
                        }
                        .padding(.bottom, 10)
                        
                        // Definition input with proper yellow background - iOS compatible version
                        ZStack(alignment: .topLeading) {
                            // Yellow background rectangle that fills the entire area
                            Rectangle()
                                .fill(Color(hex: "EDD377"))
                                .frame(height: 200)
                            
                            // Custom TextEditor wrapper to force yellow background
                            YellowBackgroundTextEditor(text: $definition)
                                .frame(height: 200)
                            
                            // This is for the placeholder text
                            if definition.isEmpty {
                                Text("what does it mean?")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.top, 15)
                                    .padding(.leading, 15)
                                    .zIndex(1) // Ensure placeholder is above the TextEditor
                            }
                        }
                        .frame(height: 200)
                        
                        // Submit button - navy blue button
                        Button(action: {
                            // Dismiss keyboard when submitting
                            hideKeyboard()
                            addNewWord()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(hex: "162959")) // Navy blue
                                    .frame(height: 60)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("slang it")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.top, 20)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .background(
                    ZStack {
                        // Base paper color
                        Color.white
                        
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
                )
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                hideKeyboard()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Word Added"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func hideKeyboard() {
        isWordFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func addNewWord() {
        // Validate inputs
        if word.isEmpty || definition.isEmpty {
            alertMessage = "Please enter both a word and definition"
            showAlert = true
            return
        }
        
        // Show loading indicator
        isLoading = true
        
        // Check if user is logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            alertMessage = "You must be logged in to add words"
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        
        // Get the current username
        db.collection("users").document(userId).getDocument { userDocument, userError in
            if let userError = userError {
                handleError("Error getting user info: \(userError.localizedDescription)")
                return
            }
            
            let username = userDocument?.data()?["username"] as? String ?? "Unknown"
            
            // 1. Create the new word document
            let newWordRef = db.collection("slangWords").document()
            let wordData: [String: Any] = [
                "word": word,
                "definition": definition,
                "upvotes": 0,
                "downvotes": 0,
                "createdAt": Timestamp(),
                "createdBy": userId,
                "username": username
            ]
            
            newWordRef.setData(wordData) { error in
                if let error = error {
                    handleError("Error adding word: \(error.localizedDescription)")
                    return
                }
                
                // 2. Update the user's createdWords array
                let userRef = db.collection("users").document(userId)
                
                // First check if the createdWords array exists
                userRef.getDocument { document, error in
                    if let error = error {
                        handleError("Error checking user document: \(error.localizedDescription)")
                        return
                    }
                    
                    if let document = document, document.exists {
                        // If createdWords doesn't exist yet, initialize it
                        if document.data()?["createdWords"] == nil {
                            userRef.updateData([
                                "createdWords": [newWordRef.documentID]
                            ]) { error in
                                if let error = error {
                                    handleError("Error initializing createdWords: \(error.localizedDescription)")
                                    return
                                }
                                handleSuccess()
                            }
                        } else {
                            // If it exists, add to it using arrayUnion
                            userRef.updateData([
                                "createdWords": FieldValue.arrayUnion([newWordRef.documentID])
                            ]) { error in
                                if let error = error {
                                    handleError("Error updating createdWords: \(error.localizedDescription)")
                                    return
                                }
                                handleSuccess()
                            }
                        }
                    } else {
                        handleError("User document not found")
                    }
                }
            }
        }
    }
    
    // Helper functions to handle success and error cases
    private func handleSuccess() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.word = ""
            self.definition = ""
            self.alertMessage = "Your slang word has been added!"
            self.showAlert = true
            print("Word successfully added and user document updated")
        }
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.alertMessage = message
            self.showAlert = true
            print(message)
        }
    }
}

// Custom wrapper for TextEditor to ensure yellow background with keyboard dismissal
struct YellowBackgroundTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor(red: 237/255, green: 211/255, blue: 119/255, alpha: 1.0) // EDD377
        textView.textColor = .black
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        // Configure return key to be "Done"
        textView.returnKeyType = .done
        
        // Make it dismiss on Done press
        textView.enablesReturnKeyAutomatically = false
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: YellowBackgroundTextEditor
        weak var currentTextView: UITextView?
        
        init(_ parent: YellowBackgroundTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            self.currentTextView = textView
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.currentTextView = textView
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // If return key was pressed, dismiss keyboard
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}
