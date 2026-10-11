<p align="center"><img src="brand/kit/logotype/logotype-plate.svg" alt="Brasa" height="96"></p>

<h1 align="center">Brasa: Mac menu bar temperature monitor for Apple Silicon</h1>

<p align="center"><b>A free, open-source menu bar app that watches your Mac's chip, battery and SSD temperature, memory pressure and fans, and warns you before it overheats. No sudo. No telemetry.</b></p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-111?style=flat-square&logo=apple&logoColor=white">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-M1%E2%80%93M5-FF5A14?style=flat-square">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-SwiftUI-FF5A14?style=flat-square&logo=swift&logoColor=white">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-111?style=flat-square">
  <img alt="No sudo" src="https://img.shields.io/badge/sudo-not%20needed-33CC80?style=flat-square">
</p>

<p align="center"><img src="brand/kit/animated/brasa-live-plate.svg" alt="Brasa: a black piece of coal with glowing ember veins" height="220"></p>

Brasa lives in your Mac's menu bar and answers one question: **is my Mac too hot right now?** It reads the Apple Silicon
sensors (chip, battery, SSD), memory pressure and swap, CPU and GPU load, fan speed and the macOS thermal state, turns them
into four clear levels, and tells you in plain words when to stop a heavy render, export or build. The stone icon in the
menu bar changes color with the state of your Mac, and you get a notification when it heats up and when it cools down.

> **Multilingual:** the interface is available in **English, Português (Brasil) and Español**. It follows your Mac's language and you can switch it in Settings. Leia em português: [README.pt-BR.md](README.pt-BR.md).

## Contents

