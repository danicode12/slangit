import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn: Bool = false  // Track login state
    @State private var showingSignUp: Bool = false  // Toggle between login and signup
    @State private var selectedTab: Tab = .discover
    @StateObject var viewModel = SlangViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Show auth views if not logged in
            if !isLoggedIn {
                if showingSignUp {
                    SignUpView(isLoggedIn: $isLoggedIn)
                        .transition(.opacity)
                        .animation(.default, value: showingSignUp)
                        .overlay(
                            Button(action: {
                                showingSignUp = false
                            }) {
                                Text("already have an account? log in")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "162959"))
                                    .underline()
                            }
                            .padding(.bottom, 30),
                            alignment: .bottom
                        )
                } else {
                    LoginView(isLoggedIn: $isLoggedIn, showingSignUp: $showingSignUp)
                        .transition(.opacity)
                        .animation(.default, value: showingSignUp)
                        // No overlay button here anymore
                }
            } else {
                // Main app content
                TabView(selection: $selectedTab) {
                    DiscoverView()
                        .tag(Tab.discover)
                        .ignoresSafeArea()

                    CreateView()
                        .tag(Tab.create)
                        .ignoresSafeArea()

                    ProfileView(isLoggedIn: $isLoggedIn)  // Pass the binding to ProfileView
                        .tag(Tab.profile)
                        .ignoresSafeArea()
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea()
        .environmentObject(viewModel)
        .onAppear {
            // Check if the user is logged in and update the state
            if Auth.auth().currentUser != nil {
                isLoggedIn = true
            }
        }
    }
}
