# KasaSwift

A native Swift client for controlling TP-Link Kasa smart plugs, switches, and devices via the TP-Link Cloud API.

Built for the open-source smart home community by **ShortBridge** ([shortbridge.app](https://shortbridge.app)).

## Features

- ⚡️ Modern Swift Concurrency (`async`/`await`, `Sendable`).
- 🔒 No external dependencies (uses native `Foundation` and `URLSession`).
- 📱 Compatible with iOS 16+, macOS 13+, watchOS 9+, tvOS 16+.
- 🧩 Easy integration via Swift Package Manager.

## Installation

Add `KasaSwift` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/shortbridgeapp/kasa-swift.git", from: "1.0.0")
]
```

## Quick Start

```swift
import KasaSwift

let client = KasaClient()

// 1. Authenticate
let token = try await client.login(email: "user@example.com", password: "password123")

// 2. Discover Devices
let devices = try await client.getDevices(token: token)
for device in devices {
    print("Found \(device.displayName) (\(device.deviceId))")
}

// 3. Control Relay (Turn On/Off)
if let plug = devices.first {
    try await client.setDeviceRelayState(deviceId: plug.deviceId, isOn: true, token: token)
    print("Turned on \(plug.displayName)")
}
```

## Acknowledgements & Licensing

This project is open-sourced under the **GNU General Public License v3.0 (GPL-3.0)** in honor of the pioneering reverse-engineering research and protocol documentation created by the Home Assistant community (`python-kasa`) and Homebridge (`tplink-smarthome-api`).

TP-Link and Kasa are registered trademarks of TP-Link Corporation Limited. This project is independent and not affiliated with or endorsed by TP-Link.
