import SwiftUI

import FirebaseAuth

import FirebaseFirestore  // Added for Firestore functionality



struct ProfileView: View {

    @EnvironmentObject var viewModel: SlangViewModel

    @Binding var isLoggedIn: Bool

    @State private var username: String = "Loading..."  // Default text while loading

    

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

                

                // Placeholder content for user's slang words

                ScrollView {

                    VStack(spacing: 15) {

                        WordRow(word: "Rizz", votes: 13)

                        WordRow(word: "Meta", votes: 14)

                        WordRow(word: "Type", votes: 20)

                    }

                    .padding(.bottom, 20)

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

                .padding(.bottom, 20)

                

                Spacer()

            }

        }

        .onAppear {

            fetchUserData()  // Load username when view appears

        }

    }

    

    // Fetch user data from Firestore

    func fetchUserData() {

        guard let userId = Auth.auth().currentUser?.uid else {

            print("No user logged in")

            return

        }

        

        let db = Firestore.firestore()

        db.collection("users").document(userId).getDocument { document, error in

            if let error = error {

                print("Error fetching user data: \(error.localizedDescription)")

                return

            }

            

            if let document = document, document.exists {

                print("Document data: \(document.data() ?? [:])")  // Debug print

                if let username = document.data()?["username"] as? String {

                    self.username = username

                    print("Username loaded: \(username)")  // Debug print

                } else {

                    print("Username field not found in document")

                    self.username = "User"  // Fallback

                }

            } else {

                print("User document doesn't exist")

                self.username = "User"  // Fallback if no username is found

            }

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
