# PigeonHole (GameCheat)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![GitHub stars](https://img.shields.io/github/stars/eliseorobles/PigeonHole?style=social)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-6.0-orange)

Open-source iOS game-solving toolkit built with SwiftUI, featuring algorithmic assistants for **Word Hunt**, **Anagrams**, **Four in a Row (Connect Four)**, **Mancala**, **Sea Battle (Battleship)**, and **Chess (Stockfish)**.

If this project is useful, star the repo to help more developers discover it.

## What This Project Is

PigeonHole is a mobile strategy assistant that helps analyze game states and suggest strong moves.  
The Xcode target/app name is currently `GameCheat`, while this repository is published as `PigeonHole`.

This repository is useful if you are looking for:
- iOS game AI examples in Swift
- Stockfish integration in a SwiftUI app
- minimax strategy implementations
- trie/DFS word search solvers
- Battleship-style probability heatmaps

## Supported Game Modes

| Game | What it Solves | Core Approach |
| --- | --- | --- |
| Word Hunt | Finds valid words and board paths on a 4x4 grid | Trie + DFS over adjacent cells |
| Anagrams | Finds valid words from scrambled letters | Trie + letter-frequency DFS |
| Four in a Row | Recommends strongest next column | Minimax search |
| Mancala | Recommends strongest next pit | Minimax search |
| Sea Battle | Suggests best shot coordinate | Probability grid + hunt/target mode |
| Chess | Suggests best legal move | Stockfish bridge + fallback evaluator |

## Why Developers Star This Project

- Real SwiftUI + algorithm code, not toy pseudocode
- Multiple classic game solvers in one iOS codebase
- Native Stockfish integration path for on-device chess analysis
- Test-backed core logic for easier contribution and extension

## Architecture Highlights

- `GameCheat/Core/WordEngine`: Trie and dictionary loading for word games
- `GameCheat/Core/MinimaxEngine`: shared minimax contracts used by board games
- `GameCheat/Core/BattleshipEngine`: Sea Battle probability calculator and targeting heuristics
- `GameCheat/Games/Chess/Stockfish`: native bridge layer to embedded Stockfish source
- `GameCheatTests`: unit tests covering solver behavior and game logic

## Quick Start (iOS)

### Prerequisites

- Xcode 16+
- iOS 17+ SDK
- XcodeGen

### Build

```bash
git clone https://github.com/eliseorobles/PigeonHole.git
cd PigeonHole
xcodegen generate
open GameCheat.xcodeproj
```

### Test

```bash
xcodebuild -project GameCheat.xcodeproj -scheme GameCheat -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Repository Structure

```text
GameCheat/                  # App source (SwiftUI + engines)
GameCheatTests/             # Unit tests
ThirdParty/Stockfish/       # Embedded Stockfish source (GPLv3)
GameCheat.xcodeproj/        # Generated Xcode project
project.yml                 # XcodeGen project spec (source of truth)
```

## Open Source License

This repository uses **GNU General Public License v3.0 (GPL-3.0)**.  
See `LICENSE` for full terms.

Stockfish is included under GPLv3 and remains GPLv3 in this project.  
See `ThirdParty/Stockfish/Copying.txt` and `TERMS.md` for redistribution obligations.

## Terms of Use

See `TERMS.md`.

## Contributing

Issues and pull requests are welcome. By contributing, you agree that your contributions are licensed under GPLv3.

## SEO Keywords

iOS game solver, SwiftUI game assistant, Stockfish iOS integration, chess engine Swift, word hunt solver Swift, anagram solver iOS, connect four minimax Swift, mancala AI, battleship probability calculator, open source game AI.
