// Brasa: a Mac menu bar app that watches what matters for the machine's safety: chip, battery and SSD temperature,
// CPU, GPU, memory, fans, the macOS thermal state and what is heating things up. DEFAULT limits (adjustable in Settings):
// slow down at 85 °C, pause at 92 °C (back to normal below 80 °C), critical at 100 °C.
// Deliberately light: everything is read inside the process (no shell commands) every 2 s; the process list is only
// read while the panel is open.
import SwiftUI
import AppKit
import IOKit
import ServiceManagement
import UserNotifications
import Combine

// ───────── settings: the limits below are only the DEFAULTS; the user changes everything in Settings (stored in UserDefaults) ─────────
enum Key: String, CaseIterable {
  case chipResume, chipWarn, chipPause, chipCritical, batteryWarn, batteryHigh, ssdWarn, ssdHigh, swapWarn, loadMedium, loadHigh

  var defaultValue: Double {
    switch self {
    case .chipResume: return 80      // after pausing, it only goes back to normal below this
    case .chipWarn: return 85       // slow down: avoid starting a render or export
    case .chipPause: return 92       // pause heavy work
    case .chipCritical: return 100
    case .batteryWarn: return 40    // above ~40 °C the battery ages fast
    case .batteryHigh: return 45     // 45 °C is damage
    case .ssdWarn: return 70
    case .ssdHigh: return 80
    case .swapWarn: return 8        // GB of swap: the Mac is writing memory to the SSD non-stop
    case .loadMedium: return 60      // % of CPU of a highlighted process (yellow)
    case .loadHigh: return 85       // (orange)
    }
  }
  var range: ClosedRange<Double> {
    switch self {
    case .chipResume, .chipWarn, .chipPause, .chipCritical: return 50...110
    case .batteryWarn, .batteryHigh: return 25...60
    case .ssdWarn, .ssdHigh: return 40...100
    case .swapWarn: return 1...32
    case .loadMedium, .loadHigh: return 20...100
    }
  }
  var step: Double { self == .swapWarn ? 0.5 : 1 }
  var unit: String { self == .swapWarn ? "GB" : (self == .loadMedium || self == .loadHigh) ? "%" : "°C" }
  /// groups in ascending order: each value must stay above the previous one
  static let groups: [[Key]] = [[.chipResume, .chipWarn, .chipPause, .chipCritical], [.batteryWarn, .batteryHigh], [.ssdWarn, .ssdHigh], [.loadMedium, .loadHigh]]
}

final class Settings: ObservableObject {
  static let shared = Settings()
  @Published private(set) var values: [Key: Double] = [:]
  @Published var notify: Bool { didSet { UserDefaults.standard.set(notify, forKey: "brasa.notify") } }
  @Published var soundOnPause: Bool { didSet { UserDefaults.standard.set(soundOnPause, forKey: "brasa.sound") } }
  @Published var language: Language { didSet { UserDefaults.standard.set(language.rawValue, forKey: "brasa.language") } }
  private let d = UserDefaults.standard

  private init() {
    notify = d.object(forKey: "brasa.notify") as? Bool ?? true
    soundOnPause = d.object(forKey: "brasa.sound") as? Bool ?? true
    language = Language(rawValue: d.string(forKey: "brasa.language") ?? "") ?? .auto
    for k in Key.allCases { values[k] = (d.object(forKey: "brasa.limit.\(k.rawValue)") as? Double).map { min(max($0, k.range.lowerBound), k.range.upperBound) } ?? k.defaultValue }
    fixOrder()
    L.choice = { Settings.shared.language }
  }

  func value(_ k: Key) -> Double { values[k] ?? k.defaultValue }
  func isDefault(_ k: Key) -> Bool { value(k) == k.defaultValue }
  var allDefault: Bool { Key.allCases.allSatisfy(isDefault) }

  /// changes one limit and pushes its neighbours to keep the order (resume < warn < pause < critical)
  func set(_ k: Key, _ next: Double) {
    var lower = k.range.lowerBound, upper = k.range.upperBound
    if let g = Key.groups.first(where: { $0.contains(k) }), let i = g.firstIndex(of: k) {
      // leave room for the neighbours to fit in their range (otherwise the order would break at the edge of the range)
      lower = max(lower, g[0].range.lowerBound + Double(i) * k.step)
      upper = min(upper, g[g.count - 1].range.upperBound - Double(g.count - 1 - i) * k.step)
    }
    values[k] = min(max(next, lower), upper)
    fixOrder(keeping: k)
    save()
  }
  func restore(_ k: Key? = nil) {
    if let k { values[k] = k.defaultValue; fixOrder(keeping: k) } else { Key.allCases.forEach { values[$0] = $0.defaultValue } }
    save()
  }
  private func fixOrder(keeping k: Key? = nil) {
    for g in Key.groups {
      let i0 = k.flatMap { g.firstIndex(of: $0) } ?? 0
      if i0 + 1 < g.count { for i in (i0 + 1)..<g.count where value(g[i]) < value(g[i - 1]) + g[i].step { values[g[i]] = min(value(g[i - 1]) + g[i].step, g[i].range.upperBound) } }
      if i0 > 0 { for i in stride(from: i0 - 1, through: 0, by: -1) where value(g[i]) > value(g[i + 1]) - g[i].step { values[g[i]] = max(value(g[i + 1]) - g[i].step, g[i].range.lowerBound) } }
    }
  }
  private func save() { for (k, v) in values { d.set(v, forKey: "brasa.limit.\(k.rawValue)") } }
}

/// read shortcuts; always return the current setting (or the default)
enum Limit {
  static var warn: Double { Settings.shared.value(.chipWarn) }
  static var pause: Double { Settings.shared.value(.chipPause) }
  static var resume: Double { Settings.shared.value(.chipResume) }
  static var critical: Double { Settings.shared.value(.chipCritical) }
  static var scaleMin: Double { 30 }
  static var scaleMax: Double { max(105, critical + 5) }
  static var batteryWarn: Double { Settings.shared.value(.batteryWarn) }
  static var batteryHigh: Double { Settings.shared.value(.batteryHigh) }
  static var ssdWarn: Double { Settings.shared.value(.ssdWarn) }
  static var ssdHigh: Double { Settings.shared.value(.ssdHigh) }
  static var swapWarn: Double { Settings.shared.value(.swapWarn) }
  static var loadMedium: Double { Settings.shared.value(.loadMedium) }
  static var loadHigh: Double { Settings.shared.value(.loadHigh) }
}

