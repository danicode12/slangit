import SwiftUI

enum Tab: String, CaseIterable {
    case discover
    case create
    case profile
    
    var icon: String {
        switch self {
        case .discover: return "pencil"         // Left icon (pencil)
        case .create: return "target"           // Middle icon (target/bullseye)
        case .profile: return "person.fill"     // Right icon (person)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(UIColor(red: 10/255, green: 30/255, blue: 80/255, alpha: 1)))
                    .frame(height: 25)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedTab = tab
                        }
                    }
                
                Spacer()
            }
        }
        .frame(width: 200, height: 50)
        .background(
            Capsule()
                .fill(Color(UIColor(red: 220/255, green: 180/255, blue: 80/255, alpha: 1))) // Gold/yellow color
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .padding(.bottom, 20)
    }
}
