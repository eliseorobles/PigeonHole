# Feature Landscape

**Domain:** Game solver / helper app for iMessage GamePigeon games (iOS)
**Researched:** 2026-02-07
**Confidence:** MEDIUM (based on training data knowledge of WordFinder, Lichess, Chess.com analysis, board game solver apps; web search unavailable for 2026-specific verification)

## Table Stakes

Features users expect. Missing = product feels incomplete or unusable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Accurate solver output | The entire value prop. Wrong answers = uninstall. | High | Dictionary coverage, correct path-tracing for Word Hunt, valid move generation for board games |
| Fast solve times (<1s for word games, <3s for board games) | Users are mid-conversation in iMessage. Waiting kills flow. | Medium | Trie + DFS is inherently fast for words. Minimax needs alpha-beta + depth limits. Stockfish is already optimized. |
| Clear results display | Users need to quickly identify the best move. Wall of text = useless. | Medium | Word games: sorted by points/length with swipe paths. Board games: highlighted move on the board. |
| Intuitive game state input | Manual entry must be fast. Clunky input = friction every single use. | High | This is the make-or-break UX. Letter grids, board taps, piece placement must feel native and fast. |
| Game selection home screen | Users play different GamePigeon games. Need quick navigation. | Low | Simple grid/list of supported games with icons. |
| Swipe path visualization (Word Hunt) | Word Hunt's core mechanic is swiping connected letters. Users need to see the path to replicate it. | Medium | Draw the path on the 4x4 grid so users can trace it in iMessage. |
| Board state visualization (board games) | Users need to see the suggested move in context of the current board. | Medium | Highlight the recommended move/piece on a rendered board. |
| Offline functionality | Users may be in areas with poor connectivity. All solve engines must work locally. | Low | Already the plan -- all engines bundled. No network dependency. |
| Reset / new game | Users play multiple rounds. Need to clear state quickly. | Low | Clear button per game, or auto-clear on re-entry. |

## Differentiators

Features that set the product apart. Not expected, but valued. These create competitive advantage over generic word solvers or standalone chess apps.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| All GamePigeon games in one app | Competitors are single-game solvers (word solver OR chess app, never both). One app for the whole GamePigeon suite is unique. | High (breadth) | This IS the core differentiator. No one else covers Word Hunt + Chess + Checkers + Sea Battle in one place. |
| Word Hunt path overlay on grid | Most word solvers just list words. Showing the exact swipe path on a visual grid is a killer feature for Word Hunt specifically. | Medium | Animated or step-numbered path on the 4x4 grid. Users trace it finger-for-finger. |
| Sea Battle probability heatmap | Visual heat overlay showing where ships most likely are. Transforms Sea Battle from random guessing to informed strategy. | Medium | Color-coded grid (red = high probability, blue = low). Updates after each hit/miss. |
| Hunt/target mode indicator (Sea Battle) | Shows users when to switch from hunting (spread shots) to targeting (focus on hits). Makes strategy explicit. | Low | Simple mode label + explanation of current strategy. |
| Adjustable chess difficulty | Stockfish skill 0-20 lets users choose how much help they want. Play at opponent's level rather than always crushing. | Low | Stockfish already supports this natively. Just expose the slider. |
| Word length filtering | Filter Word Hunt / Anagrams results by word length. Users in GamePigeon score more for longer words, so they want to see 7+ letter words first. | Low | Simple filter/sort toggle. Already implied by "sorted by length." |
| Move explanation for board games | Show WHY a move is recommended, not just WHAT. "This blocks opponent's winning line" or "Forces a double jump." | High | Requires move evaluation annotation. Hard to do well for minimax. Consider deferring. |
| Favorites / history | Remember recent solves so users can reference them if they switch back to iMessage and forget. | Medium | Local persistence of last N solves per game. |
| Haptic feedback on interactions | Board taps, letter entry, solve completion -- subtle haptics make the app feel polished and native iOS. | Low | UIFeedbackGenerator. Small effort, high perceived quality. |
| Dark mode support | Many users use dark mode. A solver app that blinds them mid-game feels cheap. | Low | SwiftUI supports this natively with proper color tokens. |
| Word definitions on tap | Tap a found word to see its definition. Helps users learn and also verify the word is real. | Medium | Requires bundling a definition source or using DictionaryKit / system dictionary API. |

## Anti-Features

