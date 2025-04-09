import SwiftUI

import Firebase

import FirebaseAuth



struct ContentView: View {

    @State private var isLoggedIn: Bool = false  // Track login state

    @State private var selectedTab: Tab = .discover

    @StateObject var viewModel = SlangViewModel()



    var body: some View {

        ZStack(alignment: .bottom) {

            // Show LoginView or SignUpView if the user is not logged in

            if !isLoggedIn {

                // Show LoginView or SignUpView based on your preference

                LoginView(isLoggedIn: $isLoggedIn)  // Pass binding to change login state

                // If you want to show SignUpView, replace above line with:

                // SignUpView(isLoggedIn: $isLoggedIn)

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
