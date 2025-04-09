import SwiftUI

enum Tab: String, CaseIterable {
    case discover
    case create
    case profile
    
    var icon: String {
        switch self {
        case .discover: return "list.clipboard"
        case .create: return "plus.circle"
        case .profile: return "person"
        }
    }
    
    var title: String {
        return self.rawValue.capitalized
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                    
                    Text(tab == .create ? "create" : tab == .discover ? "discover" : "profile")
                        .font(.caption)
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                }
                .padding(.vertical, 10)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        selectedTab = tab
                    }
                }
                
                Spacer()
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: 60)
        .background(Color.black.opacity(0.2))
    }
}
