import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            MuseMainChatView()
                .tabItem { Label(RootTab.muse.title, systemImage: RootTab.muse.symbol) }
                .tag(RootTab.muse)

            DriftBottleBeachView()
                .tabItem { Label(RootTab.drift.title, systemImage: RootTab.drift.symbol) }
                .tag(RootTab.drift)

            SecretCrushComposeView()
                .tabItem { Label(RootTab.crush.title, systemImage: RootTab.crush.symbol) }
                .tag(RootTab.crush)

            MagpieBridgeSundayView()
                .tabItem { Label(RootTab.magpie.title, systemImage: RootTab.magpie.symbol) }
                .tag(RootTab.magpie)

            CoupledMirrorTimelineView()
                .tabItem { Label(RootTab.memory.title, systemImage: RootTab.memory.symbol) }
                .tag(RootTab.memory)
        }
        .tint(SoulPalette.night.aurora)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