enum Level: Int, Comparable {
  case ok, warn, pause, critical
  static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
  var color: Color {
    switch self {
    case .ok: return Color(red: 0.20, green: 0.80, blue: 0.50)
    case .warn: return Color(red: 1.00, green: 0.71, blue: 0.20)
    case .pause: return Color(red: 1.00, green: 0.48, blue: 0.16)
    case .critical: return Color(red: 1.00, green: 0.25, blue: 0.32)
    }
  }
  var nsColor: NSColor { NSColor(color) }
  var title: String { [L.t("Safe"), L.t("Warming up"), L.t("Too hot"), L.t("Critical")][rawValue] }
}

// ───────── temperature sensors (IOHIDEventSystem, no sudo) ─────────
typealias HIDClient = OpaquePointer
@_silgen_name("IOHIDEventSystemClientCreate") func IOHIDEventSystemClientCreate(_ a: CFAllocator?) -> HIDClient?
@_silgen_name("IOHIDEventSystemClientSetMatching") func IOHIDEventSystemClientSetMatching(_ c: HIDClient, _ m: CFDictionary) -> Int32
@_silgen_name("IOHIDEventSystemClientCopyServices") func IOHIDEventSystemClientCopyServices(_ c: HIDClient) -> Unmanaged<CFArray>?
@_silgen_name("IOHIDServiceClientCopyProperty") func IOHIDServiceClientCopyProperty(_ s: OpaquePointer, _ k: CFString) -> Unmanaged<CFTypeRef>?
@_silgen_name("IOHIDServiceClientCopyEvent") func IOHIDServiceClientCopyEvent(_ s: OpaquePointer, _ t: Int64, _ a: Int32, _ b: Int64) -> OpaquePointer?
@_silgen_name("IOHIDEventGetFloatValue") func IOHIDEventGetFloatValue(_ e: OpaquePointer, _ f: Int32) -> Double

final class Temperatures {
  private var services: [(name: String, svc: OpaquePointer)] = []
  private var list: CFArray?
  init() {
    guard let cli = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else { return }
    _ = IOHIDEventSystemClientSetMatching(cli, ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5] as CFDictionary)
    guard let arr = IOHIDEventSystemClientCopyServices(cli)?.takeRetainedValue() else { return }
    list = arr
    for s in (arr as [AnyObject]) {
      let svc = OpaquePointer(Unmanaged.passUnretained(s).toOpaque())
      if let name = IOHIDServiceClientCopyProperty(svc, "Product" as CFString)?.takeRetainedValue() as? String { services.append((name, svc)) }
    }
  }
  /// (chip = highest temperature among the chip cores, battery, SSD)
  func read() -> (chip: Double?, battery: Double?, ssd: Double?) {
    var chip: Double?, bat: Double?, ssd: Double?, others: Double?
    for (name, svc) in services {
      guard let ev = IOHIDServiceClientCopyEvent(svc, 15, 0, 0) else { continue }
      let v = IOHIDEventGetFloatValue(ev, Int32(15 << 16))
      Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(ev)).release()
      guard v > 0 && v < 150 else { continue }
      let n = name.lowercased()
      if n.contains("tdie") || n.contains("tdev") || n.contains("soc") { chip = max(chip ?? 0, v) }
      else if n.contains("battery") { bat = max(bat ?? 0, v) }
      else if n.contains("nand") { ssd = max(ssd ?? 0, v) }
      else if !n.contains("tcal") { others = max(others ?? 0, v) }
    }
    return (chip ?? others, bat, ssd)
  }
}

