import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(viewModel: ContentViewModel = ContentViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Earth Image
//                Image(systemName: "globe")
//                    .imageScale(.large)
//                    .foregroundStyle(.tint)
//                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                // Greeting Text
                Text("Hello, Akshay!!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                // Steps Count with Animation
                HStack {
                    LottieView(filename: "walking_man")
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    Text("Current Steps: \(viewModel.stepCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                }

                // Heart Rate with Animation
                HStack {
                    LottieView(filename: "heart_anim")
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    Text("Current HR: \(viewModel.heartRate, specifier: "%.1f") bpm")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel(healthStore: nil)) // Use dummy data
    }
}
