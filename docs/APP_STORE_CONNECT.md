# App Store Connect — Dear Muse: Soul Drift

Bundle ID: `com.s2.dearmuse`  
Team: `XN42ZWWAT9`  
Display name: **Dear Muse**  
Subtitle suggestion: **Soul Drift · Anonymous Notes**

## Review URLs (must resolve on production)

| Field | URL |
| --- | --- |
| Marketing | https://dearmuse.space2.world/ |
| Support | https://dearmuse.space2.world/support |
| Privacy Policy | https://dearmuse.space2.world/privacy |

## Subscription group

Create group **Dear Muse Membership** with levels:

| Level | Reference name | Product ID | Period | Price (US) |
| --- | --- | --- | --- | --- |
| 1 (highest) | Max Monthly | `com.s2.dearmuse.max.monthly` | 1 month | $9.99 |
| 1 | Max Yearly | `com.s2.dearmuse.max.yearly` | 1 year | $79.99 |
| 2 | Pro Monthly | `com.s2.dearmuse.pro.monthly` | 1 month | $4.99 |
| 2 | Pro Yearly | `com.s2.dearmuse.pro.yearly` | 1 year | $39.99 |

These IDs are wired in:

- `Core/StoreKit/StoreKitManager.swift`
- `Config/DearMuseMembership.storekit` (Xcode local StoreKit testing)

### ASC checklist

1. App → Features → In-App Purchases → create the four auto-renewable products above.
2. Attach localization (en-US + zh-Hans) for display name / description.
3. Add products to the app version’s In-App Purchases section before submit.
4. Paid Apps Agreement + banking + tax must be Active.
5. Local verify: Scheme DearMuse → Run with `DearMuseMembership.storekit`.

## Capability notes

- App Group: `group.com.s2.dearuniverse`, `group.com.robotzero.shared.ai`
- Background Modes: Processing (`midnight-mirror`, `sunday-magpie`)
- Local Network: Rainbow Bridge MQTT (optional)
- Encryption: ITSAppUsesNonExemptEncryption = NO

## MQTT Rainbow Bridge (device 联调)

Default WSS (public EMQX sandbox for lab): `wss://broker.emqx.io:8084/mqtt`  
Override in `Config/Info.plist` → `DEARMUSE_MQTT_WSS_URL` (production EMQX / HiveMQ WSS endpoint).

Topics (retain = false):

- `s2rb/dearmuse/ocean/bottle/{yyyy_mm_dd}`
- `s2rb/dearmuse/inbox/{recipient_22_s2_did}/crush`
- `s2rb/dearmuse/magpie/{session_id}/handshake`
- `s2rb/dearmuse/lovers/{recipient_22_s2_did}/mirror_and_chat`