// ───────── fans (AppleSMC, read-only, no sudo) ─────────
struct SMCData { // mirrors the kernel SMCKeyData_t (80 bytes), field by field
  var key: UInt32 = 0
  var vMajor: UInt8 = 0, vMinor: UInt8 = 0, vBuild: UInt8 = 0, vReserved: UInt8 = 0, vRelease: UInt16 = 0
  var pad1: UInt16 = 0
  var pVersion: UInt16 = 0, pLength: UInt16 = 0, pCPU: UInt32 = 0, pGPU: UInt32 = 0, pMem: UInt32 = 0
  var infoSize: UInt32 = 0, infoType: UInt32 = 0, infoAttributes: UInt8 = 0, pad2: UInt8 = 0, pad3: UInt8 = 0, pad4: UInt8 = 0
  var result: UInt8 = 0, status: UInt8 = 0, data8: UInt8 = 0, pad5: UInt8 = 0
  var data32: UInt32 = 0
  var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

final class SMC {
  private var connection: io_connect_t = 0
  init?() {
    guard MemoryLayout<SMCData>.size == 80 else { return nil }
    let svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
    guard svc != 0 else { return nil }
    defer { IOObjectRelease(svc) }
    guard IOServiceOpen(svc, mach_task_self_, 0, &connection) == KERN_SUCCESS else { return nil }
  }
  deinit { if connection != 0 { IOServiceClose(connection) } }
  private func key(_ s: String) -> UInt32 { s.utf8.reduce(0) { ($0 << 8) | UInt32($1) } }
  private func call(_ e: inout SMCData) -> Bool {
    var s = SMCData(); var size = MemoryLayout<SMCData>.stride
    let r = IOConnectCallStructMethod(connection, 2, &e, MemoryLayout<SMCData>.stride, &s, &size)
    guard r == KERN_SUCCESS, s.result == 0 else { return false }
    e = s; return true
  }
  /// reads a key and returns (type, bytes)
  func read(_ k: String) -> (dataType: String, bytes: [UInt8])? {
    var e = SMCData(); e.key = key(k); e.data8 = 9 // key info
    guard call(&e) else { return nil }
    let size = e.infoSize, dataType = e.infoType
    var l = SMCData(); l.key = key(k); l.infoSize = size; l.data8 = 5 // read
    guard call(&l) else { return nil }
    let b = withUnsafeBytes(of: l.bytes) { Array($0.prefix(Int(size))) }
    let t = String(bytes: [24, 16, 8, 0].map { UInt8((dataType >> $0) & 0xff) }, encoding: .ascii) ?? ""
    return (t, b)
  }
  func number(_ k: String) -> Double? {
    guard let (t, b) = read(k), !b.isEmpty else { return nil }
    switch t {
    case "flt ": return b.count >= 4 ? Double(b.withUnsafeBytes { $0.loadUnaligned(as: Float32.self) }) : nil
    case "ui8 ": return Double(b[0])
    case "ui16": return b.count >= 2 ? Double(UInt16(b[0]) << 8 | UInt16(b[1])) : nil
    case "fpe2": return b.count >= 2 ? Double(UInt16(b[0]) << 8 | UInt16(b[1])) / 4 : nil
    default: return nil
    }
  }
  /// current and maximum speed of each fan
  func fans() -> [(current: Double, maximum: Double)] {
    let n = Int(number("FNum") ?? 0)
    return (0..<min(n, 4)).compactMap { i in
      guard let a = number("F\(i)Ac") else { return nil }
      return (a, number("F\(i)Mx") ?? 0)
    }
  }
}

// ───────── CPU, GPU, memory ─────────
final class Load {
  private var previous: [UInt64] = []
  func cpu() -> Double? {
    var n: natural_t = 0; var info: processor_info_array_t?; var count: mach_msg_type_number_t = 0
    guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &n, &info, &count) == KERN_SUCCESS, let info else { return nil }
    defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(Int(count) * MemoryLayout<integer_t>.stride)) }
    var current: [UInt64] = []
    for i in 0..<Int(n) {
      let base = i * Int(CPU_STATE_MAX)
      let user = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_USER)])), system = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]))
      let idle = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)])), nice = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]))
      current += [user + system + nice, user + system + nice + idle]
    }
    defer { previous = current }
    guard previous.count == current.count else { return nil }
    var busy: UInt64 = 0, total: UInt64 = 0
    for i in stride(from: 0, to: current.count, by: 2) { busy &+= current[i] &- previous[i]; total &+= current[i + 1] &- previous[i + 1] }
    return total > 0 ? Double(busy) / Double(total) * 100 : nil
  }
  func gpu() -> Double? {
    var it: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &it) == KERN_SUCCESS else { return nil }
    defer { IOObjectRelease(it) }
    var usage: Double?
    var s = IOIteratorNext(it)
    while s != 0 {
      var props: Unmanaged<CFMutableDictionary>?
      if IORegistryEntryCreateCFProperties(s, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
         let d = props?.takeRetainedValue() as? [String: Any], let ps = d["PerformanceStatistics"] as? [String: Any],
         let u = ps["Device Utilization %"] as? NSNumber { usage = max(usage ?? 0, u.doubleValue) }
      IOObjectRelease(s); s = IOIteratorNext(it)
    }
    return usage
  }
  /// GB of memory pushed to the SSD (swap)
  func swap() -> Double {
    var u = xsw_usage(); var t = MemoryLayout<xsw_usage>.size
    guard sysctlbyname("vm.swapusage", &u, &t, nil, 0) == 0 else { return 0 }
    return Double(u.xsu_used) / 1_073_741_824
  }
  /// (used, total) in GB and the macOS memory pressure (1 normal, 2 warning, 4 critical)
  func memory() -> (used: Double, total: Double, pressure: Int) {
    var st = vm_statistics64(); var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let r = withUnsafeMutablePointer(to: &st) { p in p.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) } }
    let total = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
    var pressure: Int32 = 1; var t = MemoryLayout<Int32>.size
    sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &t, nil, 0)
    guard r == KERN_SUCCESS else { return (0, total, Int(pressure)) }
    let pageSize = Double(vm_kernel_page_size)
    let app = Double(st.internal_page_count) - Double(st.purgeable_count)
    let used = (app + Double(st.wire_count) + Double(st.compressor_page_count)) * pageSize / 1_073_741_824
    return (min(used, total), total, Int(pressure))
  }
}

// ───────── model ─────────
struct Sample { let t: Date; let temp: Double?; let cpu: Double? }
struct TopProcess: Identifiable { let id = UUID(); let name: String; let cpu: Double }

@MainActor
final class Monitor: ObservableObject {
  @Published var temp: Double?
  @Published var battery: Double?
  @Published var ssd: Double?
  @Published var cpu: Double?
  @Published var gpu: Double?
  @Published var memUsed = 0.0
  @Published var memTotal = 0.0
  @Published var pressure = 1
  @Published var swap = 0.0
  @Published var fans: [(current: Double, maximum: Double)] = []
  @Published var macState = ProcessInfo.ThermalState.nominal
  @Published var level = Level.ok
  @Published var history: [Sample] = []
  @Published var processes: [TopProcess] = []
  @Published var panelOpen = false { didSet { if panelOpen { readProcesses() } } }

  private let temps = Temperatures(), load = Load(), smc = SMC()
  private var clock: Timer?, counter = 0

  init() {
    sample()
    clock = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in Task { @MainActor in self?.sample() } }
    clock?.tolerance = 0.5
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  func sample() {
    let t = temps.read()
    temp = t.chip; battery = t.battery; ssd = t.ssd
    cpu = load.cpu(); gpu = load.gpu()
    let m = load.memory(); memUsed = m.used; memTotal = m.total; pressure = m.pressure; swap = load.swap()
    macState = ProcessInfo.processInfo.thermalState
    counter += 1
    if counter % 3 == 1, let smc { fans = smc.fans() }
    history.append(Sample(t: Date(), temp: temp, cpu: cpu))
    if history.count > 300 { history.removeFirst(history.count - 300) } // 10 minutes
    evaluate()
    if panelOpen && counter % 2 == 0 { readProcesses() }
  }

