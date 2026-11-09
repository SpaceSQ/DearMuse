import SwiftUI

struct MuseMainChatView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                SoulNightBackground()
                VStack(spacing: 0) {
                    loverStatusBar
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(model.chatLines) { line in
                                    chatBubble(line)
                                        .id(line.id)
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: model.chatLines.count) { _, _ in
                            if let last = model.chatLines.last?.id {
                                withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                            }
                        }
                    }

                    composer
                }
            }
            .navigationTitle("Dear Muse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MembershipView()
                    } label: {
                        Image(systemName: "crown")
                    }
                }
            }
        }
    }

    private var loverStatusBar: some View {
        let lovers = model.router.snapshotRelations().filter { $0.value == .lover }
        return HStack(spacing: 8) {
            Image(systemName: lovers.isEmpty ? "moon" : "heart.circle")
            Text(lovers.isEmpty
                 ? "Solo Muse — midnight mirror sleeps"
                 : "Lover mirror active · \(lovers.count) bond(s)")
                .font(.caption)
            Spacer()
            Text(String(model.myS2DID.suffix(4)))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(SoulPalette.night.aurora)
        }
        .foregroundStyle(SoulPalette.night.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SoulPalette.night.deep.opacity(0.65))
    }

    private func chatBubble(_ line: ChatLine) -> some View {
        HStack {
            if line.role == .user { Spacer(minLength: 40) }
            Text(line.text)
                .font(.body)
                .foregroundStyle(line.role == .muse ? SoulPalette.night.moonlight : SoulPalette.night.abyss)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(line.role == .muse ? SoulPalette.night.glass : SoulPalette.night.aurora.opacity(0.9))
                )
            if line.role == .muse { Spacer(minLength: 40) }
        }
    }

    private var composer: some View {
        @Bindable var model = model
        return HStack(spacing: 10) {
            TextField("Whisper to your Muse…", text: $model.chatDraft, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(SoulPalette.night.mist.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(SoulPalette.night.moonlight)
            Button {
                model.sendChat()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(SoulPalette.night.aurora)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }
}

struct MembershipView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            SoulNightBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Membership")
                        .font(.system(size: 30, weight: .light, design: .serif))
                        .foregroundStyle(SoulPalette.night.moonlight)
                    Text("Active: \(model.storeKit.activeTier.rawValue)")
                        .foregroundStyle(SoulPalette.night.aurora)

                    tierCard(
                        title: "Free",
                        price: "$0",
                        lines: ["Daily bottle · Muse chat · local S2-DID sandbox"]
                    )
                    tierCard(
                        title: "Pro",
                        price: "$4.99/mo",
                        lines: ["Unlimited Magpie profile polish", "Midnight mirror export", "Priority ocean pick demos"]
                    )
                    tierCard(
                        title: "Max",
                        price: "$9.99/mo",
                        lines: ["Everything in Pro", "Coupled Muse workshop", "Rainbow Bridge multi-lover graphs"]
                    )

                    if let product = model.storeKit.proMonthly {
                        Button("Subscribe Pro") {
                            Task { await model.storeKit.purchase(product) }
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())
                    }
                    if let product = model.storeKit.maxMonthly {
                        Button("Subscribe Max") {
                            Task { await model.storeKit.purchase(product) }
                        }
                        .buttonStyle(SoulGhostButtonStyle())
                    }
                    Button("Restore Purchases") {
                        Task { await model.storeKit.restorePurchases() }
                    }
                    .buttonStyle(SoulGhostButtonStyle())

                    if let err = model.storeKit.purchaseError {
                        Text(err.resolve())
                            .font(.footnote)
                            .foregroundStyle(SoulPalette.night.rose)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("StoreKit")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tierCard(title: String, price: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline).foregroundStyle(SoulPalette.night.moonlight)
                Spacer()
                Text(price).foregroundStyle(SoulPalette.night.aurora)
            }
            ForEach(lines, id: \.self) { line in
                Text("· \(line)")
                    .font(.footnote)
                    .foregroundStyle(SoulPalette.night.secondary)
            }
        }
        .glassCard()
    }
}
