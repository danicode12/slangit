import SwiftUI

struct TrendingView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
                
                VStack {
                    Text("Top 5 Slang Words")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    Text("this week's leaderboard")
                        .font(.system(size: 18, weight: .medium))
                        .italic()
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Spacer()
                    } else if viewModel.topWords.isEmpty {
                        Spacer()
                        Text("No trending words yet!")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        // Leaderboard display
                        VStack(spacing: 15) {
                            // Take only top 5 words
                            ForEach(Array(viewModel.topWords.prefix(5).enumerated()), id: \.element.id) { index, word in
                                LeaderboardRow(rank: index + 1, word: word)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .imageScale(.large)
            })
            .onAppear {
                Task {
                    await viewModel.loadTopWords()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let word: SlangWord
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word.uppercased())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: 10) {
                    Text("by @\(word.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                    
                    // Added upvotes display
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text("\(word.upvotes)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Trophy for first place
            if rank == 1 {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "FFD700")) // Gold color
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(Color(hex: "EDD377")) // Yellow background
        .cornerRadius(0) // No rounded corners to match other screens
    }
    
    // Different colors for different ranks
    var rankColor: Color {
        switch rank {
        case 1:
            return Color(hex: "FFD700") // Gold
        case 2:
            return Color(hex: "C0C0C0") // Silver
        case 3:
            return Color(hex: "CD7F32") // Bronze
        default:
            return Color(hex: "162959") // Dark blue (your app color)
        }
    }
}
