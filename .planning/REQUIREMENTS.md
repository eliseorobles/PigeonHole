# Requirements: GamePigeon Helper

**Defined:** 2026-02-07
**Core Value:** Instantly find every valid word in Word Hunt's 4x4 grid, sorted by length for maximum points

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Word Engine

- [ ] **WORD-01**: Trie-based dictionary engine loads ~270K words from bundled word list
- [ ] **WORD-02**: Dictionary loads asynchronously without blocking app launch

### Word Hunt

- [ ] **HUNT-01**: User can enter 16 letters in a 4x4 grid
- [ ] **HUNT-02**: Solver finds all valid words via DFS with adjacency constraints
- [ ] **HUNT-03**: Results sorted by word length (longest first)
- [ ] **HUNT-04**: Each result shows the swipe path on the grid
- [ ] **HUNT-05**: User can filter results by minimum word length

### Anagrams

- [ ] **ANAG-01**: User can enter a set of letters
- [ ] **ANAG-02**: Solver finds all valid words from those letters (no adjacency constraint)
- [ ] **ANAG-03**: Results sorted by word length
- [ ] **ANAG-04**: User can filter results by minimum word length

### Chess

- [ ] **CHES-01**: User can set up board position via tap-based board UI
- [ ] **CHES-02**: Stockfish engine analyzes position and returns best move
- [ ] **CHES-03**: User can adjust Stockfish skill level (0-20)
- [ ] **CHES-04**: Best move highlighted on the board

### Four in a Row

- [ ] **FOUR-01**: User can input current board state (drop pieces by column)
- [ ] **FOUR-02**: Minimax engine recommends optimal move
- [ ] **FOUR-03**: Recommended move highlighted on the board

### Mancala

- [ ] **MANC-01**: User can input current pit/store state
- [ ] **MANC-02**: Minimax engine recommends optimal pit to play
- [ ] **MANC-03**: Recommended move highlighted on the board

### Sea Battle

- [ ] **SEAB-01**: User can tap 10x10 grid to mark hits, misses, and sunk ships
- [ ] **SEAB-02**: Probability engine calculates density heatmap for remaining ships
- [ ] **SEAB-03**: Heatmap displayed as color overlay (red=high, blue=low)
- [ ] **SEAB-04**: Hunt/target mode switches automatically based on game state

### App Shell

- [ ] **SHELL-01**: Game picker home screen with all supported games
- [ ] **SHELL-02**: NavigationStack-based navigation to each game
- [ ] **SHELL-03**: Reset/new game functionality per game
- [ ] **SHELL-04**: Fully offline — all engines and data bundled

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Word Bites

- **BITE-01**: User can input letter fragments and find all valid words

### Additional Board Games

- **CHCK-01**: Checkers with minimax solver and board UI
- **GOMK-01**: Gomoku with minimax solver and board UI

### Polish

- **POLSH-01**: Dark mode support
- **POLSH-02**: Haptic feedback on interactions
- **POLSH-03**: Word definitions on tap
- **POLSH-04**: Favorites / solve history

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| OCR / screenshot recognition | Massive complexity, unreliable results; manual entry only for v1 |
| iMessage extension | Sandboxing constraints, fragile integration with GamePigeon |
| Accounts / sign-in | Zero value for a fully local tool |
| Ads (interstitial/video) | Interrupts solve flow mid-conversation; one-time paid or free |
| Cloud sync | No user data worth syncing; everything local |
| Gamification (streaks, badges) | This is a utility, not a game |
| Difficulty slider for non-Chess | Minimax plays optimally; artificial weakening is hard to tune well |
| Move explanations | High complexity, low urgency; defer to v2+ |
| AI chatbot / natural language input | Purpose-built UIs are faster than NL parsing |
| Widget / Live Activity | Solver results are ephemeral, no home screen value |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WORD-01 | Phase 1 | Pending |
| WORD-02 | Phase 1 | Pending |
| HUNT-01 | Phase 1 | Pending |
| HUNT-02 | Phase 1 | Pending |
| HUNT-03 | Phase 1 | Pending |
| HUNT-04 | Phase 1 | Pending |
| HUNT-05 | Phase 1 | Pending |
| ANAG-01 | Phase 2 | Pending |
| ANAG-02 | Phase 2 | Pending |
| ANAG-03 | Phase 2 | Pending |
| ANAG-04 | Phase 2 | Pending |
| CHES-01 | Phase 5 | Pending |
| CHES-02 | Phase 5 | Pending |
| CHES-03 | Phase 5 | Pending |
| CHES-04 | Phase 5 | Pending |
| FOUR-01 | Phase 3 | Pending |
| FOUR-02 | Phase 3 | Pending |
| FOUR-03 | Phase 3 | Pending |
| MANC-01 | Phase 4 | Pending |
| MANC-02 | Phase 4 | Pending |
| MANC-03 | Phase 4 | Pending |
| SEAB-01 | Phase 6 | Pending |
| SEAB-02 | Phase 6 | Pending |
| SEAB-03 | Phase 6 | Pending |
| SEAB-04 | Phase 6 | Pending |
| SHELL-01 | Phase 1 | Pending |
| SHELL-02 | Phase 1 | Pending |
| SHELL-03 | Phase 1 | Pending |
| SHELL-04 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

---
*Requirements defined: 2026-02-07*
*Last updated: 2026-02-07 after roadmap creation*
