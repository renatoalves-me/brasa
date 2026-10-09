// Brasa languages: English (base), Brazilian Portuguese and Spanish. The key of each string is the English sentence itself.
// The language follows the system (automatic) and can be changed in Settings. To add a language: a case in `Language`,
// a name in `name` and a column in `table` (tests/run.sh fails if any sentence is missing a translation).
import Foundation

enum Language: String, CaseIterable, Identifiable {
  case auto, en, pt, es
  var id: String { rawValue }
  /// the language name in its own language (only "Automatic" is translated)
  var name: String {
    switch self {
    case .auto: return L.t("Automatic")
    case .en: return "English"
    case .pt: return "Português"
    case .es: return "Español"
    }
  }
}

enum L {
  /// who chooses the language (wired to Settings by the app; automatic in tests)
  static var choice: () -> Language = { .auto }

  /// the concrete language in use: the chosen one, or the first system language Brasa knows (default: English)
  static var current: Language {
    let e = choice()
    if e != .auto { return e }
    for p in Locale.preferredLanguages {
      let c = String(p.lowercased().prefix(2))
      if c == "pt" { return .pt }
      if c == "es" { return .es }
      if c == "en" { return .en }
    }
    return .en
  }

  static func t(_ key: String) -> String { table[key]?[current] ?? key }
  /// text with %@ placeholders (always pass the values already as text)
  static func f(_ key: String, _ values: String...) -> String { String(format: t(key), arguments: values as [CVarArg]) }

