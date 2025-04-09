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
                    Text("top words this week")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.topWords) { word in
                                HStack {
                                    Text("\(word.word) by @\(word.username)")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color(hex: "EDD377")) // Yellow background
                                .cornerRadius(0) // No rounded corners to match other screens
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black) // Changed to black for notebook theme
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

// Note: Color hex extension is defined in CreateView.swift
