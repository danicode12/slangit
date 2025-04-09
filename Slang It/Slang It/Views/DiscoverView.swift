import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var isShowingTrending = false
    @State private var cardOffset: CGFloat = 0
    @State private var showingCard: SlangWord?
    @State private var nextCard: SlangWord?
    
    var body: some View {
        ZStack {
            // Background with notebook paper effect
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
            
            VStack(spacing: 20) {
                Text("new words")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 80)
                
                Spacer().frame(height: 30)
                
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
                            .background(Color(hex: "162959"))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .padding(.top, 20)
                        }
                    } else if let currentWord = viewModel.currentWord {
                        // Custom slang card to match the design
                        VStack(alignment: .leading, spacing: 0) {
                            // Yellow card
                            VStack(alignment: .leading, spacing: 10) {
                                // Word in bold, large text
                                Text(currentWord.word.uppercased())
                                    .font(.system(size: 48, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.bottom, 20)
                                
                                // Definition
                                Text(currentWord.definition)
                                    .font(.system(size: 22))
                                    .foregroundColor(.black)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(30)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .background(Color(hex: "EDD377"))
                            .cornerRadius(0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 400)
                        .padding(.horizontal, 20)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    cardOffset = gesture.translation.width
                                }
                                .onEnded { gesture in
                                    withAnimation(.spring()) {
                                        if cardOffset > 100 {
                                            // Swipe right - upvote
                                            viewModel.upvoteCurrentWord()
                                        } else if cardOffset < -100 {
                                            // Swipe left - downvote
                                            viewModel.downvoteCurrentWord()
                                        }
                                        cardOffset = 0
                                    }
                                }
                        )
                        .offset(x: cardOffset)
                        .rotationEffect(.degrees(Double(cardOffset) * 0.05))
                        .animation(.spring(), value: cardOffset)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                        .id(currentWord.id ?? UUID().uuidString) // Use ID to force view refresh
                    }
                }
                .frame(height: 400)
                
                Text("swipe right for slang, left for lame")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
                Spacer()
                
                Button(action: {
                    isShowingTrending = true
                }) {
                    Text("words of the week")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(width: 250)
                        .background(Color(hex: "162959"))
                        .cornerRadius(25)
                }
                .padding(.bottom, 50)
                
                Spacer()
            }
            .padding(.horizontal)
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

// SlangCard is no longer needed as a separate component
// since we're implementing the card directly in the view

// Note: Color hex extension is defined in CreateView.swift
