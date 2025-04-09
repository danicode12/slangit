import SwiftUI

struct TrendingView: View {
    @EnvironmentObject var viewModel: SlangViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("top words this week")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.topWords) { word in
                            HStack {
                                Text("\(word.word) by @\(word.username)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color.blue)
            .edgesIgnoringSafeArea(.all)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .onAppear {
                Task {
                    await viewModel.loadTopWords()
                }
            }
        }
    }
}
