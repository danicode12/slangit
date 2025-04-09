import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    
    var body: some View {
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
            
            // Content
            VStack {
                // Profile picture
                Circle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                    .padding(.top, 80)
                
                Text("John Doe")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                Text("your slang")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                
                // Placeholder content for user's slang words
                ScrollView {
                    VStack(spacing: 15) {
                        WordRow(word: "Rizz", votes: 13)
                        WordRow(word: "Meta", votes: 14)
                        WordRow(word: "Type", votes: 20)
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
    }
}

struct WordRow: View {
    let word: String
    let votes: Int
    
    var body: some View {
        HStack {
            Text(word)
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
            
            Text("\(votes) votes")
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color(hex: "EDD377"))
        .cornerRadius(0) // Remove corner radius to match the design of other screens
        .padding(.horizontal)
    }
}

// Note: Color hex extension is defined in CreateView.swift