  static let table: [String: [Language: String]] = [
    // levels
    "Safe": [.pt: "Tudo seguro", .es: "Todo seguro"],
    "Warming up": [.pt: "Esquentando", .es: "Calentándose"],
    "Too hot": [.pt: "Quente demais", .es: "Demasiado caliente"],
    "Critical": [.pt: "Crítico", .es: "Crítico"],
    // explanations and notifications
    "Chip, battery, memory and SSD within normal range.": [.pt: "Chip, bateria, memória e SSD dentro do normal.", .es: "Chip, batería, memoria y SSD dentro de lo normal."],
    "Chip at critical temperature. Close what is heavy now (see below).": [.pt: "Chip em temperatura crítica. Feche agora o que está pesando (veja abaixo).", .es: "Chip a temperatura crítica. Cierra ahora lo que pesa (mira abajo)."],
    "Battery at %@ °C. Battery heat wears the Mac the most: unplug it or lighten the load%@.": [.pt: "Bateria a %@ °C. Calor na bateria é o que mais desgasta o Mac: tire do carregador ou alivie a carga%@.", .es: "Batería a %@ °C. El calor en la batería es lo que más desgasta el Mac: desconéctalo del cargador o alivia la carga%@."],
    "now": [.pt: "agora", .es: "ahora"],
    "and macOS is already slowing things down": [.pt: "e o macOS já está reduzindo a velocidade", .es: "y macOS ya está reduciendo la velocidad"],
    "Chip above %@ °C%@. Pause heavy work until it drops below %@ °C.": [.pt: "Chip acima de %@ °C%@. Pause o trabalho pesado até baixar de %@ °C.", .es: "Chip por encima de %@ °C%@. Pausa el trabajo pesado hasta que baje de %@ °C."],
    "macOS reported moderate heat. Avoid starting a render or export now.": [.pt: "O macOS sinalizou calor moderado. Evite começar render ou exportação agora.", .es: "macOS ha señalado calor moderado. Evita empezar un render o una exportación ahora."],
    "Chip above %@ °C. Avoid starting a render or export now.": [.pt: "Chip acima de %@ °C. Evite começar render ou exportação agora.", .es: "Chip por encima de %@ °C. Evita empezar un render o una exportación ahora."],
    "Cooling down. Wait until it drops below %@ °C to resume heavy work.": [.pt: "Esfriando. Espere baixar de %@ °C para voltar ao trabalho pesado.", .es: "Enfriándose. Espera a que baje de %@ °C para volver al trabajo pesado."],
    "Memory exhausted: the Mac is writing memory to the SSD non-stop. Close apps now.": [.pt: "Memória esgotada: o Mac está gravando memória no SSD sem parar. Feche apps agora.", .es: "Memoria agotada: el Mac está escribiendo memoria en el SSD sin parar. Cierra apps ahora."],
    "Memory is tight (%@ GB on the SSD). Close apps you are not using.": [.pt: "Memória apertada (%@ GB no SSD). Feche apps que não está usando.", .es: "Memoria justa (%@ GB en el SSD). Cierra las apps que no uses."],
    "SSD at %@ °C. Avoid large writes and copies until it cools.": [.pt: "SSD a %@ °C. Evite gravações e cópias grandes até esfriar.", .es: "SSD a %@ °C. Evita escrituras y copias grandes hasta que se enfríe."],
    "Check one of the sensors.": [.pt: "Atenção a um dos sensores.", .es: "Atención a uno de los sensores."],
    "Mac back to normal": [.pt: "Mac de volta ao normal", .es: "Mac de vuelta a la normalidad"],
    "Mac: %@": [.pt: "Mac: %@", .es: "Mac: %@"],
    // panel
    "normal": [.pt: "normal", .es: "normal"],
    "moderate": [.pt: "moderado", .es: "moderado"],
    "serious": [.pt: "sério", .es: "serio"],
    "critical": [.pt: "crítico", .es: "crítico"],
    "macOS: %@": [.pt: "macOS: %@", .es: "macOS: %@"],
    "last 10 min": [.pt: "últimos 10 min", .es: "últimos 10 min"],
    "line: temperature · area: CPU": [.pt: "linha: temperatura · área: CPU", .es: "línea: temperatura · área: CPU"],
    "Battery": [.pt: "Bateria", .es: "Batería"],
    "Memory": [.pt: "Memória", .es: "Memoria"],
    "Fan": [.pt: "Ventoinha", .es: "Ventilador"],
    "idle": [.pt: "parada", .es: "parado"],
    "Top processes by CPU (% of total)": [.pt: "O que mais está usando o processador (% do total)", .es: "Lo que más usa el procesador (% del total)"],
    "Chip: slows %@° · pauses %@° · critical %@° · battery %@°": [.pt: "Chip: reduz %@° · pausa %@° · crítico %@° · bateria %@°", .es: "Chip: reduce %@° · pausa %@° · crítico %@° · batería %@°"],
    "Open at login": [.pt: "Abrir ao ligar o Mac", .es: "Abrir al encender el Mac"],
    "Settings": [.pt: "Ajustes", .es: "Ajustes"],
    "Quit": [.pt: "Sair", .es: "Salir"],
    // settings
    "Brasa · Settings": [.pt: "Brasa · Ajustes", .es: "Brasa · Ajustes"],
    "Back to default (%@ %@)": [.pt: "Voltar ao padrão (%@ %@)", .es: "Volver al valor por defecto (%@ %@)"],
    "The factory values are only defaults. Change what you like; limits adjust each other to keep their order.": [.pt: "Os valores de fábrica são só o padrão. Mude o que quiser; os limites se ajustam entre si para manter a ordem.", .es: "Los valores de fábrica son solo los predeterminados. Cambia lo que quieras; los límites se ajustan entre sí para mantener el orden."],
    "Chip": [.pt: "Chip", .es: "Chip"],
    "Highlighted processes": [.pt: "Processos em destaque", .es: "Procesos destacados"],
    "Notifications": [.pt: "Notificações", .es: "Notificaciones"],
    "Language": [.pt: "Idioma", .es: "Idioma"],
    "Automatic": [.pt: "Automático", .es: "Automático"],
    "Slow down from": [.pt: "Reduzir a partir de", .es: "Reducir a partir de"],
    "Warning: avoid starting a render or export.": [.pt: "Aviso: evite começar render ou exportação.", .es: "Aviso: evita empezar un render o una exportación."],
    "Pause from": [.pt: "Pausar a partir de", .es: "Pausar a partir de"],
    "Pause heavy work.": [.pt: "Pause o trabalho pesado.", .es: "Pausa el trabajo pesado."],
    "Critical from": [.pt: "Crítico a partir de", .es: "Crítico a partir de"],
    "Close what is heavy right now.": [.pt: "Feche o que está pesando agora.", .es: "Cierra ahora lo que pesa."],
    "Back to normal below": [.pt: "Voltar ao normal abaixo de", .es: "Volver a la normalidad por debajo de"],
    "After pausing, it only clears once it cools down to here.": [.pt: "Depois de pausar, só libera quando esfriar até aqui.", .es: "Tras pausar, solo se libera cuando se enfríe hasta aquí."],
    "Warning from": [.pt: "Aviso a partir de", .es: "Aviso a partir de"],
    "Above about 40 °C the battery ages faster.": [.pt: "Acima de cerca de 40 °C a bateria envelhece mais rápido.", .es: "Por encima de unos 40 °C la batería envejece más rápido."],
    "High from": [.pt: "Alto a partir de", .es: "Alto a partir de"],
    "Heat that causes damage.": [.pt: "Calor que causa dano.", .es: "Calor que causa daño."],
    "Avoid large writes and copies.": [.pt: "Evite gravações e cópias grandes.", .es: "Evita escrituras y copias grandes."],
    "Warn when swap is above": [.pt: "Avisar com swap acima de", .es: "Avisar con swap por encima de"],
    "The Mac is writing memory to the SSD non-stop.": [.pt: "O Mac está gravando memória no SSD sem parar.", .es: "El Mac está escribiendo memoria en el SSD sin parar."],
    "Yellow from": [.pt: "Amarelo a partir de", .es: "Amarillo a partir de"],
    "% of the processor used by one process.": [.pt: "% do processador usado por um processo.", .es: "% del procesador usado por un proceso."],
    "Orange from": [.pt: "Laranja a partir de", .es: "Naranja a partir de"],
    "Notify when the level changes": [.pt: "Avisar quando o nível mudar", .es: "Avisar cuando cambie el nivel"],
    "Play a sound on pause and critical": [.pt: "Tocar som em pausa e crítico", .es: "Reproducir sonido en pausa y crítico"],
    "Restore all defaults": [.pt: "Restaurar todos os padrões", .es: "Restaurar todos los valores por defecto"],
  ]
}