Features to explicitly NOT build. These are tempting but counterproductive.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| OCR / screenshot recognition | Massive complexity (Vision framework, training data for GamePigeon's specific UI, handling rotations/crops/varied devices). Unreliable results undermine trust. Not worth it for v1. | Manual input with excellent UX. Make manual entry so fast that OCR feels unnecessary. |
| iMessage extension / real-time integration | Requires App Extension architecture, sandboxing constraints, iMessage app review hurdles. GamePigeon itself may block or conflict. Fragile. | Standalone app. Users alt-tab. Keep it simple. |
| Online multiplayer / social features | Completely orthogonal to the value prop. Users want to cheat at their existing iMessage games, not find new opponents. | No social features. Single-player tool only. |
| Accounts / sign-in | Zero reason to require authentication. Adds friction, privacy concerns, and server costs for no user benefit. | All local. No accounts. No server. |
| Ads (interstitial/video) | Solver apps are used mid-conversation. An interstitial ad between entering letters and seeing results would be rage-inducing. | If monetizing, use a one-time paid app or tip jar. Never interrupt the solve flow. |
| AI chatbot / natural language input | "Find words in these letters: A B C D..." is slower and less reliable than a purpose-built grid UI. LLM integration is complexity for negative value here. | Purpose-built input UIs per game type. |
| Difficulty slider for non-chess games | Minimax for Checkers/Connect4/Gomoku/Mancala plays optimally or it plays worse -- there is no natural "play at level 5." Artificial weakening feels wrong and is hard to tune. | Minimax games always suggest the optimal move. Chess uses Stockfish's built-in skill levels. |
| Game tutorials / how-to-play guides | Users already know how to play -- they are mid-game in iMessage. Teaching them the rules wastes screen real estate. | Brief one-line instruction per game screen at most (e.g., "Enter the 4x4 grid letters"). |
| Gamification (streaks, badges, XP) | This is a utility, not a game. Gamifying a cheat tool is absurd. | Clean, functional UI. Get in, get answer, get out. |
| Cloud sync | No user data worth syncing. No accounts. Adds server infrastructure for zero value. | Everything local. |
| Widget / Live Activity | Solver results are contextual and ephemeral. A widget showing "your last Word Hunt results" has no value on the home screen. | Just the app. Launch it when you need it. |

## Feature Dependencies

```
Dictionary Engine ──→ Word Hunt Solver
                  ──→ Anagrams Solver
                  ──→ Word Bites Solver

Minimax Engine ──→ Checkers
               ──→ Four in a Row
               ──→ Gomoku
               ──→ Mancala

Board UI Components ──→ All board game UIs (shared grid/board rendering)
                    ──→ Sea Battle heatmap grid
                    ──→ Chess board

Stockfish Integration ──→ Chess Solver

Letter Grid Input ──→ Word Hunt (4x4 grid)
                  ──→ Word Bites (fragment grid)

Probability Engine ──→ Sea Battle Heatmap

Game Picker Home ──→ All games (navigation hub)

Results Display ──→ Word list view (word games)
               ──→ Board move overlay (board games)
               ──→ Heatmap overlay (Sea Battle)
```

### Critical Path

```
1. Dictionary Engine (blocks all 3 word games)
2. Letter Grid Input + Word Hunt Solver (highest-value feature, validates core UX)
3. Minimax Engine (blocks all 4 board games)
4. Board UI Components (shared across board games + Sea Battle)
5. Stockfish Integration (independent, can parallel with minimax work)
6. Probability Engine (independent, Sea Battle only)
```

## MVP Recommendation

### Phase 1: Word Games (highest value, lowest effort)

Prioritize:
1. **Dictionary/Trie engine** -- foundation for all word games, 90% code reuse
2. **Word Hunt solver with path visualization** -- the killer feature, the reason people download this app
3. **Anagrams solver** -- trivial once the trie exists, different DFS traversal
4. **Word Bites solver** -- fragment matching on the same trie
5. **Game picker home screen** -- simple navigation, but needed from day one

### Phase 2: Board Games (shared engine, multiple games)

6. **Generic minimax + alpha-beta engine** -- one engine, four games
7. **Checkers** -- most popular GamePigeon board game after chess
8. **Four in a Row** -- simple board state, good second minimax game
9. **Gomoku** -- similar to Four in a Row but larger board
10. **Mancala** -- different board shape, tests engine flexibility

### Phase 3: Specialized Engines

11. **Stockfish/Chess integration** -- external engine, separate integration effort
12. **Sea Battle probability heatmap** -- standalone probability engine, unique UI

### Defer to Post-Launch

- **Move explanations** for board games: High complexity, low urgency
- **Word definitions on tap**: Nice-to-have, not core
- **Favorites / history**: Can add after validating core usage patterns
- **Dark mode**: Should be built from day one with proper color tokens, but polish can come later

### Do Not Build

- OCR, iMessage extension, accounts, ads, AI chat, cloud sync, gamification, widgets

## Competitive Landscape Notes

### Word Game Solvers (WordFinder, WordSolver, Unscrambler apps)
- **What they do well:** Large dictionaries, fast results, word length sorting
- **What they lack:** No path visualization for grid games like Word Hunt. They solve generic anagram/Scrabble problems, not GamePigeon-specific grid traversals.
- **Our advantage:** Path overlay on the 4x4 grid is the killer feature they do not have.

### Chess Analysis Apps (Lichess, Chess.com, dedicated Stockfish apps)
- **What they do well:** Deep analysis, multiple lines, opening books, endgame tables
- **What they lack:** Overkill for "tell me the best move in this casual iMessage game." Too complex for the use case.
- **Our advantage:** Simplified interface. Enter board state, get one move. Adjustable difficulty so you do not suspiciously crush your friend every time.

### Board Game Solvers (Connect4 solvers, Checkers apps)
- **What they do well:** Optimal play, sometimes with difficulty levels
- **What they lack:** Each is a separate app. Nobody bundles them.
- **Our advantage:** All GamePigeon board games in one app with a unified UI language.

### GamePigeon-Specific Helpers
- **What exists:** A few Word Hunt solvers exist on the App Store and as web tools. None cover the full GamePigeon suite.
- **Our advantage:** Comprehensive coverage. One app replaces 5+ separate tools.

## Sources

- Training data knowledge of WordFinder, Lichess, Chess.com analysis features, App Store game solver landscape (confidence: MEDIUM -- unable to verify with live web search)
- Project context from PROJECT.md (confidence: HIGH -- primary source)
- Domain knowledge of trie/DFS word solving, minimax game trees, Stockfish engine capabilities (confidence: HIGH -- well-established CS fundamentals)
