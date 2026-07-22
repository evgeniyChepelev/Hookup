import SwiftUI

@main
struct HookUpApp: App {
    @UIApplicationDelegateAdaptor(PushCoordinator.self) var pushCoordinator

    var body: some Scene {
        WindowGroup {
            RootFlowView()
        }
    }
}
