import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Binding var isLoggedIn: Bool  // This binding controls navigation to main app
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
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
            VStack(spacing: 0) {
                // Logo at the top
                Image("logo") // Make sure "logo" is the name of your image in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.top, 60)
                
                Spacer()
                    .frame(height: 10)
                
                // Create account text - moved to be right above the text fields
                Text("create account")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 30)
                
                VStack(spacing: 25) {
                    // Email field
                    VStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "EDD377"))
                                .cornerRadius(0)
                                .frame(height: 50)
                            
                            if email.isEmpty {
                                Text("email")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 15)
                            }
                            
                            TextField("", text: $email)
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Username field
                    VStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "EDD377"))
                                .cornerRadius(0)
                                .frame(height: 50)
                            
                            if username.isEmpty {
                                Text("username")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 15)
                            }
                            
                            TextField("", text: $username)
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .autocapitalization(.none)
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Password field
                    VStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "EDD377"))
                                .cornerRadius(0)
                                .frame(height: 50)
                            
                            if password.isEmpty {
                                Text("password")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 15)
                            }
                            
                            SecureField("", text: $password)
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Confirm Password field
                    VStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "EDD377"))
                                .cornerRadius(0)
                                .frame(height: 50)
                            
                            if confirmPassword.isEmpty {
                                Text("confirm password")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 15)
                            }
                            
                            SecureField("", text: $confirmPassword)
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Sign up button
                    Button(action: {
                        signUp()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(hex: "162959")) // Navy blue
                                .frame(height: 60)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("create account")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    .disabled(isLoading)
                }
                
                Spacer()
            }
        }
        .onDisappear {
            // This is important for cleanup when the view disappears
            if isLoading {
                isLoading = false
            }
        }
    }
    
    // Updated Sign-Up function using Firebase
    func signUp() {
        // Validation
        if username.isEmpty {
            errorMessage = "please enter a username"
            return
        }
        
        if email.isEmpty || password.isEmpty {
            errorMessage = "please fill in all fields"
            return
        }
        
        if password != confirmPassword {
            errorMessage = "passwords do not match"
            return
        }
        
        // Show loading state
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Firebase Auth Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "sign-up error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "failed to create user"
                }
                return
            }
            
            // Save the username to Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "username": self.username,
                "email": self.email,
                "createdWords": [],
                "likedWords": [],
                "dislikedWords": []
            ]
            
            db.collection("users").document(user.uid).setData(userData) { firestoreError in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let firestoreError = firestoreError {
                        print("Firestore Error: \(firestoreError.localizedDescription)")
                        self.errorMessage = "error saving profile data: \(firestoreError.localizedDescription)"
                        return
                    }
                    
                    print("User created successfully with ID: \(user.uid)")
                    print("User data saved successfully for: \(self.username)")
                    
                    // This is the critical line - set isLoggedIn to true AFTER successful account creation
                    self.isLoggedIn = true
                }
            }
        }
    }
}
