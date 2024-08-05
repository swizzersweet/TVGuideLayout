import SwiftUI
import TVGuideLayout

struct ContentView: View {
    private let provider = ExampleProvider()
    
    var body: some View {
        TVGuideExampleViewRepresentable(provider: provider)
    }
}

#Preview {
    ContentView()
}
