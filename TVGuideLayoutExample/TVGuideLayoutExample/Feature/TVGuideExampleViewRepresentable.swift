import SwiftUI
import TVGuideLayout

struct TVGuideExampleViewRepresentable<P: TVGuideViewController<ExampleProvider>>: UIViewControllerRepresentable {

    let provider: ExampleProvider
    
    func makeUIViewController(context: Context) -> TVGuideViewController<ExampleProvider> {
        TVGuideViewController<ExampleProvider>(provider: provider)
    }
    
    func updateUIViewController(_ uiViewController: TVGuideViewController<ExampleProvider>, context: Context) {
        
    }
}