  // ── one level per risk; the icon shows the worst ──
  @Published var chipLevel = Level.ok
  var batteryLevel: Level { guard let b = battery else { return .ok }; return b >= Limit.batteryHigh ? .pause : b >= Limit.batteryWarn ? .warn : .ok }
  var ssdLevel: Level { guard let d = ssd else { return .ok }; return d >= Limit.ssdHigh ? .pause : d >= Limit.ssdWarn ? .warn : .ok }
  var memoryLevel: Level { pressure >= 4 ? .pause : (pressure >= 2 || swap >= Limit.swapWarn) ? .warn : .ok }

  /// chip with hysteresis: after pausing, it only goes back to normal below the resume limit
  private func evaluate() {
    let T = temp ?? 0
    var raw: Level = T >= Limit.critical ? .critical : T >= Limit.pause ? .pause : T >= Limit.warn ? .warn : .ok
    switch macState {
    case .critical: raw = max(raw, .critical)
    case .serious: raw = max(raw, .pause)
    case .fair: raw = max(raw, .warn)
    default: break
    }
    if raw < chipLevel && chipLevel >= .pause && T >= Limit.resume { raw = .warn } // still cooling down
    chipLevel = raw
    let next = max(chipLevel, batteryLevel, ssdLevel, memoryLevel)
    if next != level { alert(from: level, to: next) }
    level = next
  }

  var reason: String {
    if level == .ok { return L.t("Chip, battery, memory and SSD within normal range.") }
    // explain the most serious risk (in the order of what damages the machine most)
    if chipLevel == .critical { return L.t("Chip at critical temperature. Close what is heavy now (see below).") }
    if batteryLevel == level, let b = battery { return L.f("Battery at %@ °C. Battery heat wears the Mac the most: unplug it or lighten the load%@.", "\(Int(b))", level >= .pause ? " " + L.t("now") : "") }
    if chipLevel == level {
      if level == .pause { return L.f("Chip above %@ °C%@. Pause heavy work until it drops below %@ °C.", "\(Int(Limit.pause))", macState == .serious ? " " + L.t("and macOS is already slowing things down") : "", "\(Int(Limit.resume))") }
      if macState == .fair && (temp ?? 0) < Limit.warn { return L.t("macOS reported moderate heat. Avoid starting a render or export now.") }
      return (temp ?? 0) >= Limit.warn ? L.f("Chip above %@ °C. Avoid starting a render or export now.", "\(Int(Limit.warn))") : L.f("Cooling down. Wait until it drops below %@ °C to resume heavy work.", "\(Int(Limit.resume))")
    }
    if memoryLevel == level { return pressure >= 4 ? L.t("Memory exhausted: the Mac is writing memory to the SSD non-stop. Close apps now.") : L.f("Memory is tight (%@ GB on the SSD). Close apps you are not using.", String(format: "%.1f", swap)) }
    if ssdLevel == level, let d = ssd { return L.f("SSD at %@ °C. Avoid large writes and copies until it cools.", "\(Int(d))") }
    return L.t("Check one of the sensors.")
  }

  private func alert(from: Level, to: Level) {
    guard Settings.shared.notify, to > from || to == .ok && from >= .pause else { return }
    let c = UNMutableNotificationContent()
    c.title = to == .ok ? L.t("Mac back to normal") : L.f("Mac: %@", to.title.lowercased())
    c.body = to == .ok ? L.t("Chip, battery, memory and SSD within normal range.") : reason
    if to >= .pause && Settings.shared.soundOnPause { c.sound = .default }
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
  }

  func readProcesses() {
    DispatchQueue.global(qos: .utility).async {
      let p = Process(); p.executableURL = URL(fileURLWithPath: "/bin/ps"); p.arguments = ["-Aceo", "pcpu=,comm=", "-r"]
      let output = Pipe(); p.standardOutput = output; p.standardError = Pipe()
      guard (try? p.run()) != nil else { return }
      let data = output.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
      let lines = (String(data: data, encoding: .utf8) ?? "").split(separator: "\n").prefix(4)
      let list: [TopProcess] = lines.compactMap { l in
        let parts = l.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1)
        guard parts.count == 2, let v = Double(parts[0].replacingOccurrences(of: ",", with: ".")), v >= 5 else { return nil }
        return TopProcess(name: String(parts[1]), cpu: v / Double(max(ProcessInfo.processInfo.activeProcessorCount, 1)))
      }
      DispatchQueue.main.async { self.processes = Array(list.prefix(3)) }
    }
  }
}

// ───────── visuals ─────────
let cardFill = Color.white.opacity(0.055)
let hairline = Color.white.opacity(0.08)
let dimText = Color.white.opacity(0.55)