[Why Brasa](#why-brasa) · [Features](#features) · [Screenshot](#screenshot) · [Install](#install) · [The four levels](#the-four-levels) · [Settings](#settings-your-limits) · [How it works](#how-it-works) · [FAQ](#faq) · [Alternatives](#alternatives) · [Roadmap](#roadmap) · [Support](#support) · [License](#license)

## Why Brasa

Heavy work on a MacBook (video render, Xcode builds, local AI models, long exports) can push the chip into thermal throttling
without any warning. Most monitors show numbers. Brasa shows **a status and what to do next**, keeps your own thresholds, and stays
out of the way: about 1% of one CPU core and ~55 MB of memory.

## Features

- **Chip temperature on Apple Silicon (M1 to M5), no `sudo`.** Sensors are read inside the app through IOKit; there is no helper tool and no password prompt.
- **Four levels** (safe, warming up, too hot, critical) with the reason and the next step in plain language.
- **Menu bar stone** that changes color with the state, plus the live chip, battery and free-memory values.
- **Battery and SSD temperature**, **memory pressure and swap**, **CPU and GPU load**, **fan speed**, and the **macOS thermal state**.
- **10-minute graph** of temperature and CPU, and the **top processes** heating the machine (only read while the panel is open).
- **Adjustable thresholds** and notifications (see [Settings](#settings-your-limits)), with a cool-down margin so alerts do not flap at the edge of a limit.
- **Scriptable:** `--json`, `--watch` and a local Prometheus endpoint (`--serve`), with the status and the advice in the output, not only raw numbers (see [Command line](#command-line-json-and-prometheus)).
- **Launch at login**, and **private by design**: no network requests, no analytics.

## Screenshot

<p align="center"><img src="docs/screenshot-panel.png" alt="Brasa panel: 56 °C chip temperature, 10-minute graph, battery, memory and SSD cards, top processes" width="330"></p>

## Install

**Homebrew** (recommended, opens without any security prompt):

```bash
brew install renatoalves-me/brasa/brasa
brasa --install                   # puts Brasa.app in ~/Applications and opens it
```

Homebrew builds it on your Mac in a few seconds, so macOS opens it right away. After `brew upgrade`, run `brasa --install` again.

**Download:** grab `Brasa-v*-arm64.zip` from [Releases](https://github.com/renatoalves-me/brasa/releases), unzip, move to Applications. The build is not notarized yet, so macOS blocks the first launch: open **System Settings → Privacy & Security** and click **Open Anyway** next to Brasa. A notarized build is on the [roadmap](#roadmap).

**From source** (only the Xcode Command Line Tools):

```bash
xcode-select --install            # once, if you do not have them
git clone https://github.com/renatoalves-me/brasa.git
cd brasa
./build.sh                        # builds and installs ~/Applications/Brasa.app
open ~/Applications/Brasa.app
```

Requirements: an Apple Silicon Mac and macOS 14 (Sonoma) or later. Intel Macs are not supported.

Preview without opening the menu bar: `~/Applications/Brasa.app/Contents/MacOS/Brasa --preview panel.png`
(and `--preview-settings settings.png`).

## Command line, JSON and Prometheus

The same binary is a CLI. Every output carries the **status and what to do next**, not only numbers.

```bash
brasa --json                 # one reading: status, advice, temperatures, load, memory, fans, thresholds
brasa --watch 5              # one JSON line every 5 s (pipe it to jq)
brasa --prometheus           # Prometheus text format
brasa --serve 9091           # http://127.0.0.1:9091/metrics, /json, /healthz
brasa --sensors              # every temperature sensor your Mac exposes
```

```bash
$ brasa --json | jq '.status'
{ "level": "too_hot", "level_index": 2, "title": "Too hot",
  "advice": "Chip above 92 °C. Pause heavy work until it drops below 80 °C." }
```

`--serve` listens on the loopback interface only (127.0.0.1): nothing leaves your Mac, nothing outside it can connect.
Alert on `brasa_level >= 2` in Prometheus or Grafana. Without Homebrew, the command is at `~/Applications/Brasa.app/Contents/MacOS/Brasa`.

## The four levels

| Level | Chip default | What Brasa says |
|---|---|---|
| Safe | below 85 °C | Everything within the normal range. |
| Warming up | 85 °C and above | Avoid starting a render or export now. |
| Too hot | 92 °C and above | Pause heavy work until it drops below 80 °C. |
| Critical | 100 °C and above, or macOS throttling hard | Close what is heavy now. |

Battery (40 / 45 °C), SSD (70 / 80 °C) and memory pressure raise the level too. The macOS thermal state can only raise it, never lower it.

## Settings: your limits

The numbers above are only **defaults**. Open **Settings** in the panel footer to change the chip (warn, pause, critical and
"back to normal below"), battery, SSD, swap and process-highlight thresholds, and to turn notifications and sound on or off.
Limits keep their order automatically (raising "warn" above "pause" pushes "pause" up), each one has a "back to default" button,
and there is "restore all defaults".

## How it works

- **Temperatures:** the HID event system (IOKit) for chip, battery and SSD sensors, read in-process every 2 seconds.
- **Fans:** the SMC, read through IOKit. Brasa only reads; it never changes fan curves.
- **Load and memory:** standard Mach and system APIs. The process list uses `ps` and runs only while the panel is open.
- **State:** a level per risk (chip with hysteresis, battery, SSD, memory); the menu bar shows the worst one.

The app is [`Brasa.swift`](Brasa.swift) plus [`Localization.swift`](Localization.swift), the translation table (English is the key; add a column to add a language).
Run the translation check with `./tests/run.sh`: it fails if any sentence is missing a translation or a `%@` placeholder does not match.

## FAQ

**Does Brasa need sudo or admin rights?** No. There is no password prompt and no privileged helper.

**Which Macs work?** Apple Silicon (M1 to M5) on macOS 14+. It is developed and verified on a MacBook Pro with M4 Pro; M5 uses the same sensor interface but is not tested on real hardware yet. Sensor names can differ between
chips: run `brasa --sensors` and please [open an issue](https://github.com/renatoalves-me/brasa/issues) with your model if a value looks wrong.

**Can it control my fans?** No. It is a monitor, not a fan controller.

**Does it send data anywhere?** No. The app makes no network requests and has no analytics.

**Why does my Mac get hot?** Sustained CPU/GPU load (renders, builds, local models), a closed lid on a dock, charging while under load, or a blocked vent.
Brasa shows which processes use the most CPU so you can act.

## Alternatives

Other good tools exist and solve different problems.

| | Brasa | [mactop](https://github.com/metaspartan/mactop) | [macmon](https://github.com/vladkens/macmon) | [Stats](https://github.com/exelban/Stats) |
|---|---|---|---|---|
| Runs without sudo | yes | yes | yes | yes |
| Menu bar | yes (main interface) | optional `--menubar` mode | no (terminal UI) | yes |
| Says if it is too hot and what to do | **yes (4 levels + advice)** | no, metrics | no, metrics | no, metrics |
| Your own thresholds + notifications | **yes** | no | no | partly |
| JSON output | yes | yes | yes | no |
| Prometheus endpoint | yes (loopback only) | yes (optional) | yes | no |
| Power (watts), ANE, DRAM bandwidth | no | yes | yes (power, ANE) | partly |
| Fan control | no (read-only by design) | optional | no | yes |
| Install | brew, zip, source | brew | brew, MacPorts | brew, dmg |

mactop and macmon go much deeper on raw performance metrics (power, per-core data, bandwidth). Brasa goes the other way: it
is built to answer "should I stop now?", with your limits and an alert, and it is light enough to leave on all day.
Comparison based on their public READMEs; check them for the latest.

Brasa does not try to be a full hardware dashboard (see iStat Menus or Stats) or a fan controller (Macs Fan Control, TG Pro).

## Roadmap

- [x] GitHub Releases zip and Homebrew (`brew install renatoalves-me/brasa/brasa`)
- [x] JSON, `--watch` and Prometheus output
- [ ] Notarized download (needs an Apple Developer ID)
- [x] English, Portuguese and Spanish interface (more languages welcome: see [`Localization.swift`](Localization.swift))
- [ ] Test reports for more Apple Silicon models
- [ ] Optional temperature unit (°F)

## Support

Brasa is free and open source. If it saved you from a hot Mac, you can help keep it going:

[![Support on Ko-fi](https://img.shields.io/badge/Ko--fi-support%20Brasa-FF5A14?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/H1T528G4KQ)

GitHub Sponsors will be added soon.

## Brand

Identity: a black piece of coal with veins of ember of varying thickness. Brandbook [`brand/brandbook/index.html`](brand/brandbook/index.html),
kit [`brand/kit/`](brand/kit/), summary [`brand/README.md`](brand/README.md). Fonts (Bricolage Grotesque, Geist Mono) are under the SIL Open Font License.

## License

[MIT](LICENSE) © 2026 Renato Alves.

<sub>Keywords: Mac temperature monitor, menu bar temperature, Apple Silicon temperature, M1 M2 M3 M4 M5 thermal monitor, MacBook overheating, CPU temperature Mac, Mac fan speed, macOS menu bar app, Swift, SwiftUI.</sub>
