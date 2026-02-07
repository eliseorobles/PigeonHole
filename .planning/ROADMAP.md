# Roadmap: GamePigeon Helper

## Overview

This roadmap delivers a native iOS app that solves GamePigeon games, starting with the highest-value feature (Word Hunt with trie-based word finding) and expanding outward through word games, board games, chess, and Sea Battle. Each phase delivers a complete, playable game solver -- never a partial feature. The app shell and navigation are built alongside the first game so every phase produces a testable, end-to-end vertical slice.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Word Hunt + App Shell** - Trie engine, Word Hunt solver, and app navigation foundation
- [ ] **Phase 2: Anagrams** - Anagram solver reusing the trie engine
- [ ] **Phase 3: Four in a Row + Minimax Engine** - Generic minimax engine proven with the simplest board game
- [ ] **Phase 4: Mancala** - Mancala solver reusing the minimax engine
- [ ] **Phase 5: Chess** - Stockfish integration with board UI and adjustable difficulty
- [ ] **Phase 6: Sea Battle** - Probability heatmap engine with hunt/target strategy

## Phase Details

### Phase 1: Word Hunt + App Shell
**Goal**: Users can launch the app, pick Word Hunt from the home screen, enter a 4x4 letter grid, and see every valid word with its swipe path -- all offline
**Depends on**: Nothing (first phase)
**Requirements**: WORD-01, WORD-02, HUNT-01, HUNT-02, HUNT-03, HUNT-04, HUNT-05, SHELL-01, SHELL-02, SHELL-03, SHELL-04
**Success Criteria** (what must be TRUE):
  1. User sees a game picker home screen and can navigate to Word Hunt
  2. User can enter 16 letters into a 4x4 grid and tap Solve to see all valid words sorted by length (longest first)
  3. User can tap any result word and see its swipe path highlighted on the grid
  4. User can filter results by minimum word length
  5. User can reset the grid and start a new solve, and the entire app works offline with no network dependency
**Plans**: TBD

Plans:
- [ ] 01-01: TBD
- [ ] 01-02: TBD

### Phase 2: Anagrams
**Goal**: Users can enter a set of letters and find every valid word that can be formed from those letters
**Depends on**: Phase 1 (trie engine)
**Requirements**: ANAG-01, ANAG-02, ANAG-03, ANAG-04
**Success Criteria** (what must be TRUE):
  1. User can navigate to Anagrams from the home screen and enter a set of letters
  2. User can tap Solve and see all valid words formed from those letters, sorted by length (longest first)
  3. User can filter results by minimum word length
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Four in a Row + Minimax Engine
**Goal**: Users can input a Four in a Row board state and get the optimal column to play next, powered by a reusable minimax engine
**Depends on**: Phase 1 (app shell)
**Requirements**: FOUR-01, FOUR-02, FOUR-03
**Success Criteria** (what must be TRUE):
  1. User can navigate to Four in a Row from the home screen and input the current board state by dropping pieces into columns
  2. User can tap Solve and the app highlights the recommended column to play
  3. User can reset the board and analyze a new position
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Mancala
**Goal**: Users can input the current Mancala pit/store state and get the optimal pit to play
**Depends on**: Phase 3 (minimax engine)
**Requirements**: MANC-01, MANC-02, MANC-03
**Success Criteria** (what must be TRUE):
  1. User can navigate to Mancala from the home screen and input the current pit and store values
  2. User can tap Solve and the app highlights the recommended pit to play
  3. User can reset the board and analyze a new position
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

### Phase 5: Chess
**Goal**: Users can set up a chess position and get the best move from Stockfish at their chosen difficulty level
**Depends on**: Phase 1 (app shell)
**Requirements**: CHES-01, CHES-02, CHES-03, CHES-04
**Success Criteria** (what must be TRUE):
  1. User can navigate to Chess from the home screen and set up a board position by tapping to place and move pieces
  2. User can adjust the Stockfish skill level from 0 (weakest) to 20 (strongest)
  3. User can tap Solve and the best move is highlighted on the board
  4. User can reset the board and analyze a new position
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

### Phase 6: Sea Battle
**Goal**: Users can mark hits, misses, and sunk ships on a grid and see a probability heatmap showing where remaining ships are most likely located
**Depends on**: Phase 1 (app shell)
**Requirements**: SEAB-01, SEAB-02, SEAB-03, SEAB-04
**Success Criteria** (what must be TRUE):
  1. User can navigate to Sea Battle from the home screen and tap cells on a 10x10 grid to mark hits, misses, and sunk ships
  2. User sees a color-coded probability heatmap overlay (red = high probability, blue = low probability) updating after each input
  3. The engine automatically switches between hunt mode (spread out) and target mode (focus near hits) based on game state
  4. User can reset the grid and start a new game
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|---------------|--------|-----------|
| 1. Word Hunt + App Shell | 0/TBD | Not started | - |
| 2. Anagrams | 0/TBD | Not started | - |
| 3. Four in a Row + Minimax Engine | 0/TBD | Not started | - |
| 4. Mancala | 0/TBD | Not started | - |
| 5. Chess | 0/TBD | Not started | - |
| 6. Sea Battle | 0/TBD | Not started | - |
