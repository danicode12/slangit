import SwiftUI
import Firebase
import FirebaseFirestore

struct CreateView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var alertMessage = "Your slang word has been added!"
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("feeling creative?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 80)
                
                Spacer()
                
                // Centered content container
                VStack(spacing: 25) {
                    // Word input
                    TextField("type a new word...", text: $word)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    // Definition input
                    TextField("what does it mean?", text: $definition)
                        .padding()
                        .frame(height: 120)
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    // Submit button
                    Button(action: {
                        addNewWord()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("slang it")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                .frame(maxHeight: 400)
                
                Spacer()
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
