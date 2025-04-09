import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = SlangViewModel()
    @State private var selectedTab: Tab = .discover
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DiscoverView()
                    .tag(Tab.discover)
                    .ignoresSafeArea()
                
                CreateView()
                    .tag(Tab.create)
                    .ignoresSafeArea()
                
                ProfileView()
                    .tag(Tab.profile)
                    .ignoresSafeArea()
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea()
        .environmentObject(viewModel)
        .onAppear {
            // Initialize user on app start
            viewModel.signIn()
        }
    }
}
