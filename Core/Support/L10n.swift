import Foundation

struct Bilingual: Equatable, Sendable {
    var en: String
    var zh: String

    func resolve(locale: Locale = .current) -> String {
        if locale.language.languageCode?.identifier == "zh" { return zh }
        return en
    }
}

enum L10n {
    static let brand = Bilingual(en: "Dear Muse", zh: "亲爱的缪斯")
    static let subtitle = Bilingual(en: "Soul Drift", zh: "灵魂漂流")
    static let castBottle = Bilingual(en: "Cast a bottle", zh: "放出漂流瓶")
    static let pickBottle = Bilingual(en: "Pick from the tide", zh: "从潮汐中拾起")
    static let secretCrush = Bilingual(en: "Secret crush", zh: "暗恋纸条")
    static let magpieBridge = Bilingual(en: "Magpie Bridge", zh: "周日鹊桥")
    static let museChat = Bilingual(en: "Talk to Muse", zh: "与缪斯对话")
    static let zeroReturn = Bilingual(
        en: "No return address. Once cast, it cannot find its way home.",
        zh: "无回邮地址。一经投出，无法原路归返。"
    )
}
