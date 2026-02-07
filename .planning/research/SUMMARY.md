# Project Research Summary

**Project:** GamePigeon Helper (iOS Game Solver)
**Domain:** iOS Multi-Game Solver / Strategy Tool
**Researched:** 2026-02-07
**Confidence:** HIGH (architecture & algorithms), MEDIUM (Stockfish integration), LOW (App Store positioning)

## Executive Summary

This is a comprehensive iOS helper app for GamePigeon's iMessage games, covering three distinct engine types: word games (trie-based pathfinding), board games (minimax with alpha-beta pruning), and specialized engines (Stockfish for chess, probability heatmaps for Sea Battle). The recommended approach is a Swift/SwiftUI app targeting iOS 17+ with minimal external dependencies, using protocol-oriented design for the minimax engine and a memory-efficient binary trie for word lookups. The core architecture separates game-agnostic engines (Core/) from game-specific implementations (Games/), enabling code reuse across similar games while maintaining clean boundaries.

The most critical technical challenge is memory management for the 270K-word dictionary -- a naive object-based trie consumes 300-600MB and causes app kills on older devices. The solution is a pre-compiled binary trie format with memory mapping, reducing memory to 3-8MB. The second major risk is Stockfish integration complexity (C++ compilation, NNUE weights bundling, UCI protocol handling), which should be validated with an early spike. The third risk is App Store rejection if the app is positioned as a "cheat" tool rather than a "helper/solver/strategy guide."

Beyond technical execution, the biggest uncertainty is dictionary accuracy -- GamePigeon uses an undocumented word list, and any mismatch (suggesting words the game rejects) destroys user trust. This requires extensive real-world testing and a user feedback mechanism for word validation. Success depends on solving these three challenges early: compact trie implementation (Phase 1), Stockfish wrapper verification (Chess phase), and careful App Store positioning (before submission).

## Key Findings

### Recommended Stack

The stack is intentionally dependency-minimal. Swift 6.0 with strict concurrency checking prevents data races in background solver computations. SwiftUI with iOS 17+ provides modern state management via `@Observable` (replacing the legacy `ObservableObject` pattern) and stable navigation via `NavigationStack`. The trie, minimax engine, and probability calculators are all hand-rolled -- no third-party packages required. This eliminates supply chain risk and version compatibility issues when Xcode updates.

