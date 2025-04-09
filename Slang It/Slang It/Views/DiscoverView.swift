import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var isShowingTrending = false
    @State private var cardOffset: CGFloat = 0
    @State private var showingCard: SlangWord?
    @State private var nextCard: SlangWord?
    
    // States for emoji animations
    @State private var showFireEmojis = false
    @State private var showXEmojis = false
    @State private var emojiPositions: [CGPoint] = []
    @State private var animationId = UUID() // To force animation refresh
    
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
                                    // First, determine what action to take
                                    let swipeRight = cardOffset > 100
                                    let swipeLeft = cardOffset < -100
                                    
                                    if swipeRight {
                                        // Animate card completely off the screen to the right
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            cardOffset = UIScreen.main.bounds.width + 100
                                        }
                                        
                                        // Reset animation states to ensure they trigger again
                                        showFireEmojis = false
                                        showXEmojis = false
                                        
                                        // Trigger the animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                            triggerFireEmojis()
                                        }
                                        
                                        // After card exits, update the model
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.upvoteCurrentWord()
                                            // Reset offset for next card
                                            cardOffset = 0
                                        }
                                    } else if swipeLeft {
                                        // Animate card completely off the screen to the left
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            cardOffset = -UIScreen.main.bounds.width - 100
                                        }
                                        
                                        // Reset animation states to ensure they trigger again
                                        showFireEmojis = false
                                        showXEmojis = false
                                        
                                        // Trigger the animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                            triggerXEmojis()
                                        }
                                        
                                        // After card exits, update the model
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.downvoteCurrentWord()
                                            // Reset offset for next card
                                            cardOffset = 0
                                        }
                                    } else {
                                        // If not far enough, return to center
                                        withAnimation(.spring()) {
                                            cardOffset = 0
                                        }
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
            
            // Fire Emoji Animation Overlay
            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    if showFireEmojis, index < emojiPositions.count {
                        Text("🔥")
                            .font(.system(size: CGFloat.random(in: 25...45)))
                            .modifier(FloatingAnimation(isShowing: showFireEmojis,
                                                       startPosition: emojiPositions[index]))
                            .id("\(animationId)-fire-\(index)") // Unique ID for each emoji
                    }
                }
            }
            
            // X Emoji Animation Overlay
            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    if showXEmojis, index < emojiPositions.count {
                        Text("❌")
                            .font(.system(size: CGFloat.random(in: 25...45)))
                            .modifier(FloatingAnimation(isShowing: showXEmojis,
                                                       startPosition: emojiPositions[index]))
                            .id("\(animationId)-x-\(index)") // Unique ID for each emoji
                    }
                }
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
    
    // Functions to trigger emoji animations
    private func triggerFireEmojis() {
        generateEmojiPositionsFromCard()
        animationId = UUID() // Force view refresh for each animation
        showFireEmojis = true
        
        // Hide emojis after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showFireEmojis = false
            }
        }
    }
    
    private func triggerXEmojis() {
        generateEmojiPositionsFromCard()
        animationId = UUID() // Force view refresh for each animation
        showXEmojis = true
        
        // Hide emojis after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showXEmojis = false
            }
        }
    }
    
    private func generateEmojiPositionsFromCard() {
        let screenWidth = UIScreen.main.bounds.width
        let cardCenter = CGPoint(x: screenWidth / 2, y: UIScreen.main.bounds.height / 2 - 50)
        let cardWidth: CGFloat = screenWidth - 40  // Accounting for horizontal padding
        let cardHeight: CGFloat = 400
        
        // Generate starting positions around the card
        emojiPositions = (0..<20).map { _ in
            // Choose random edge of the card to start from
            let edge = Int.random(in: 0...3)  // 0: top, 1: right, 2: bottom, 3: left
            
            var x: CGFloat
            var y: CGFloat
            
            switch edge {
            case 0:  // Top edge
                x = cardCenter.x + CGFloat.random(in: -cardWidth/2...cardWidth/2)
                y = cardCenter.y - cardHeight/2
            case 1:  // Right edge
                x = cardCenter.x + cardWidth/2
                y = cardCenter.y + CGFloat.random(in: -cardHeight/2...cardHeight/2)
            case 2:  // Bottom edge
                x = cardCenter.x + CGFloat.random(in: -cardWidth/2...cardWidth/2)
                y = cardCenter.y + cardHeight/2
            default:  // Left edge
                x = cardCenter.x - cardWidth/2
                y = cardCenter.y + CGFloat.random(in: -cardHeight/2...cardHeight/2)
            }
            
            return CGPoint(x: x, y: y)
        }
    }
}

// Custom animation modifier for floating emojis
struct FloatingAnimation: ViewModifier {
    let isShowing: Bool
    let startPosition: CGPoint
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    
    func body(content: Content) -> some View {
        content
            .position(startPosition)
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                if isShowing {
                    // Initial state
                    opacity = 1
                    scale = 0.5
                    
                    // Random horizontal drift
                    let horizontalDrift = CGFloat.random(in: -100...100)
                    
                    // Animate the emoji floating up and out
                    withAnimation(.easeOut(duration: 1.5)) {
                        offset = CGSize(
                            width: horizontalDrift,
                            height: -UIScreen.main.bounds.height
                        )
                        scale = CGFloat.random(in: 0.7...1.3)
                    }
                }
            }
    }
}

// Note: Color hex extension is defined in CreateView.swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
