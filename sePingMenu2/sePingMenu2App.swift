import SwiftUI

@main
struct sePingMenu2App: App {
    // We bridge our AppDelegate using NSApplicationDelegateAdaptor
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Minimal scene to satisfy SwiftUI
        WindowGroup {
            EmptyView()
        }
    }
}
