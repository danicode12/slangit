import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @Binding var isLoggedIn: Bool  // Binding to update login state
    @Binding var showingSignUp: Bool  // NEW: Binding to toggle signup view
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var errorMessage: String = ""
    
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
                
                // Welcome back text - moved to be right above the text fields
                Text("welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 30)
                
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
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
                    }
                    
                    // Login button
                    Button(action: {
                        login()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(hex: "162959")) // Navy blue
                                .frame(height: 60)
                            
                            Text("login")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Toggle to signup view - THIS IS THE IMPORTANT CHANGE
                    Button(action: {
                        showingSignUp = true  // Use the new binding instead of a local state
                        errorMessage = ""
                    }) {
                        Text("don't have an account? sign up")
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
