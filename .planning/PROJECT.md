# GamePigeon Helper

## What This Is

A native iOS app (SwiftUI) that solves GamePigeon games. Users manually input game state (letters, board positions, hits/misses), and the app computes optimal moves using specialized engines — a trie-based word solver for word games, Stockfish for chess, minimax for board games, and a probability heatmap for Sea Battle. Targeting App Store distribution.

## Core Value

Instantly find every valid word in Word Hunt's 4x4 grid, sorted by length for maximum points — this is the game everyone plays and where the app delivers the most obvious value.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Trie-based dictionary engine shared across word games (Word Hunt, Anagrams, Word Bites)
- [ ] Word Hunt: 4x4 letter grid input → all valid words with swipe paths, sorted by length
- [ ] Anagrams: letter input → all valid words from those letters
- [ ] Word Bites: letter fragment input → all valid words
- [ ] Chess: Stockfish engine with adjustable skill level (0-20) and tap-based board UI
- [ ] Checkers: minimax + alpha-beta pruning with board UI
- [ ] Four in a Row: minimax solver with board UI
- [ ] Gomoku: minimax with evaluation function and board UI
- [ ] Mancala: minimax solver with board UI
- [ ] Sea Battle: probability density heatmap with hunt/target modes, tap grid for hits/misses
- [ ] Game picker home screen to select which game to play
- [ ] Standard English dictionary (~270K words) bundled in app

### Out of Scope

- OCR / screenshot recognition — manual entry only for v1
- Difficulty slider for non-Chess games — Chess only via Stockfish skill levels
- Reversi — cut to keep scope manageable, easy to add later with minimax engine
- Real-time GamePigeon integration — standalone app, no iMessage extension
- Online/multiplayer features — this is a single-player tool

## Context

GamePigeon is an iMessage game suite. Players take turns in iMessage threads. The app runs separately — user sees the game in iMessage, switches to this app to get the optimal move, then switches back to play it.

Three distinct engine types cover all games:
1. **Word engine** (Trie + DFS): Word Hunt, Anagrams, Word Bites — 90% code reuse across these
2. **Game tree search** (Minimax + alpha-beta): Checkers, Four in a Row, Gomoku, Mancala — generic engine with pluggable board state, move generation, and evaluation
3. **Probability engine**: Sea Battle only — density heatmap with hunt/target mode switching
4. **External engine**: Chess uses Stockfish compiled for iOS via existing Swift wrappers

The word engine is the highest-value, lowest-effort feature. Board games share a generic minimax core. Sea Battle is standalone.

## Constraints

- **Platform**: iOS, SwiftUI, minimum deployment target iOS 17
- **Language**: Swift
- **Chess engine**: Stockfish via existing iOS-compatible Swift wrapper
- **Dictionary**: Standard public English word list (TWL06 or similar), bundled in app bundle
- **Distribution**: App Store — must comply with App Store Review Guidelines
- **Input**: All manual entry (typing letters, tapping board positions, tapping grid cells)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftUI over UIKit | Faster UI development, modern framework | — Pending |
| Manual input only | Keeps v1 simple, avoids Vision framework complexity | — Pending |
| Standard dictionary over GamePigeon-specific | Public word list is good enough, no reverse engineering needed | — Pending |
| Stockfish for Chess | Battle-tested engine with existing iOS wrappers, adjustable difficulty | — Pending |
| Generic minimax for board games | One engine serves Checkers, Four in a Row, Gomoku, Mancala | — Pending |
| Chess-only difficulty slider | Stockfish has built-in skill levels; other games just play optimally | — Pending |

---
*Last updated: 2026-02-07 after initialization*
