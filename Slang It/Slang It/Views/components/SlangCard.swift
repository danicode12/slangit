import SwiftUI

struct SlangCard: View {
    let word: SlangWord
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .white
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange)
            
            VStack(alignment: .center, spacing: 10) {
                Text(word.word.uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text(word.definition)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                Spacer()
            }
            .frame(width: 300, height: 400)
        }
        .frame(width: 300, height: 400)
        .cornerRadius(20)
        .shadow(radius: 10)
        .offset(x: offset.width, y: 0)
        .rotationEffect(.degrees(Double(offset.width / 15)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Only allow gesture if not currently animating
                    if !isAnimating {
                        offset = gesture.translation
                        withAnimation {
                            // Change color based on swipe direction
                            if offset.width > 0 {
                                color = .green.opacity(min(0.5, Double(offset.width) / 300))
                            } else if offset.width < 0 {
                                color = .red.opacity(min(0.5, Double(-offset.width) / 300))
                            } else {
                                color = .white
                            }
                        }
                    }
                }
                .onEnded { gesture in
                    // Only process if not currently animating
                    if !isAnimating {
                        isAnimating = true
                        
                        if offset.width > 100 {
                            // Swipe right
                            withAnimation(.spring()) {
                                offset.width = 500
                            }
                            
                            // Delay to let animation finish before calling handler
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeRight()
                                isAnimating = false
                            }
                            
                        } else if offset.width < -100 {
                            // Swipe left
                            withAnimation(.spring()) {
                                offset.width = -500
                            }
                            
                            // Delay to let animation finish before calling handler
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeLeft()
                                isAnimating = false
                            }
                            
                        } else {
                            // Return to center
                            withAnimation(.spring()) {
                                offset = .zero
                                color = .white
                            }
                            isAnimating = false
                        }
                    }
                }
        )
    }
}
