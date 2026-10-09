<p align="center"><img src="brand/kit/logotype/logotype-plate.svg" alt="Brasa" height="96"></p>

<h1 align="center">Brasa: Mac menu bar temperature monitor for Apple Silicon</h1>

<p align="center"><b>A free, open-source menu bar app that watches your Mac's chip, battery and SSD temperature, memory pressure and fans, and warns you before it overheats. No sudo. No telemetry.</b></p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-111?style=flat-square&logo=apple&logoColor=white">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-M1%E2%80%93M4-FF5A14?style=flat-square">
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

- **Chip temperature on Apple Silicon (M1 to M4), no `sudo`.** Sensors are read inside the app through IOKit; there is no helper tool and no password prompt.
- **Four levels** (safe, warming up, too hot, critical) with the reason and the next step in plain language.
- **Menu bar stone** that changes color with the state, plus the live chip, battery and free-memory values.
- **Battery and SSD temperature**, **memory pressure and swap**, **CPU and GPU load**, **fan speed**, and the **macOS thermal state**.
- **10-minute graph** of temperature and CPU, and the **top processes** heating the machine (only read while the panel is open).
- **Adjustable thresholds** and notifications (see [Settings](#settings-your-limits)), with a cool-down margin so alerts do not flap at the edge of a limit.
- **Launch at login**, and **private by design**: no network requests, no analytics.

## Screenshot

<p align="center"><img src="docs/screenshot-panel.png" alt="Brasa panel: 56 °C chip temperature, 10-minute graph, battery, memory and SSD cards, top processes" width="330"></p>

## Install

Brasa is built from source for now (a notarized download is on the [roadmap](#roadmap)). You only need the Xcode Command Line Tools.

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

**Which Macs work?** Apple Silicon (M1 to M4) on macOS 14+. It is developed on a MacBook Pro with M4 Pro; sensor names can differ between
chips, so please [open an issue](https://github.com/renatoalves-me/brasa/issues) with your model if a value looks wrong.

**Can it control my fans?** No. It is a monitor, not a fan controller.

**Does it send data anywhere?** No. The app makes no network requests and has no analytics.

**Why does my Mac get hot?** Sustained CPU/GPU load (renders, builds, local models), a closed lid on a dock, charging while under load, or a blocked vent.
Brasa shows which processes use the most CPU so you can act.

## Alternatives

Other good tools exist, and they solve different problems: [Stats](https://github.com/exelban/Stats) (open-source system monitor), iStat Menus (paid, full hardware dashboard),
Macs Fan Control and TG Pro (fan control). Brasa focuses on **safety status and advice with your own thresholds**, and stays light.

## Roadmap

- [ ] Notarized, signed download (GitHub Releases) and a Homebrew cask
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

<sub>Keywords: Mac temperature monitor, menu bar temperature, Apple Silicon temperature, M1 M2 M3 M4 thermal monitor, MacBook overheating, CPU temperature Mac, Mac fan speed, macOS menu bar app, Swift, SwiftUI.</sub>