// ───────── the brand stone (compact version, generated by brand/generate_stone_swift.py; do not edit by hand) ─────────
enum Stone {
  static let box = CGRect(x: 52.8, y: 50.3, width: 154.6, height: 157.2)
  static let base: [[CGFloat]] = [[76.6,190.6,78.3,193.1,81.3,194.7,139.2,207.5,142.5,206.4,183.8,180,178.3,175.3,172.5,171.2,167.7,169.3,152,164.7,145.9,161.7,141.7,158.4,140.2,156.6,138,151.8,134.6,137.3,133.2,134,129.7,129.2,117.3,116.4,97.6,118.7,88.4,120.8,80.9,124.2,63.2,134.4,55.8,137.7],
    [207.1,115.1,207.3,112.5,206.4,109.6,171.9,58.8,169.9,56.8,166.7,55.7,103.6,50.3,100.4,51.2,97.9,53.4,59.7,115.5,76.8,113.3,84.5,111.6,92.3,108.2,107.9,98.7,116.3,94.4,121.9,93,126.1,93.9,129.7,96.3,133.6,102.3,136,107.7,141.2,123.3,144.2,128.7,157.6,140.7,164.5,146,178,161.5,183.4,165,192,169.1,190.7,173.4]]
  static let ember: [[CGFloat]] = [[70.9,114.1,59.7,115.5,53.7,125.3,52.9,127.6,53.1,130.6,55.8,137.7,63.2,134.4,80.9,124.2,88.4,120.8,97.6,118.7,117.3,116.4,129.7,129.2,133.2,134,134.6,137.3,138.5,153.2,140.2,156.6,143.5,159.9,152,164.7,171.8,170.9,177.1,174.4,183.8,180,188.3,177,190.2,174.7,192,169.1,183.4,165,178,161.5,164.5,146,157.6,140.7,144.2,128.7,141.2,123.3,136,107.7,133.6,102.3,129.7,96.3,126.1,93.9,121.9,93,117.7,93.9,109.2,98,88.7,110,81.2,112.5]]
  static func path(_ rings: [[CGFloat]], in r: NSRect) -> NSBezierPath {
    let k = min(r.width / box.width, r.height / box.height)
    let ox = r.midX - box.midX * k, oy = r.midY + box.midY * k
    let p = NSBezierPath(); p.windingRule = .evenOdd
    for ring in rings {
      for i in stride(from: 0, to: ring.count, by: 2) {
        let pt = NSPoint(x: ox + ring[i] * k, y: oy - ring[i + 1] * k)
        if i == 0 { p.move(to: pt) } else { p.line(to: pt) }
      }
      p.close()
    }
    return p
  }
  /// the stone (light enough to show on a dark menu bar) with the ember in the state's color
  static func draw(in r: NSRect, ember color: NSColor) {
    let dark = NSAppearance.currentDrawing().bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    (dark ? NSColor(red: 0.36, green: 0.36, blue: 0.39, alpha: 1) : NSColor(red: 0.055, green: 0.05, blue: 0.05, alpha: 1)).setFill()
    path(base, in: r).fill()
    color.setFill(); path(ember, in: r).fill()
  }
}



/// menu bar item: the stone with the ember in the worst-risk color + small labels above and values below (colored only when that item needs attention)
func menuBarImage(level: Level, blocks: [(String, String, Level)]) -> NSImage {
  let labelFont = NSFont.systemFont(ofSize: 7.5, weight: .semibold), value = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
  let widths = blocks.map { max(($0.0 as NSString).size(withAttributes: [.font: labelFont]).width, ($0.1 as NSString).size(withAttributes: [.font: value]).width) }
  let gap: CGFloat = 7, dot: CGFloat = 16
  let width = dot + gap + widths.reduce(0, +) + gap * CGFloat(blocks.count - 1) + 1
  let img = NSImage(size: NSSize(width: ceil(width), height: 22), flipped: false) { _ in
    Stone.draw(in: NSRect(x: 0, y: 3, width: dot, height: 16), ember: level.nsColor)
    var x = dot + gap
    for (i, (r, val, n)) in blocks.enumerated() {
      let textColor = n == .ok ? NSColor.labelColor : n.nsColor
      (r as NSString).draw(at: NSPoint(x: x, y: 12.5), withAttributes: [.font: labelFont, .foregroundColor: n == .ok ? NSColor.secondaryLabelColor : n.nsColor])
      (val as NSString).draw(at: NSPoint(x: x, y: -0.5), withAttributes: [.font: value, .foregroundColor: textColor])
      x += widths[i] + gap
    }
    return true
  }
  img.isTemplate = false
  return img
}

func menuBarDot(_ color: NSColor) -> NSImage {
  let img = NSImage(size: NSSize(width: 9, height: 9), flipped: false) { r in
    color.setFill(); NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1)).fill(); return true
  }
  img.isTemplate = false
  return img
}

struct Scale: View { // horizontal thermometer with the safety bands
  let temp: Double?
  @ObservedObject private var settings = Settings.shared   // redraws when a limit changes
  func x(_ v: Double, _ w: CGFloat) -> CGFloat { CGFloat((min(max(v, Limit.scaleMin), Limit.scaleMax) - Limit.scaleMin) / (Limit.scaleMax - Limit.scaleMin)) * w }
  var body: some View {
    GeometryReader { g in
      let w = g.size.width
      ZStack(alignment: .leading) {
        HStack(spacing: 2) {
          Capsule().fill(Level.ok.color.opacity(0.35)).frame(width: x(Limit.warn, w) - 2)
          Rectangle().fill(Level.warn.color.opacity(0.45)).frame(width: x(Limit.pause, w) - x(Limit.warn, w) - 2)
          Rectangle().fill(Level.pause.color.opacity(0.5)).frame(width: x(Limit.critical, w) - x(Limit.pause, w) - 2)
          Capsule().fill(Level.critical.color.opacity(0.55))
        }.frame(height: 6)
        if let t = temp {
          Circle().fill(.white).frame(width: 12, height: 12).shadow(color: .black.opacity(0.5), radius: 3)
            .offset(x: x(t, w) - 6).animation(.easeInOut(duration: 0.8), value: t)
        }
      }
      .frame(height: 12)
      ForEach([Limit.warn, Limit.pause, Limit.critical], id: \.self) { v in
        Text("\(Int(v))°").font(.system(size: 9.5, weight: .medium).monospacedDigit()).foregroundStyle(dimText)
          .position(x: x(v, w), y: 24)
      }
    }.frame(height: 30)
  }
}

struct Graph: View { // last 10 minutes: temperature (line) and CPU (area)
  let samples: [Sample]; let color: Color
  var body: some View {
    GeometryReader { g in
      let w = g.size.width, h = g.size.height, n = max(samples.count - 1, 1)
      let px = { (i: Int) in CGFloat(i) / CGFloat(n) * w }
      let py = { (v: Double, lo: Double, hi: Double) in h - CGFloat((min(max(v, lo), hi) - lo) / (hi - lo)) * h }
      ZStack {
        ForEach([Limit.warn, Limit.pause], id: \.self) { v in
          Path { p in let y = py(v, 30, 105); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: w, y: y)) }
            .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
        }
        Path { p in
          p.move(to: .init(x: 0, y: h))
          for (i, a) in samples.enumerated() { p.addLine(to: .init(x: px(i), y: py(a.cpu ?? 0, 0, 100))) }
          p.addLine(to: .init(x: w, y: h)); p.closeSubpath()
        }.fill(Color.white.opacity(0.07))
        Path { p in
          var first = true
          for (i, a) in samples.enumerated() { guard let t = a.temp else { continue }
            let pt = CGPoint(x: px(i), y: py(t, 30, 105)); if first { p.move(to: pt); first = false } else { p.addLine(to: pt) } }
        }.stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
      }
    }
  }
}

