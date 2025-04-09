import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @Binding var isLoggedIn: Bool  // Binding to update login state
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""  // Added username field
    @State private var isSignUp: Bool = false  // Toggle between Sign-In and Sign-Up
    @State private var errorMessage: String = ""  // For displaying errors
    
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
                Text(isSignUp ? "create account" : "welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 80)
                
                Spacer()
                
                VStack(spacing: 25) {
                    // Custom email field
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
                    
                    // Custom password field
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
                    
                    // Username field (only in sign-up mode)
                    if isSignUp {
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
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
                    }
                    
                    // Login/Signup button
                    Button(action: {
                        isSignUp ? signUp() : login()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(hex: "162959")) // Navy blue
                                .frame(height: 60)
                            
                            Text(isSignUp ? "create account" : "login")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Toggle between login and signup
                    Button(action: {
                        isSignUp.toggle()
                        errorMessage = ""
                    }) {
                        Text(isSignUp ? "already have an account? log in" : "don't have an account? sign up")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "162959"))
                            .underline()
                    }
                    .padding(.top, 30)
                }
                
                Spacer()
            }
        }
    }
    
    // Sign-Up function using Firebase
    func signUp() {
        if username.isEmpty && isSignUp {
            errorMessage = "please enter a username"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "sign-up error: \(error.localizedDescription)"
                return
            }
            
            // Save the username to Firestore
            if let userId = result?.user.uid {
                let db = Firestore.firestore()
                db.collection("users").document(userId).setData([
                    "username": username,
                    "createdWords": [],
                    "likedWords": [],
                    "dislikedWords": []
                ]) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                        return
                    }
                    
                    // Successfully signed up and saved user data
                    print("User signed up and data saved successfully")
                    isLoggedIn = true
                }
            }
        }
    }
    
    // For the login function
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { [self] result, error in
            if let error = error {
                errorMessage = "login error: \(error.localizedDescription)"
                return
            }
            // Successfully logged in
            print("User logged in successfully")
            DispatchQueue.main.async {
                self.isLoggedIn = true  // Ensure UI update happens on main thread
            }
        }
    }
}
