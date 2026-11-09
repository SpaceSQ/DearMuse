# Dear Muse: Soul Drift

Internal codename **DearMuse** · Bundle ID `com.s2.dearmuse` · Market site [dearmuse.space2.world](https://dearmuse.space2.world/)

Poetic SwiftUI companion for **zero-return-address drift bottles**, **Sunday Magpie Bridge (~20%)**, and **secret crushes** over local **S2-DID** Rainbow Bridge routing. Lover graphs and Muse memories stay in the on-device sandbox.

## Layout

```text
DearMuse/
├── App/                 # Entry, AppModel, theme, App Group
├── CoreEngines/         # S2RB router, bottle/crush, Magpie, midnight mirror
├── Core/                # StoreKit 2, safety filter, sandbox persistence
├── Views/               # Launch, Muse chat, Romance hub, memories
├── Config/              # Info.plist, entitlements, StoreKit config
├── DearMuseTests/       # Quota / nil-sender / 20% gate / cooldown tests
└── website/             # Vercel static Market + Support + Privacy
```

## Generate & run (iOS)

```bash
cd /Users/David1/Future/DearMuse
xcodegen generate
open DearMuse.xcodeproj
```

Scheme **DearMuse** loads `Config/DearMuseMembership.storekit` for local StoreKit 2.

## Website (Vercel)

Deploy the `website/` folder to the project wired to **dearmuse.space2.world**:

| Route | File |
| --- | --- |
| `/` | `index.html` |
| `/support` or `/support.html` | `support.html` |
| `/privacy` or `/privacy.html` | `privacy.html` |

```bash
cd website && npx vercel --prod
```

## Iron rules (acceptance)

1. Drift bottle: max **1 / day**, delay **1…365** days, `senderDID == nil`.
2. Secret crush: 22-char S2-DID (2-letter checksum) or six-segment address; no return address.
3. Magpie: Sunday 24:00, **~20%** preview gate, dual agree, **4-week** cooldown.
4. Midnight mirrors only when local relation is `.lover`.
5. Cloud MQTT is exchange-only; relationship truth is local.

## App Store Connect + MQTT

See [`docs/APP_STORE_CONNECT.md`](docs/APP_STORE_CONNECT.md) for subscription product IDs, review URLs, and Rainbow Bridge WSS联调.

In-app: **Memory → Connect** opens `wss://broker.emqx.io:8084/mqtt` (override via `DEARMUSE_MQTT_WSS_URL`).

## GitHub

https://github.com/SpaceSQ/DearMuse

## Website deploy

```bash
npx vercel --prod --yes
# bind domain dearmuse.space2.world in Vercel project settings
```