struct Card<C: View>: View {
  let title: String; let icon: String; @ViewBuilder let content: C
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: icon).font(.system(size: 10.5, weight: .semibold)).foregroundStyle(dimText).labelStyle(.titleAndIcon)
      content
    }
    .padding(11).frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12).fill(cardFill))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(hairline))
  }
}

struct Metric: View {
  let name: String; let value: String
  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(name).font(.system(size: 9.5, weight: .semibold)).foregroundStyle(dimText)
      Text(value).font(.system(size: 12, design: .rounded).monospacedDigit()).foregroundStyle(.white.opacity(0.85))
    }
  }
}

struct Bar: View {
  let value: Double; let color: Color
  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(0.08))
        Capsule().fill(color).frame(width: max(3, g.size.width * CGFloat(min(value, 100) / 100))).animation(.easeInOut(duration: 0.6), value: value)
      }
    }.frame(height: 4)
  }
}

struct Value: View {
  let text: String; var unit = ""
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 2) {
      Text(text).font(.system(size: 20, weight: .light, design: .rounded).monospacedDigit()).foregroundStyle(.white)
      if !unit.isEmpty { Text(unit).font(.system(size: 11)).foregroundStyle(dimText) }
    }
  }
}

struct Panel: View {
  @ObservedObject var v: Monitor
  @State private var launchAtLogin = LaunchAtLogin.isEnabled
  @ObservedObject private var settings = Settings.shared   // redraws when a limit changes
  private func pct(_ x: Double?) -> String { x.map { "\(Int($0.rounded()))" } ?? "–" }
  private var loadColor: (Double?) -> Color { { x in (x ?? 0) >= Limit.loadHigh ? Level.pause.color : (x ?? 0) >= Limit.loadMedium ? Level.warn.color : Color.white.opacity(0.75) } }
  private var macStateText: String { [L.t("normal"), L.t("moderate"), L.t("serious"), L.t("critical")][v.macState.rawValue] }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      // state
      HStack(alignment: .top, spacing: 12) {
        ZStack {
          Circle().fill(v.level.color.opacity(0.18)).frame(width: 34, height: 34)
          Circle().fill(v.level.color).frame(width: 12, height: 12).shadow(color: v.level.color.opacity(0.8), radius: 6)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text(v.level.title).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
          Text(v.reason).font(.system(size: 12)).foregroundStyle(dimText).fixedSize(horizontal: false, vertical: true)
        }
      }

      // temperature
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline) {
          Text(v.temp.map { "\(Int($0.rounded()))" } ?? "–").font(.system(size: 52, weight: .ultraLight, design: .rounded).monospacedDigit()).foregroundStyle(.white)
            + Text(" °C").font(.system(size: 16, weight: .light)).foregroundStyle(dimText)
          Spacer()
          VStack(alignment: .trailing, spacing: 2) {
            Text("chip").font(.system(size: 11, weight: .medium)).foregroundStyle(v.chipLevel == .ok ? dimText : v.chipLevel.color)
            Text(L.f("macOS: %@", macStateText)).font(.system(size: 11)).foregroundStyle(v.macState == .nominal ? dimText : Level.warn.color)
          }
        }
        Scale(temp: v.temp)
        Graph(samples: v.history, color: v.level == .ok ? Color(red: 1, green: 0.15, blue: 0.54) : v.level.color).frame(height: 46)
        HStack { Text(L.t("last 10 min")).font(.system(size: 9.5)); Spacer(); Text(L.t("line: temperature · area: CPU")).font(.system(size: 9.5)) }.foregroundStyle(dimText.opacity(0.8))
      }

      // other risks
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
        Card(title: L.t("Battery"), icon: "battery.75") {
          Value(text: v.battery.map { "\(Int($0.rounded()))" } ?? "–", unit: "°C").foregroundStyle(v.batteryLevel == .ok ? .white : v.batteryLevel.color)
          Bar(value: ((v.battery ?? 20) - 20) / (Limit.batteryHigh + 5 - 20) * 100, color: v.batteryLevel == .ok ? Color.white.opacity(0.75) : v.batteryLevel.color)
        }
        Card(title: L.t("Memory"), icon: "memorychip") {
          Value(text: String(format: "%.1f", max(v.memTotal - v.memUsed, 0)), unit: "GB")
          Bar(value: v.memTotal > 0 ? v.memUsed / v.memTotal * 100 : 0, color: v.memoryLevel == .ok ? Color.white.opacity(0.75) : v.memoryLevel.color)
        }
        Card(title: "SSD", icon: "internaldrive") {
          Value(text: v.ssd.map { "\(Int($0.rounded()))" } ?? "–", unit: "°C")
          Bar(value: ((v.ssd ?? 25) - 25) / (Limit.ssdHigh + 5 - 25) * 100, color: v.ssdLevel == .ok ? Color.white.opacity(0.75) : v.ssdLevel.color)
        }
      }
      HStack(spacing: 14) { // what generates the heat (information, not risk)
        Metric(name: "CPU", value: v.cpu.map { "\(Int($0.rounded()))%" } ?? "–")
        Metric(name: "GPU", value: v.gpu.map { "\(Int($0.rounded()))%" } ?? "–")
        Metric(name: "Swap", value: v.swap < 0.05 ? "0" : String(format: "%.1f GB", v.swap))
        Metric(name: L.t("Fan"), value: { let r = v.fans.map(\.current).max() ?? 0; return v.fans.isEmpty ? "–" : r < 100 ? L.t("idle") : "\(Int(r)) rpm" }())
      }

      // what is heating up
      if !v.processes.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          Text(L.t("Top processes by CPU (% of total)")).font(.system(size: 10.5, weight: .semibold)).foregroundStyle(dimText)
          ForEach(v.processes) { p in
            HStack {
              Text(p.name).font(.system(size: 12)).foregroundStyle(.white.opacity(0.9)).lineLimit(1).truncationMode(.middle)
              Spacer()
              Text("\(Int(p.cpu.rounded()))%").font(.system(size: 12, design: .rounded).monospacedDigit()).foregroundStyle(loadColor(p.cpu))
            }
          }
        }
      }

      Divider().overlay(hairline)
      HStack(spacing: 10) {
        Text(L.f("Chip: slows %@° · pauses %@° · critical %@° · battery %@°", "\(Int(Limit.warn))", "\(Int(Limit.pause))", "\(Int(Limit.critical))", "\(Int(Limit.batteryWarn))")).font(.system(size: 10.5).monospacedDigit()).foregroundStyle(dimText)
        Spacer()
      }
      HStack {
        Toggle(L.t("Open at login"), isOn: $launchAtLogin).toggleStyle(.switch).controlSize(.mini).font(.system(size: 11.5)).foregroundStyle(.white.opacity(0.8))
          .onChange(of: launchAtLogin) { _, next in LaunchAtLogin.set(next); launchAtLogin = LaunchAtLogin.isEnabled }
        Spacer()
        Button { SettingsWindow.open() } label: { Label(L.t("Settings"), systemImage: "slider.horizontal.3") }.buttonStyle(.plain).font(.system(size: 11.5)).foregroundStyle(dimText)
        Button(L.t("Quit")) { NSApp.terminate(nil) }.buttonStyle(.plain).font(.system(size: 11.5)).foregroundStyle(dimText).padding(.leading, 10)
      }
    }
    .padding(16)
    .frame(width: 330)
    .background(LinearGradient(colors: [v.level.color.opacity(v.level == .ok ? 0.06 : 0.16), .clear], startPoint: .top, endPoint: .center))
    .preferredColorScheme(.dark)
    .onAppear { v.panelOpen = true }
    .onDisappear { v.panelOpen = false }
  }
}

