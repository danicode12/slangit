import SwiftUI
import Firebase
import FirebaseFirestore

struct CreateView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var alertMessage = "your new word is out!"
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Notebook paper background
            VStack(spacing: 0) {
                // Content with notebook paper styling
                VStack {
                    Text("feeling creative?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 80)
                    
                    Spacer()
                    
                    // First text field - word input with custom styling
                    VStack(alignment: .leading, spacing: 15) {
                        // Custom text field implementation for better placeholder visibility
                        ZStack(alignment: .leading) {
                            if word.isEmpty {
                                Text("type a new word...")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            TextField("", text: $word)
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.black)
                        }
                        .padding(.bottom, 10)
                        
                        // Definition input - yellow box
                        ZStack(alignment: .topLeading) {
                            // This is now only for the placeholder
                            if definition.isEmpty {
                                Text("what does it mean?")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.top, 15)
                                    .padding(.leading, 15)
                                    .zIndex(1) // Ensure placeholder is above the TextEditor
                            }
                                                    
                            // Modified TextEditor with the background color directly applied
                            // We wrap it in a background view to ensure complete coverage
                            TextEditor(text: $definition)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding(10)
                                .frame(height: 200)
                                .background(Color(hex: "EDD377")) // Apply yellow color directly
                                .cornerRadius(0) // No rounded corners
                            }
                            .frame(height: 200)
                            .background(Color(hex: "EDD377")) // Backup background color
                                                
                        
                        // Submit button - navy blue button
                        Button(action: {
                            addNewWord()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(hex: "162959")) // Navy blue
                                    .frame(height: 60)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("slang it")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.top, 20)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .background(
                    ZStack {
                        // Base paper color
                        Color.white
                        
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
                )
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Word Added"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func addNewWord() {
        isLoading = true
        
        Task {
            let success = await viewModel.addWord(word: word, definition: definition)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    word = ""
                    definition = ""
                    alertMessage = "Your slang word has been added!"
                    showAlert = true
                } else if let error = viewModel.errorMessage {
                    alertMessage = "Error: \(error)"
                    showAlert = true
                }
            }
        }
    }
}

// Helper extension for hex colors
