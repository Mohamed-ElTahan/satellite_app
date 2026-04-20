<p align="center">
  <img src="assets/images/satellite_banner.png" width="100%" alt="Satellite Tracker Banner">
</p>

<h1 align="center">🛰️ Satellite Tracker & Telemetry</h1>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge&logo=github" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/build-passing-brightgreen?style=for-the-badge&logo=github-actions" alt="Build Status">
  <img src="https://img.shields.io/badge/platform-ios%20|%20android%20|%20web-lightgrey?style=for-the-badge&logo=flutter" alt="Platforms">
</p>

<p align="center">
  <strong>An advanced, high-performance 3D visualization and telemetry system for real-time satellite tracking.</strong>
</p>

---

## 🚀 Overview

**Satellite** is a state-of-the-art Flutter application designed for aerospace enthusiasts and engineers alike. Utilizing a custom-built 3D engine, it provides a cinematic, real-time representation of orbital mechanics. The system calculates precise look-angles (Azimuth, Elevation, Range) to bridge the gap between orbital data and terrestrial observation.

> [!IMPORTANT]
> This project leverages **CustomPainter** for high-precision 3D rendering, ensuring smooth 60 FPS performance even on mid-range mobile devices without the overhead of heavy 3D engines.

---

## ✨ Features

- **🌍 Realistic Earth Rendering**: High-fidelity visualization featuring procedural oceans, continents, and a dynamic atmospheric glow.
- **🌃 Night-Side City Lights**: Real-time terminator line simulation with glowing urban centers on the dark side of the planet.
- **🛰️ 3D Satellite Modeling**: Procedurally generated 3D satellite models with nadir-pointing orientation logic.
- **🎥 Dynamic Camera Focus**: Toggleable tracking mode that locks onto the satellite for a cinematic "drone-eye" view of the Earth's surface.
- **📊 Real-Time Telemetry**: Instant calculation of Azimuth, Elevation, and Range Km based on observer coordinates.

---

## 🛠️ Built With

<p align="center">
  <a href="https://flutter.dev"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" alt="flutter" width="40" height="40"/></a>
  <a href="https://dart.dev"><img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" alt="dart" width="40" height="40"/></a>
  <a href="https://bloclibrary.dev"><img src="https://raw.githubusercontent.com/felangel/bloc/master/docs/assets/bloc_logo_full.png" alt="bloc" height="40"/></a>
</p>

| Technology           | Implementation                          |
| :------------------- | :-------------------------------------- |
| **Frontend**         | Flutter (Dart)                          |
| **State Management** | BLoC / Cubit                            |
| **Math Engine**      | Vector Math & Custom Spherical Geometry |
| **UI Components**    | Glassmorphism & Custom Look-and-Feel    |

---

## 🏗️ Architecture

The project follows a **Feature-First Clean Architecture** approach to ensure maximum scalability and testability.

```text
lib/
├── core/
│   ├── math/            # Look-angle & Coordinate conversion logic
│   ├── models/          # Shared ECEF and Latitude/Longitude models
│   └── utils/           # Theme tokens and global constants
└── features/
    ├── calculator/      # Telemetry logic and Input panels
    │   ├── logic/       # Calculator Cubit & States
    │   └── view/        # UI widgets for data entry
    └── visualization_3d/ # Core 3D engine and Rendering
        ├── logic/       # Camera and Render states
        └── view/        # Custom Painters for Earth & Satellite
```

---

## 💻 Installation & Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/Mohamed-ElTahan/satellite.git
   cd satellite
   ```

2. **Fetch dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

---

## 👥 Team / Contributors

<table align="center">
  <tr>
    <td align="center">
      <a href="https://github.com/Mohamed-ElTahan">
        <img src="https://github.com/Mohamed-ElTahan.png" width="100px;" alt="Mohamed ElTahan"/><br />
        <sub><b>Mohamed ElTahan</b></sub>
      </a><br />
      🚀 Lead Architect
    </td>
    <td align="center">
      <a href="#">
        <img src="https://ui-avatars.com/api/?name=Team+Member&background=0D8ABC&color=fff" width="100px;" alt="Team Member"/><br />
        <sub><b>Team Member</b></sub>
      </a><br />
      🛰️ Hardware Lead
    </td>
  </tr>
</table>

<p align="center">
  Designed with ❤️ for Advanced Satellite Tracking
</p>