// ───────── settings window ─────────
struct LimitRow: View {
  let title: String, hint: String, key: Key
  @ObservedObject private var settings = Settings.shared
  init(_ title: String, _ hint: String, _ key: Key) { self.title = title; self.hint = hint; self.key = key }
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(title).font(.system(size: 12.5))
        Spacer()
        Text(key.step < 1 ? String(format: "%.1f %@", settings.value(key), key.unit) : "\(Int(settings.value(key))) \(key.unit)").font(.system(size: 12.5, weight: .semibold).monospacedDigit())
          .foregroundStyle(settings.isDefault(key) ? Color.white : Level.warn.color)
        Button { settings.restore(key) } label: { Image(systemName: "arrow.uturn.backward") }
          .buttonStyle(.plain).foregroundStyle(dimText).opacity(settings.isDefault(key) ? 0 : 1).disabled(settings.isDefault(key)).help(L.f("Back to default (%@ %@)", "\(Int(key.defaultValue))", key.unit))
      }
      Slider(value: Binding(get: { settings.value(key) }, set: { settings.set(key, $0) }), in: key.range, step: key.step)
      Text(hint).font(.system(size: 10.5)).foregroundStyle(dimText)
    }
  }
}

struct SettingsView: View {
  @ObservedObject private var settings = Settings.shared
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 3) {
          Text(L.t("Settings")).font(.system(size: 20, weight: .semibold))
          Text(L.t("The factory values are only defaults. Change what you like; limits adjust each other to keep their order.")).font(.system(size: 11.5)).foregroundStyle(dimText)
        }
        group(L.t("Language")) {
          Picker(L.t("Language"), selection: $settings.language) { ForEach(Language.allCases) { Text($0.name).tag($0) } }.labelsHidden().pickerStyle(.segmented)
        }
        group(L.t("Chip")) {
          LimitRow(L.t("Slow down from"), L.t("Warning: avoid starting a render or export."), .chipWarn)
          LimitRow(L.t("Pause from"), L.t("Pause heavy work."), .chipPause)
          LimitRow(L.t("Critical from"), L.t("Close what is heavy right now."), .chipCritical)
          LimitRow(L.t("Back to normal below"), L.t("After pausing, it only clears once it cools down to here."), .chipResume)
        }
        group(L.t("Battery")) {
          LimitRow(L.t("Warning from"), L.t("Above about 40 °C the battery ages faster."), .batteryWarn)
          LimitRow(L.t("High from"), L.t("Heat that causes damage."), .batteryHigh)
        }
        group("SSD") {
          LimitRow(L.t("Warning from"), L.t("Avoid large writes and copies."), .ssdWarn)
          LimitRow(L.t("High from"), "", .ssdHigh)
        }
        group(L.t("Memory")) {
          LimitRow(L.t("Warn when swap is above"), L.t("The Mac is writing memory to the SSD non-stop."), .swapWarn)
        }
        group(L.t("Highlighted processes")) {
          LimitRow(L.t("Yellow from"), L.t("% of the processor used by one process."), .loadMedium)
          LimitRow(L.t("Orange from"), "", .loadHigh)
        }
        group(L.t("Notifications")) {
          Toggle(L.t("Notify when the level changes"), isOn: $settings.notify).toggleStyle(.switch).controlSize(.small)
          Toggle(L.t("Play a sound on pause and critical"), isOn: $settings.soundOnPause).toggleStyle(.switch).controlSize(.small).disabled(!settings.notify)
        }
        HStack {
          Spacer()
          Button(L.t("Restore all defaults")) { settings.restore() }.disabled(settings.allDefault)
        }
      }.padding(20)
    }
    .frame(width: 400, height: 640)
    .preferredColorScheme(.dark)
  }
  private func group<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(t.uppercased()).font(.system(size: 10.5, weight: .semibold)).tracking(0.8).foregroundStyle(dimText)
      VStack(alignment: .leading, spacing: 12) { c() }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardFill)).overlay(RoundedRectangle(cornerRadius: 10).stroke(hairline))
    }
  }
}

