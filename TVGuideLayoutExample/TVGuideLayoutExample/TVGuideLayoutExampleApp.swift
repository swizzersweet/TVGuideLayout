import SwiftUI

@main
struct TVGuideLayoutAppWrapper {
    static func main() {
        if #available(iOS 14.0, *) {
            TVGuideLayoutExampleApp.main()
        }
        else {
            UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(SceneDelegate.self))
        }
    }
}

@available(iOS 14.0, *)
struct TVGuideLayoutExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
