// Localization tests (compiled together with Localization.swift only). Run: ./tests/run.sh
import Foundation
func ok(_ c: Bool, _ m: String) { print(c ? "ok  " : "FAIL", m); if !c { exit(1) } }

// 1. every sentence has Portuguese and Spanish
for (k, v) in L.table { ok(v[.pt] != nil && v[.es] != nil, "translated: \(k.prefix(50))") }
// 2. the %@ placeholders match across languages
func placeholders(_ s: String) -> Int { s.components(separatedBy: "%@").count - 1 }
for (k, v) in L.table { ok(placeholders(k) == placeholders(v[.pt]!) && placeholders(k) == placeholders(v[.es]!), "same %@ in: \(k.prefix(50))") }
// 3. explicit choice and formatting
L.choice = { .pt }; ok(L.t("Safe") == "Tudo seguro", "pt: Safe")
L.choice = { .es }; ok(L.t("Safe") == "Todo seguro", "es: Safe")
L.choice = { .en }; ok(L.t("Safe") == "Safe", "en: Safe (the key is the English text)")
L.choice = { .pt }; ok(L.f("SSD at %@ °C. Avoid large writes and copies until it cools.", "75") == "SSD a 75 °C. Evite gravações e cópias grandes até esfriar.", "formats %@ in pt")
L.choice = { .es }; ok(L.f("Chip above %@ °C%@. Pause heavy work until it drops below %@ °C.", "92", "", "80") == "Chip por encima de 92 °C. Pausa el trabajo pesado hasta que baje de 80 °C.", "formats 3 values in es")
// 4. an unknown key falls back to itself (never breaks)
L.choice = { .pt }; ok(L.t("new text without a table entry") == "new text without a table entry", "unknown key comes back unchanged")
// 5. automatic follows the system and never returns .auto
L.choice = { .auto }; ok(L.current != .auto, "automatic resolves to a concrete language (\(L.current.rawValue))")
ok(Language.allCases.count == 4, "four options: auto, en, pt, es")
print("ALL OK")
