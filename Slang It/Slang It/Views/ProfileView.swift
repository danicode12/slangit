import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    
    var body: some View {
        VStack {
            // Profile picture
            Circle()
                .fill(Color.white)
                .frame(width: 100, height: 100)
                .padding(.top, 80)
            
            Text("John Doe")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            Text("your slang")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            // Placeholder content for user's slang words
            ScrollView {
                VStack(spacing: 15) {
                    WordRow(word: "Rizz", votes: 13)
                    WordRow(word: "Meta", votes: 14)
                    WordRow(word: "Type", votes: 20)
                }
            }
            
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}

struct WordRow: View {
    let word: String
    let votes: Int
    
    var body: some View {
        HStack {
            Text(word)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(votes) votes")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.orange)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}
