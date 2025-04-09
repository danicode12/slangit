import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var isShowingTrending = false
    @State private var cardOffset: CGFloat = 0
    @State private var showingCard: SlangWord?
    @State private var nextCard: SlangWord?
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("discover new words")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 80)
                
                Spacer()
                
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundColor(.black)
                    } else if viewModel.currentWord == nil {
                        VStack {
                            Text("No more words!")
                                .font(.title)
                                .foregroundColor(.black)
                            
                            Button("Refresh") {
                                Task {
                                    await viewModel.loadWords()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                        }
                    } else if let currentWord = viewModel.currentWord {
                        // Show the card for the current word
                        SlangCard(
                            word: currentWord,
                            onSwipeLeft: {
                                viewModel.downvoteCurrentWord()
                            },
                            onSwipeRight: {
                                viewModel.upvoteCurrentWord()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                        .id(currentWord.id ?? UUID().uuidString) // Use ID to force view refresh
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
                
                Text("swipe right for slang, left for lame")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                
                HStack(spacing: 50) {
                    // Skip button (swipe left)
                    Button(action: {
                        viewModel.downvoteCurrentWord()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                    }
                    
                    // Like button (swipe right)
                    Button(action: {
                        viewModel.upvoteCurrentWord()
                    }) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 20)
                
                Button(action: {
                    isShowingTrending = true
                }) {
                    Text("words of the week")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                Spacer()
            }
        }
        .onAppear {
            if viewModel.allWords.isEmpty || viewModel.shouldRefreshDiscoverView {
                Task {
                    await viewModel.loadWords()
                    viewModel.shouldRefreshDiscoverView = false
                }
            }
        }
        .sheet(isPresented: $isShowingTrending) {
            TrendingView()
                .environmentObject(viewModel)
        }
    }
}
