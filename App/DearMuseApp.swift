import SwiftUI

@main
struct DearMuseApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                SoulNightBackground()
                if model.showLaunch {
                    DearMuseLaunchPreludeView {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            model.showLaunch = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    RootTabView()
                        .environment(model)
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await model.storeKit.loadProducts()
            }
        }
    }
}