**Core technologies:**
- **Swift 6.0 / SwiftUI (iOS 17+)**: Native iOS with strict concurrency for thread-safe background solvers. `@Observable` macro for fine-grained reactive updates.
- **Custom Trie (binary format, mmap'd)**: Memory-efficient dictionary structure (3-8MB vs 300MB naive implementation). Supports prefix search for DFS pruning.
- **Generic Minimax + Alpha-Beta**: Protocol-oriented design (`GameState` protocol) allows one engine to power four games. Value-type state prevents mutation bugs.
- **Stockfish (compiled C++ with UCI)**: Strongest open-source chess engine. Compiled as static library, communicated via UCI text protocol. NNUE weights (~40MB) bundled in app. GPL licensing requires careful App Store positioning.
- **Probability Engine (Sea Battle)**: Constraint-based ship placement enumeration. For each remaining ship, count valid placements covering each cell. Hunt/target mode state machine.

**Critical version requirements:**
- iOS 17.0+ baseline (for `@Observable`, stable `NavigationStack`, ~95%+ device coverage)
- Swift 6.0+ (strict concurrency checking)
- Xcode 16+ (ships Swift 6, modern SwiftUI previews)

**External dependencies:**
- Stockfish C++ source (~50-100MB including NNUE weights) -- only external code
- Word list text file (TWL06/SOWPODS/NWL, ~3-5MB) -- static data
- Zero Swift packages required

### Expected Features

The research identified clear feature priorities based on competitive analysis and table stakes vs. differentiators.

**Must have (table stakes):**
- **Accurate solver output** -- wrong answers mean immediate uninstall. Requires correct pathfinding for Word Hunt, valid move generation for board games, reliable dictionary coverage.
- **Fast solve times** -- <1s for word games, <3s for board games. Users are mid-iMessage conversation; waiting kills flow.
- **Clear results display** -- word games sorted by points/length with swipe paths visualized; board games with highlighted recommended move on rendered board.
- **Intuitive game state input** -- clunky manual entry creates friction every single use. Letter grids and board taps must feel native iOS.
- **Swipe path visualization (Word Hunt)** -- users need to see the exact path on the 4x4 grid to replicate it in iMessage.
- **Offline functionality** -- all solvers work locally, no network dependency.

**Should have (competitive differentiators):**
- **All GamePigeon games in one app** -- this IS the core differentiator. Competitors are single-game solvers (word finder OR chess app, never both). Comprehensive coverage is unique.
- **Sea Battle probability heatmap** -- visual heat overlay showing where ships are most likely located. Transforms random guessing into informed strategy.
- **Adjustable chess difficulty** -- Stockfish skill 0-20 lets users choose help level. Prevents suspiciously perfect play every game.
- **Word Hunt path overlay on grid** -- most word solvers just list words. Showing the exact swipe path is a killer feature for Word Hunt specifically.
- **Haptic feedback** -- subtle haptics on taps/solves make the app feel polished and native iOS.
- **Dark mode** -- built from day one with proper color tokens.

**Defer (v2+):**
- **Move explanations for board games** -- "this blocks opponent's winning line" annotations. High complexity, low urgency.
- **Word definitions on tap** -- helps users learn but not core to solving. Requires bundling definition source or using DictionaryKit.
- **Favorites / history** -- can add after validating usage patterns.

**Explicitly avoid (anti-features):**
- **OCR / screenshot recognition** -- massive complexity (Vision framework, training data), unreliable results undermine trust. Make manual entry excellent instead.
- **iMessage extension** -- sandboxing constraints, App Store review hurdles, fragile integration. Standalone app with simple alt-tab is better.
- **Ads (especially interstitials)** -- interrupting the solve flow would be rage-inducing. If monetizing, use paid app or tip jar.
- **Accounts / sign-in** -- zero reason for authentication. All local, no server.
- **Gamification** -- this is a utility tool, not a game. No streaks/badges/XP.

### Architecture Approach

The architecture uses protocol-oriented design for shared engines, MVVM for individual games, and SwiftUI's `NavigationStack` for navigation. Each game has its own ViewModel (`@Observable` class) that owns solver state and communicates with game-agnostic engines in Core/. Engines know nothing about UI or specific games.

**Major components:**

1. **WordDictionary (singleton)** -- loads 270K-word list once at app launch (background thread), builds binary trie, exposes `isWord()` and `hasPrefix()` APIs. Shared by Word Hunt, Anagrams, Word Bites solvers.

2. **MinimaxSolver (generic)** -- implements minimax + alpha-beta pruning operating on any `GameState` protocol conformance. Checkers, Four in a Row, Gomoku, Mancala each conform to `GameState` by providing move generation, evaluation, and state transitions. Engine is written once, used four times.

3. **StockfishEngine (actor)** -- wraps Stockfish C++ via UCI protocol over pipes/in-memory buffers. Sends FEN position + skill level, receives best move in algebraic notation. Runs on background thread with actor isolation for thread safety.

4. **ProbabilityGrid (Sea Battle)** -- enumerates valid ship placements given known hits/misses/sunk ships, counting placement coverage per cell. Outputs probability heatmap. Hunt/target mode state machine determines strategy.

5. **Game ViewModels** -- one per game, owns input state (grid letters, board position), drives solver, formats results. `@Observable` for reactive SwiftUI updates. Solvers run in `Task {}` blocks (async) to keep UI responsive.

6. **Game Views (SwiftUI)** -- declarative input UIs (letter grids, board taps, heatmap overlays) and results lists. No engine knowledge. Pure view layer.

**Key patterns:**
- **Value types (structs) for GameState** -- minimax operates on immutable copies. No undo bugs, no accidental mutation. Swift's copy-on-write makes this efficient.
- **Singleton dictionary with async loading** -- trie loads once in background. UI gates word game "Solve" buttons on `dictionary.isLoaded`.
- **NavigationStack (not TabView)** -- 10 games don't fit in a tab bar. Grid/list picker at root with `NavigationLink` to each game.
- **Bundled resources** -- dictionary text and Stockfish NNUE weights included in app bundle. Access via `Bundle.main`.

**Anti-patterns to avoid:**
- God ViewModel (one class for all games) -- violates single responsibility, makes testing impossible
- Synchronous dictionary loading on main thread -- freezes app for 1-2s, may trigger iOS watchdog kill
- Minimax without alpha-beta pruning -- search is exponentially slower, unusable depth for complex games
- Mutable GameState -- undo logic is bug-prone, especially with multi-jump checkers moves

### Critical Pitfalls

The research identified 15 pitfalls across critical/moderate/minor severity. Top 5 to address early:

1. **Naive Trie Memory Explosion (CRITICAL)** -- object-based trie with 270K words consumes 300-600MB, causes app kills on older devices. Solution: pre-compile to binary format (flat arrays), memory-map at runtime. Reduces memory to 3-8MB. Must be solved in Phase 1 (Word Engine).

2. **Gomoku Minimax Explosion (CRITICAL)** -- 15x15 board has 225 legal moves per turn. Naive minimax at depth 4 evaluates 2.5 billion nodes. Solution: restrict candidate moves to cells within 2 spaces of existing stones (reduces branching to ~20-40). Move ordering and iterative deepening. Must be designed into minimax API from the start.

3. **Stockfish iOS Integration Nightmare (CRITICAL)** -- Stockfish is C++17 with SIMD, POSIX threads, 40MB NNUE weights. Compiling for iOS arm64 and linking with Swift is complex. NNUE file path resolution fails on real devices. Solution: use existing iOS Stockfish wrapper (search GitHub for `chesskit-swift`, `stockfish-ios`). Spike early before building Chess UI. If no wrapper exists, expect significant effort.

4. **App Store "Cheat" Rejection (CRITICAL)** -- Apple rejects apps framed as cheating tools (Guidelines 1.1.6, 4.0). Using "cheat" in name/description or mentioning "GamePigeon" by trademark triggers rejection. Solution: frame as "helper", "solver", "strategy guide". Never mention GamePigeon by name in listing. Screenshots show only your app, not iMessage. Decide naming/positioning before Phase 1.

5. **Dictionary Mismatch (CRITICAL)** -- GamePigeon uses undocumented word list. Solver suggests words the game rejects = broken trust. Solution: use broadly inclusive dictionary (SOWPODS/Collins), acknowledge limitation in UI, add user feedback for invalid words. Test extensively with real games (target 95%+ acceptance rate). Address in Phase 1 and monitor post-launch.

**Moderate pitfalls:**
- **Trie loading blocks app launch** -- load in background, show loading state, or use pre-compiled binary for instant load
- **Expensive minimax evaluation** -- called millions of times per move. Must take <1 microsecond. Use incremental updates, avoid allocations in hot path
- **Sea Battle probability bugs** -- forgetting to remove sunk ships, not accounting for hit constraints. Use constraint-based enumeration
- **SwiftUI grid performance** -- 225-cell Gomoku board stutters on state change. Use `.equatable()` per cell or `Canvas` rendering
- **Word Hunt invalid paths** -- DFS must enforce adjacency and no-revisit with bitmask. Return actual path, not just word

## Implications for Roadmap

Based on the research, the following phase structure minimizes risk and maximizes value delivery:

### Phase 1: Word Engine Foundation
**Rationale:** Word games are highest-value (Word Hunt is THE killer feature) and lowest-risk (pure Swift, no external dependencies). The trie is shared infrastructure for three games. Solving the memory-efficient trie problem (Pitfall 1) early unblocks all word games and validates the core UX (manual letter entry + path visualization). Word Hunt validates end-to-end flow before tackling more complex engines.

**Delivers:**
- Binary packed trie with memory mapping (3-8MB, instant load)
- WordDictionary singleton with async loading
- Trie API: `isWord()` and `hasPrefix()` for DFS pruning

**Addresses features:**
- Table stakes: accurate solver output, fast solve times, offline functionality
- Differentiator: Word Hunt path overlay on grid

**Avoids pitfalls:**
- P1: Trie memory explosion (solved with binary format)
- P6: Blocking app launch (async load)
- P10: Invalid Word Hunt paths (bitmask DFS, adjacency enforcement)
- P5: Dictionary mismatch (test with real games during this phase)

**Research flag:** Standard algorithm, skip additional research. Use NWL2023 or SOWPODS word list (verify availability).

---

### Phase 2: Word Hunt Solver + UI
**Rationale:** Word Hunt is the highest-value single feature. It proves the entire vertical stack works (dictionary → solver → ViewModel → View → path visualization). Success here validates the core value prop and UX assumptions. All other word games are variations on the same engine.

**Delivers:**
- Word Hunt DFS solver with adjacency constraints and trie prefix pruning
- 4x4 letter grid input UI (SwiftUI)
- WordHuntViewModel with background solving
- Path visualization on grid (Canvas overlay or SwiftUI drawing)
- Results list sorted by length/points

**Addresses features:**
- Table stakes: intuitive input, clear results, swipe path visualization
- Differentiator: path overlay on grid (unique to this app)

**Avoids pitfalls:**
- P10: Path validation (bitmask visited tracking, strict adjacency)
- P5: Dictionary mismatch (extensive testing against real GamePigeon games)

**Research flag:** Skip research, standard pathfinding.

---

### Phase 3: Remaining Word Games (Anagrams + Word Bites)
**Rationale:** These reuse the trie infrastructure. Anagrams is subset permutation search with trie pruning (different DFS strategy). Word Bites combines fragments and checks trie. Both are trivial given the trie is built. Can be developed in parallel or sequentially with minimal effort. Adds breadth to word game coverage.

**Delivers:**
- Anagrams solver (subset search + trie)
- Anagrams UI (letter input + results)
- Word Bites solver (fragment combination + trie)
- Word Bites UI (fragment input + results)

**Addresses features:**
- Table stakes: accurate solvers, fast results
- Breadth: comprehensive word game coverage

**Avoids pitfalls:**
- P5: Same dictionary mismatch concerns, mitigated by Phase 2 testing

**Research flag:** Skip research, standard algorithms.

---

### Phase 4: Generic Minimax Engine + Four in a Row
**Rationale:** Board games share a generic minimax engine. Building the engine with the first game (Four in a Row, simplest board) proves the protocol-oriented design works. Four in a Row has low branching factor (~7 columns) and simple evaluation, making it ideal for validating alpha-beta pruning works correctly. Success here unblocks all remaining board games.

**Delivers:**
- `GameState` protocol (move generation, evaluation, terminal check)
- `MinimaxSolver` with alpha-beta pruning
- Iterative deepening for time-bounded search
- Four in a Row game state conformance
- Four in a Row UI (column-drop input + board visualization)

**Addresses features:**
- Table stakes: accurate board game recommendations, fast computation
- Architecture: generic engine reusable across games

**Avoids pitfalls:**
- P7: Expensive evaluation (design for incremental updates from start)
- P2: Gomoku explosion (deferred to that game, but API must support candidate move restriction)
- Anti-pattern: mutable state (use value types)

**Research flag:** Skip research, textbook minimax implementation.

---

### Phase 5: Checkers + Mancala
**Rationale:** These reuse the minimax engine from Phase 4. Checkers has moderate complexity (mandatory capture, multi-jump, king promotion). Mancala has different board layout but similar branching factor. Both test engine flexibility. Can be developed in parallel since they share no code beyond the engine.

**Delivers:**
- Checkers game state (8x8 board, jump rules, king promotion)
- Checkers UI (board taps + move highlight)
- Mancala game state (pit/store layout, capture rules)
- Mancala UI (pit selection + visual move indication)

**Addresses features:**
- Breadth: comprehensive board game coverage

**Avoids pitfalls:**
- P13: Checkers rule variants (test against GamePigeon first)
- P12: Mancala rule variants (test against GamePigeon first)

**Research flag:** NEEDS RESEARCH for rule variants. Run `/gsd:research-phase` during planning to identify exact GamePigeon rules (mandatory capture, multi-jump path selection, Mancala sowing/capture rules).

---

### Phase 6: Gomoku
**Rationale:** Gomoku is the most complex minimax game due to massive branching factor (225 empty cells on 15x15 board). It MUST use candidate move reduction (only cells within 2 spaces of stones) or it's unusable. This phase validates that the minimax API supports pluggable move generation. Deferred until after simpler board games prove the engine works.

**Delivers:**
- Gomoku game state with candidate move reduction (neighbor cells only)
- Move ordering heuristic (center cells first, cells near stones)
- Gomoku UI (15x15 grid tap input + move highlight)

**Addresses features:**
- Breadth: all GamePigeon board games covered

**Avoids pitfalls:**
- P2: Minimax explosion (candidate move reduction mandatory)
- P9: SwiftUI grid performance (225 cells, use `.equatable()` or `Canvas`)

**Research flag:** Skip research, but validate candidate move reduction works in Phase 4 API design.

---

### Phase 7: Stockfish Chess Integration
**Rationale:** Chess is the highest-risk feature due to external C++ dependency. Stockfish integration requires compiling C++17 for iOS, bundling 40MB NNUE weights, implementing UCI protocol correctly, and handling threading/licensing issues. This phase should START with a spike to validate a working Stockfish iOS wrapper exists. If no wrapper exists, effort balloons. Deferred until word and board games are proven to de-risk the project.

**Delivers:**
- Stockfish C++ compiled as static library for iOS arm64
- StockfishEngine actor with UCI protocol (send FEN, receive best move)
- Skill level control (UCI option, 0-20)
- Chess board UI (piece placement + FEN generation)
- ChessViewModel with async Stockfish calls

**Addresses features:**
- Breadth: chess coverage (high-value, popular game)
- Differentiator: adjustable difficulty (play at opponent's level)

**Avoids pitfalls:**
- P3: Stockfish build nightmare (use existing wrapper, spike early)
- P11: UCI protocol mishandling (follow sequence: uci → isready → position → go → bestmove)
- P14: App binary size (NNUE weights are 40MB, consider ODR or small net)

**Research flag:** NEEDS RESEARCH NOW (before Phase 7 planning). Validate Stockfish iOS wrapper availability (search GitHub for `chesskit-swift`, `stockfish-ios`, `ChessKitEngine`). If none exist or are unmaintained, flag as high-risk phase requiring significant effort.

---

### Phase 8: Sea Battle Probability Heatmap
**Rationale:** Sea Battle is independent of other engines. It uses a standalone probability calculator (constraint-based ship placement enumeration). It can be developed anytime after Phase 1 (app shell + navigation). Deferred to late phase because it's lower priority than word/board games, but it's a strong differentiator (visual heatmap is unique).

**Delivers:**
- ProbabilityGrid engine (enumerate valid ship placements, count per cell)
- HuntTargetStrategy state machine (hunt mode vs target mode)
- Sea Battle UI (10x10 tap grid for hit/miss/sunk input + heatmap overlay)
- Heatmap visualization (color gradient, blue=low → red=high)

**Addresses features:**
- Differentiator: probability heatmap (transforms Sea Battle from random to strategic)
- Breadth: final GamePigeon game covered

**Avoids pitfalls:**
- P8: Probability bugs (constraint-based enumeration, remove sunk ships, handle hit adjacency)

**Research flag:** Skip research, well-studied Battleship probability algorithms.

---

### Phase 9: Polish + App Store Prep
**Rationale:** All features built. This phase focuses on app-wide polish (haptics, dark mode, loading states, error handling), performance tuning (profile on oldest supported device), and App Store preparation (screenshots, listing copy, trademark-safe positioning).

**Delivers:**
- Haptic feedback on all interactions
- Dark mode color tokens verified
- Loading states for all async operations
- Performance testing on iPhone SE 3rd gen (or oldest iOS 17 device)
- App Store listing with safe positioning (no "cheat", no "GamePigeon")
- Screenshots showing only app UI (not iMessage)

**Avoids pitfalls:**
- P4: App Store rejection (careful naming, framing as "helper/solver/strategy")
- P15: Older device issues (test memory/CPU on low-end hardware)
- P14: Binary size (verify IPA under 100MB, consider ODR for Stockfish)

**Research flag:** NEEDS RESEARCH for App Store Guidelines 2026 interpretation. Verify current stance on game helper apps, trademark usage, "cheat" framing. Review recent rejections in community forums.

---

### Phase Ordering Rationale

1. **Word games first (Phases 1-3)** because they are highest-value (Word Hunt is the killer feature), lowest-risk (pure Swift, no external dependencies), and fastest to deliver. Success here validates the entire app concept and UX assumptions.

2. **Board games second (Phases 4-6)** because they share a generic engine (build once, use four times). Four in a Row first to prove the engine, then Checkers/Mancala in parallel, then Gomoku last (most complex). This grouping maximizes code reuse.

3. **Chess deferred (Phase 7)** because Stockfish integration is the highest-risk feature. External C++ dependency, build system complexity, 40MB binary size, GPL licensing concerns. De-risk by proving value with word/board games first. Spike Stockfish wrapper availability EARLY during roadmap planning.

4. **Sea Battle late (Phase 8)** because it's independent (no shared engine) and lower priority than word/board/chess. It's a differentiator but not table stakes. Can be moved earlier if bandwidth allows.

5. **Polish last (Phase 9)** because it requires all features present to test holistically. App Store preparation must happen after all functionality is complete.

**Dependencies:**
- Phases 2-3 depend on Phase 1 (trie)
- Phases 5-6 depend on Phase 4 (minimax engine)
- Phase 7 is independent (can parallel with Phases 5-6 if desired, but riskier)
- Phase 8 is independent (can parallel with any phase after 1)

### Research Flags

**Needs deeper research during planning:**
- **Phase 5 (Checkers/Mancala):** Rule variants. GamePigeon's exact rules are undocumented. Must identify mandatory capture rules, multi-jump path selection, Mancala sowing/capture/extra-turn rules. Use `/gsd:research-phase` to investigate via gameplay testing or community knowledge.
- **Phase 7 (Chess):** Stockfish wrapper availability. Search GitHub/SPM for `chesskit-swift`, `stockfish-ios`, `ChessKitEngine`. Verify wrapper is maintained, supports iOS 17+, includes NNUE. If no wrapper exists, this phase becomes HIGH RISK.
- **Phase 9 (App Store Prep):** Current App Store guidelines on game helper apps. Verify 2026 interpretation of "cheat" framing, trademark usage for competitor app names, minimum functionality requirements. Review recent rejections/approvals in iOS dev communities.

**Standard patterns (skip research-phase):**
- **Phases 1-3 (Word Engine):** Trie data structure and DFS pathfinding are textbook algorithms with abundant resources. No domain-specific uncertainty.
- **Phases 4-6 (Minimax):** Alpha-beta pruning is well-documented. Game-specific evaluation functions are straightforward heuristics (piece count, positional advantage).
- **Phase 8 (Sea Battle):** Battleship probability algorithms are well-studied in combinatorial game theory. Constraint-based enumeration is the standard approach.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core technologies (Swift, SwiftUI, trie, minimax) are well-established. Algorithms are textbook. Only uncertainty is Stockfish wrapper availability (MEDIUM confidence). |
| Features | HIGH | Table stakes are clear from competitive analysis (word solvers, chess apps, board game solvers). Differentiators are validated by gaps in existing tools. GamePigeon's popularity is well-known. |
| Architecture | HIGH | MVVM + protocol-oriented design are standard iOS patterns. SwiftUI NavigationStack is well-documented. Component boundaries are clear. The generic minimax design is textbook. |
| Pitfalls | HIGH (algorithms), MEDIUM (Stockfish), LOW (App Store) | Memory management, minimax scaling, and UCI protocol issues are well-documented. Stockfish iOS integration challenges are known in chess programming communities but specific 2026 wrapper status is uncertain. App Store review process is opaque and subjective. |

**Overall confidence:** MEDIUM-HIGH

The core technical execution (trie, minimax, word solvers, architecture) is HIGH confidence -- these are established patterns with abundant references. The two areas of MEDIUM confidence are:

1. **Stockfish integration effort** -- depends entirely on whether a maintained iOS wrapper exists. If yes, it's a few hours of integration. If no, it's days of build system work. This should be validated EARLY with a GitHub search and spike.

2. **Dictionary accuracy** -- GamePigeon's word list is undocumented. Mismatch risk is HIGH. This can only be mitigated through extensive real-world testing and user feedback mechanisms. Launch with a broadly inclusive dictionary and refine post-launch.

The LOW confidence area is:

3. **App Store positioning** -- Apple's review process is subjective. "Cheat" framing is almost certainly rejected, but the line between "helper" and "cheat" is fuzzy. Trademark usage (mentioning "GamePigeon") is legally risky. Mitigation: avoid both, but there's no guarantee. Prepare for 1-2 rejection cycles and plan accordingly.

### Gaps to Address

**Technical gaps:**
- **Stockfish wrapper availability (2026):** Research says packages like `chesskit-swift` or `stockfish-ios` likely exist but couldn't verify. Action: Search GitHub/SPM during roadmap planning. If none exist, re-estimate Chess phase effort (could increase from 1 week to 3 weeks).
- **NNUE file size and embedding:** Stockfish 16/17 NNUE weights are ~40MB. Research suggests a "small net" option exists (~5MB) but couldn't confirm. Action: Check Stockfish documentation during Chess phase planning. If no small net, accept 40MB or consider classical eval (weaker play).
- **iOS 17 device compatibility:** Research assumes iOS 17 covers ~95%+ devices in 2026. Action: Verify with Apple's device compatibility data before finalizing target.

**Domain gaps:**
- **GamePigeon rule variants:** Checkers (mandatory capture? max capture requirement?), Mancala (can you sow into opponent's store? what triggers extra turn?), exact board sizes for Gomoku. Action: Play each game extensively during Phase 5 planning to document exact rules.
- **Dictionary source:** Research mentions TWL06 (~178K), SOWPODS (~267K), NWL2023 (unknown availability). Action: Verify NWL2023 is freely available. If not, default to SOWPODS (more inclusive, fewer false negatives).

**Business gaps:**
- **App Store guidelines interpretation (2026):** Can you mention "GamePigeon" in app name/description? How strictly is "cheat" framing enforced? Are game helper apps flagged for extended review? Action: Review recent (2025-2026) game solver/helper app submissions in iOS dev forums. Consult App Store Review Guidelines 1.1.6, 3.1.2(a), 4.0.
- **GPL licensing for Stockfish in App Store:** Stockfish is GPL v3. Does bundling it in a closed-source app violate GPL? Can GPL apps be distributed via App Store? Action: Research Stockfish's license terms and App Store compatibility during Chess phase. Options: open-source the app, use process separation to avoid linking, or accept GPL for the app.

## Sources

### Primary (HIGH confidence)
- **STACK.md:** Training knowledge of Swift/SwiftUI, trie data structures, minimax algorithms, Stockfish architecture. Core technologies are well-established and unlikely to change. Version numbers (iOS 17, Swift 6, Xcode 16) should be verified but are likely correct.
- **FEATURES.md:** Training knowledge of word game solvers (WordFinder, Unscrambler), chess analysis apps (Lichess, Chess.com), board game solvers. Competitive landscape analysis based on App Store knowledge through 2025.
- **ARCHITECTURE.md:** Textbook algorithms (trie, DFS, minimax, alpha-beta pruning, UCI protocol). SwiftUI patterns documented in Apple WWDC22/23 sessions. Protocol-oriented design is Swift best practice.
- **PITFALLS.md:** Well-documented issues in iOS development (memory management, main thread blocking, App Store review), game AI (minimax scaling, evaluation cost), and Stockfish integration (C++ compilation, NNUE weights, UCI protocol).

### Secondary (MEDIUM confidence)
- **Stockfish iOS integration:** Community knowledge of chess app development. Specific wrapper names (`chesskit-swift`, `stockfish-ios`) are inferred from common naming patterns but not verified. Underlying technical challenges (C++17 compilation, NNUE bundling, UCI protocol) are HIGH confidence.
- **App Store rejection patterns:** Training knowledge of common rejection reasons (trademark violations, "cheat" framing, misleading info). Guidelines 1.1.6, 3.1.2(a), 4.0 are public. Specific 2026 enforcement strictness is uncertain.

### Tertiary (LOW confidence)
- **GamePigeon word list:** No documentation available. Dictionary mismatch is a known issue in word solver reviews but specific GamePigeon list is unknown. Mitigation: test extensively with real games.
- **GamePigeon rule variants:** No official documentation. Rules inferred from general knowledge of Checkers/Mancala variants but specific GamePigeon implementation must be validated through gameplay.
- **NWL2023 availability:** Mentioned as latest Scrabble word list but availability and licensing not verified.

### Verification needed before implementation
- Stockfish iOS wrapper existence and maintenance status (GitHub search)
- NWL2023 word list availability and licensing
- iOS 17 device coverage statistics (Apple docs)
- App Store Guidelines interpretation for game helper apps (2025-2026 developer forums)
- Stockfish GPL licensing compatibility with App Store (Stockfish license + App Store terms)

---

*Research completed: 2026-02-07*
*Ready for roadmap: yes*