@MainActor
enum SettingsWindow {
  private static var window: NSWindow?
  static func open() {
    if window == nil {
      let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 640), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
      w.title = L.t("Brasa · Settings")
      w.contentView = NSHostingView(rootView: SettingsView())
      w.isReleasedWhenClosed = false
      w.center()
      window = w
    }
    window?.title = L.t("Brasa · Settings")
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
  }
}

// ───────── launch at login ─────────
enum LaunchAtLogin {
  static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
  static func set(_ on: Bool) { try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
}

// ───────── app ─────────
// Hand-made status item (NSStatusItem) so it is born at the far right: on a crowded menu bar (notch), macOS hides
// what sits next to the notch first, and a new app always lands there.
@MainActor
final class MenuBar: NSObject, NSApplicationDelegate {
  let v = Monitor()
  var item: NSStatusItem!
  let pop = NSPopover()
  var observer: AnyCancellable?

  func applicationDidFinishLaunching(_ n: Notification) {
    let name = "brasa-menubar"
    let key = "NSStatusItem Preferred Position \(name)"
    if UserDefaults.standard.object(forKey: key) == nil { UserDefaults.standard.set(1, forKey: key) } // far right
    item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.autosaveName = name
    item.behavior = []
    item.button?.target = self; item.button?.action = #selector(toggle)
    pop.behavior = .transient; pop.animates = true
    pop.contentViewController = NSHostingController(rootView: Panel(v: v))
    paint()
    observer = v.objectWillChange.sink { [weak self] _ in DispatchQueue.main.async { self?.paint() } }
  }
  func paint() {
    guard let b = item?.button else { return }
    let blocks: [(String, String, Level)] = [
      ("CHIP", v.temp.map { "\(Int($0.rounded()))°" } ?? "–", v.chipLevel),
      ("BAT", v.battery.map { "\(Int($0.rounded()))°" } ?? "–", v.batteryLevel),
      ("MEM", v.memTotal > 0 ? String(format: "%.0fG", max(v.memTotal - v.memUsed, 0)) : "–", v.memoryLevel),
    ]
    b.image = menuBarImage(level: v.level, blocks: blocks); b.imagePosition = .imageOnly; b.title = ""
    b.toolTip = "Brasa · \(v.level.title)"
  }
  @objc func toggle() {
    guard let b = item.button else { return }
    if pop.isShown { pop.performClose(nil) } else { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY); NSApp.activate(ignoringOtherApps: true) }
  }
}

@main
enum Main {
  static func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    // --language en|pt|es: forces the language for this run only (for previews; not saved to preferences)
    if let i = CommandLine.arguments.firstIndex(of: "--language"), i + 1 < CommandLine.arguments.count, let id = Language(rawValue: CommandLine.arguments[i + 1]) {
      _ = Settings.shared; L.choice = { id }
    }
    if let i = CommandLine.arguments.firstIndex(of: "--preview-settings"), i + 1 < CommandLine.arguments.count {
      // --preview-settings <file.png>: renders the settings window and exits
      let output = CommandLine.arguments[i + 1]
      Task { @MainActor in
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 640), styleMask: [.titled], backing: .buffered, defer: false)
        let h = NSHostingView(rootView: SettingsView()); w.contentView = h; w.appearance = NSAppearance(named: .darkAqua)
        w.orderFrontRegardless()
        try? await Task.sleep(for: .seconds(1.5))
        if let rep = h.bitmapImageRepForCachingDisplay(in: h.bounds) {
          h.cacheDisplay(in: h.bounds, to: rep)
          if let png = rep.representation(using: .png, properties: [:]) { try? png.write(to: URL(fileURLWithPath: output)) }
        }
        exit(0)
      }
      app.run(); return
    }
    if let i = CommandLine.arguments.firstIndex(of: "--preview"), i + 1 < CommandLine.arguments.count {
      // --preview <file.png>: renders the panel with live data and exits (to check the look without the menu bar)
      let output = CommandLine.arguments[i + 1]
      Task { @MainActor in
        let v = Monitor(); v.panelOpen = true
        try? await Task.sleep(for: .seconds(8))
        let r = ImageRenderer(content: Panel(v: v).background(Color(red: 0.11, green: 0.11, blue: 0.12)).environment(\.colorScheme, .dark))
        r.scale = 2
        if let img = r.nsImage, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
          try? png.write(to: URL(fileURLWithPath: output))
        }
        // the menu bar item too, on a dark backdrop (as in dark mode)
        let blocks: [(String, String, Level)] = [("CHIP", v.temp.map { "\(Int($0.rounded()))°" } ?? "–", v.chipLevel), ("BAT", v.battery.map { "\(Int($0.rounded()))°" } ?? "–", v.batteryLevel), ("MEM", String(format: "%.0fG", max(v.memTotal - v.memUsed, 0)), v.memoryLevel)]
        let bar = menuBarImage(level: v.level, blocks: blocks)
        let backdrop = NSImage(size: NSSize(width: bar.size.width + 24, height: 24), flipped: false) { r in
          NSColor(white: 0.16, alpha: 1).setFill(); r.fill(); NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance { bar.draw(at: NSPoint(x: 12, y: 1), from: .zero, operation: .sourceOver, fraction: 1) }; return true }
        if let t = backdrop.tiffRepresentation, let rep = NSBitmapImageRep(data: t), let png = rep.representation(using: .png, properties: [:]) { try? png.write(to: URL(fileURLWithPath: output.replacingOccurrences(of: ".png", with: "-menubar.png"))) }
        exit(0)
      }
      app.run(); return
    }
    let d = MenuBar(); app.delegate = d
    withExtendedLifetime(d) { app.run() }
  }
}
