# Technology Stack

**Project:** GamePigeon Helper (iOS Game Solver)
**Researched:** 2026-02-07
**Research Mode:** Ecosystem (Stack dimension)
**Source Limitation:** Web/Context7 tools were unavailable. All recommendations are based on training data (cutoff ~May 2025). Versions and availability MUST be verified before implementation.

---

## Recommended Stack

### Core Platform

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Swift | 6.0+ | Primary language | Required for iOS. Swift 6 brings full data-race safety via strict concurrency checking, which matters for background engine computations. Compile-time guarantees prevent crashes in async solver work. | HIGH |
| SwiftUI | iOS 17+ | UI framework | Declarative UI is ideal for reactive solver output (results update as they compute). iOS 17 baseline gives access to `Observable` macro (replacing `ObservableObject`/`@Published` boilerplate), `SwiftData` if needed, and stable `NavigationStack`. iOS 17 covers ~95%+ of active devices by 2026. | HIGH |
| Xcode | 16+ | IDE/Build system | Required for iOS development. Xcode 16 ships Swift 6, latest SwiftUI previews, and improved SPM integration. | HIGH |

### Architecture Pattern

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `@Observable` macro | iOS 17+ | State management | Replaces `ObservableObject`/`@Published` with simpler `@Observable` class macro. Automatic fine-grained observation -- only views that read a property re-render when it changes. Critical for solver UIs where partial results stream in. | HIGH |
| Swift Concurrency (async/await, actors) | Swift 5.5+ | Background computation | Solvers (minimax, trie traversal) MUST run off the main thread. `Task {}` with `@Sendable` closures and actors provide structured concurrency without GCD complexity. Swift 6 strict concurrency makes data races compile-time errors. | HIGH |
| MVVM (lightweight) | -- | App architecture | SwiftUI is designed around MVVM. Each game gets a `ViewModel` (an `@Observable` class) that owns the engine and exposes results to the view. No need for heavier patterns (VIPER, TCA) for a tool app with no networking. | HIGH |

### Word Engine (Trie + DFS)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Custom Trie (hand-rolled) | -- | Dictionary lookup & prefix search | A trie is the only correct data structure for this use case. You need `isPrefix()` for DFS pruning (Word Hunt path search) and `isWord()` for validation. No Swift library provides the exact API needed (prefix-checking + path-constrained DFS). A trie over ~270K words is ~50-100MB in a naive implementation, or ~5-15MB with a DAWG/compressed trie. Hand-rolling is straightforward (~100 lines) and gives full control over memory layout. | HIGH |
| DAWG (Directed Acyclic Word Graph) | -- | Memory-optimized dictionary | A DAWG compresses the trie by sharing suffix nodes. For a 270K word English dictionary, a DAWG typically uses 5-10x less memory than a naive trie. Build the DAWG at compile time (offline tool) and serialize to a binary file bundled in the app. Deserialize on launch. This is a SHOULD-HAVE optimization, not a blocker for v1. Start with a plain trie; optimize to DAWG if memory is a concern. | MEDIUM |
| Plain text word list (TWL06 / SOWPODS / NWL) | -- | Dictionary source | TWL06 (~178K words) is the Tournament Word List used in North American Scrabble. SOWPODS (~267K) is the international list. NWL2023 is the latest official list. Use a public-domain or freely-available word list. Load from a `.txt` file in the app bundle, one word per line. Build trie on first launch, cache in memory. | HIGH |

### Chess Engine (Stockfish)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Stockfish (C++ source, compiled for iOS) | 16 or 17 | Chess move computation | Stockfish is the strongest open-source chess engine. It compiles for iOS/ARM64 via C++ with no platform-specific dependencies beyond POSIX threads. The approach: include Stockfish C++ source in the Xcode project, compile as a static library or directly in the target, and communicate via UCI protocol over stdin/stdout pipes (or in-process function calls). | HIGH |
| C++/Swift interop via bridging header | -- | Calling Stockfish from Swift | Use an Objective-C++ bridging layer: a thin `.mm` file that wraps Stockfish's UCI interface and exposes it to Swift via a bridging header. Swift cannot directly call C++ (Swift/C++ interop exists but is still maturing). The Obj-C++ bridge is battle-tested and reliable. | HIGH |
| UCI protocol | -- | Engine communication | Stockfish speaks UCI (Universal Chess Interface). Send `position fen <fen>` and `go depth <N>` commands, parse `bestmove` responses. This is a text-based protocol, trivially parsed in Swift. Run in a background thread/actor. | HIGH |

**Stockfish integration approach (detailed):**

1. Clone Stockfish source (C++ files from `src/`)
2. Add to Xcode project as a separate static library target
3. Create `StockfishBridge.h` / `StockfishBridge.mm` (Obj-C++ wrapper)
4. Expose a simple Swift API: `func analyze(fen: String, depth: Int) async -> BestMove`
5. Internally, the bridge spawns a Stockfish instance, sends UCI commands, parses responses
6. Skill level control: send `setoption name Skill Level value <0-20>` before analysis

**Confidence note:** I am aware of community wrappers like `ChessKitEngine` (formerly `StockfishKit`) on GitHub that package Stockfish as a Swift Package. These should be investigated -- if one exists and is maintained, it saves significant integration work. However, the raw C++ integration approach above always works as a fallback. **Verify current wrapper availability before implementation.**

| Alternative | Why Not |
|-------------|---------|
| Leela Chess Zero (Lc0) | Requires neural network weights (~30-100MB), GPU inference. Overkill for a helper app. Stockfish with NNUE is stronger on CPU anyway. |
| Custom chess engine | Years of development to match Stockfish quality. No reason to build from scratch. |
| Server-side Stockfish | Adds network dependency, latency, hosting costs. Bundled engine works offline. |

### Game Tree Search (Minimax)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Custom minimax + alpha-beta pruning | -- | Board game AI (Checkers, Four in a Row, Gomoku, Mancala) | Minimax with alpha-beta is the standard algorithm for two-player zero-sum games. No library needed -- the algorithm is ~50 lines of Swift. The real work is in game-specific evaluation functions and move generation. Build a generic `GameEngine` protocol and plug in game-specific implementations. | HIGH |
| Iterative deepening | -- | Time-bounded search | Instead of fixed-depth search, use iterative deepening: search depth 1, then 2, then 3... until time runs out. Return the best move found so far. This gives responsive UX (always have a move ready) and naturally handles games of varying complexity. | HIGH |
| Transposition table (Dictionary-based) | -- | Avoid redundant computation | Cache evaluated positions in a `[BoardHash: Evaluation]` dictionary. Use Zobrist hashing for fast incremental hash updates. Critical for Checkers and Gomoku where transpositions are common. | HIGH |

**Generic engine architecture:**

```swift
protocol GameState: Hashable {
    associatedtype Move
    var currentPlayer: Player { get }
    var isTerminal: Bool { get }
    func legalMoves() -> [Move]
    func applying(_ move: Move) -> Self
    func evaluate() -> Double  // +1.0 = player1 wins, -1.0 = player2 wins
}

func minimax<G: GameState>(
    state: G, depth: Int, alpha: Double, beta: Double, maximizing: Bool
) -> (move: G.Move?, score: Double) { ... }
```

Each game (Checkers, Four in a Row, Gomoku, Mancala) implements `GameState`. The minimax function is written once.

| Alternative | Why Not |
|-------------|---------|
| Monte Carlo Tree Search (MCTS) | Better for games with huge branching factors (Go). For the games in scope, minimax with alpha-beta is simpler, deterministic, and sufficient. MCTS would be overkill. |
| Neural network evaluation | Requires training data, GPU inference. Way out of scope. Hand-crafted evaluation functions work fine for these games. |

### Sea Battle (Probability Engine)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Custom probability density calculator | -- | Compute optimal shot placement | For each empty cell, count how many ways each remaining ship can be placed covering that cell, given known hits/misses. The cell with the highest count is the best shot. This is a brute-force enumeration algorithm, not a library. ~100-200 lines of Swift. | HIGH |
| Hunt/Target mode state machine | -- | Strategy switching | Hunt mode: shoot highest-probability cell. Target mode: when a hit is found, focus on adjacent cells to sink the ship. Standard Battleship AI pattern, well-documented. | HIGH |
| SwiftUI Canvas or Grid | -- | Heatmap visualization | Use SwiftUI's `Canvas` view or a `LazyVGrid` with colored cells. Map probability values to a color gradient (blue = low, red = high). No charting library needed -- it's a 10x10 colored grid. | HIGH |

### UI Components

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| SwiftUI `NavigationStack` | iOS 16+ | Navigation | Type-safe navigation with `NavigationPath`. Each game is a navigation destination from the home screen game picker. | HIGH |
| SwiftUI `Grid` / `LazyVGrid` | iOS 16+ | Board layouts | Native grid layouts for chess boards, Word Hunt 4x4 grid, Sea Battle 10x10 grid. No third-party grid libraries needed. | HIGH |
| SwiftUI `Canvas` | iOS 15+ | Custom drawing (heatmaps, paths) | For drawing Word Hunt swipe paths over the grid and Sea Battle probability heatmaps. Hardware-accelerated immediate-mode drawing. | HIGH |
| `Color.interpolate` / custom gradient | -- | Heatmap coloring | Map probability values [0,1] to a color gradient. SwiftUI `Color` can be initialized with HSB values for smooth blue-to-red gradients. | HIGH |
| SF Symbols | -- | Icons | Apple's built-in icon set for game picker icons, toolbar buttons. Free, consistent with iOS design. | HIGH |

### Bundled Resources

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| App Bundle (`Bundle.main`) | -- | Dictionary file storage | Bundle the word list `.txt` file directly in the app bundle. Access via `Bundle.main.url(forResource:withExtension:)`. Simple, reliable, no file management needed. | HIGH |
| Binary serialization (custom or `Codable`) | -- | Pre-built trie caching | Option 1: Build trie from text on first launch (~0.5-1s for 270K words), cache in memory. Option 2: Pre-serialize the trie to a binary format at build time, load the binary on launch for instant startup. Option 2 is better UX but more build-time tooling. **Start with Option 1; optimize if launch time matters.** | MEDIUM |
| Stockfish NNUE weights file | -- | Chess engine neural network | Stockfish 16+ uses NNUE (efficiently updatable neural network) for position evaluation. The weights file (`nn-*.nnue`, ~50-100MB) must be bundled in the app. Stockfish can also be compiled with the network embedded in the binary. **Verify the embedding approach with current Stockfish source.** | MEDIUM |

### Testing

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| XCTest | Built-in | Unit & integration tests | Built into Xcode. Test trie correctness (known words found, non-words rejected), minimax correctness (known game positions), probability calculations. | HIGH |
| Swift Testing framework | Swift 5.10+ | Modern test syntax | Apple's new testing framework with `@Test` and `#expect` macros. Cleaner syntax than XCTest. Available in Xcode 16+. Use for new tests; XCTest for anything it can't handle yet. | MEDIUM |
| XCTest `measure {}` | Built-in | Performance testing | Profile trie lookup speed, minimax search depth/time, dictionary load time. Critical for ensuring solvers run fast enough for good UX. | HIGH |

### Dev Tooling

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Swift Package Manager (SPM) | Built-in | Dependency management | Xcode-native. No CocoaPods/Carthage needed for this project (minimal external dependencies). Use SPM if any packages are added. | HIGH |
| SwiftLint | Latest | Code style enforcement | Catches common Swift issues, enforces consistent style. Add as a build phase script. | MEDIUM |
| Instruments (Xcode) | Built-in | Performance profiling | Profile memory usage (trie size), CPU usage (minimax depth), main thread blocking. Essential for solver performance tuning. | HIGH |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| UI Framework | SwiftUI | UIKit | SwiftUI is sufficient for this app's UI needs (grids, lists, navigation). UIKit adds complexity with no benefit. The app has no complex custom gestures or UIKit-only features. |
| UI Framework | SwiftUI | React Native / Flutter | Cross-platform irrelevant -- iOS only. Native gives best performance for compute-heavy solvers and smallest binary. |
| State Management | `@Observable` | TCA (The Composable Architecture) | TCA is powerful but heavy. This app has no complex side effects, no networking, no shared state between features. `@Observable` + MVVM is the right weight. |
| State Management | `@Observable` | `ObservableObject` + `@Published` | Legacy pattern. `@Observable` (iOS 17+) is simpler, more performant (fine-grained updates), and the modern standard. Since we target iOS 17+, use it. |
| Data Persistence | None (in-memory) | SwiftData / Core Data | No persistent data needed. Dictionary loads from bundle each launch. Game state is ephemeral. If settings persistence is needed later, `UserDefaults` suffices. |
| Data Persistence | `UserDefaults` (settings only) | Keychain | Only for trivial preferences (last game selected, theme). Keychain is for secrets; not applicable. |
| Charting | Custom Canvas | Swift Charts | Swift Charts is for data visualization (line charts, bar charts). Heatmaps and board game grids are custom layouts, not charts. Swift Charts would fight the layout rather than help. |
| Networking | None | Alamofire / URLSession | App is fully offline. No API calls, no server, no networking stack needed. |
| Chess Engine | Stockfish (bundled C++) | Lichess API | Network dependency. Offline is better for a helper app (no latency, works on airplane mode, no API limits). |
| Word Lookup | Custom Trie | SQLite FTS | Trie gives prefix search + DFS traversal needed for Word Hunt path-finding. SQLite FTS is for text search, not graph traversal. Wrong tool for the job. |
| Word Lookup | Custom Trie | `Set<String>` | A `Set` can check `contains()` but cannot do prefix search. Word Hunt needs "is this prefix valid?" to prune DFS branches. Without prefix pruning, search is exponentially slower. |

---

## Dependencies Summary

This project is intentionally **dependency-minimal**. The only significant external code is Stockfish (C++ source compiled into the app).

### External Dependencies

| Dependency | Type | Size Impact | Maintenance Risk |
|------------|------|-------------|------------------|
| Stockfish source (C++) | Compiled into app | ~50-100MB (includes NNUE weights) | Low -- stable, well-maintained open source. Pin to a specific version. |
| Word list (TWL06/SOWPODS/NWL) | Bundled text file | ~3-5MB | None -- static data file. |

### Zero External Swift Packages Required

Every other component (trie, minimax, probability engine, UI) is built with Swift standard library + SwiftUI + platform frameworks. This is intentional:

- **No supply chain risk** from third-party packages
- **No version compatibility issues** when Xcode/Swift updates
- **Full control** over algorithm implementations (critical for solver correctness)
- **Smaller binary** -- no unused framework code

---

## Project Structure (Recommended)

```
GameCheat/
  App/
    GameCheatApp.swift              # @main entry point
    ContentView.swift               # Game picker / home screen
  Core/
    Trie/
      Trie.swift                    # Trie data structure
      TrieNode.swift                # Node type
      DictionaryLoader.swift        # Load word list from bundle
    Minimax/
      GameState.swift               # Protocol definition
      MinimaxEngine.swift           # Generic minimax + alpha-beta
      TranspositionTable.swift      # Zobrist hashing + cache
    Stockfish/
      StockfishBridge.h             # Obj-C++ header
      StockfishBridge.mm            # Obj-C++ implementation
      StockfishEngine.swift         # Swift wrapper (async API)
    Probability/
      SeaBattleSolver.swift         # Density calculator
      HuntTargetStateMachine.swift  # Hunt/target mode logic
  Features/
    WordHunt/
      WordHuntView.swift
      WordHuntViewModel.swift
      WordHuntSolver.swift          # DFS with trie + grid constraints
    Anagrams/
      AnagramsView.swift
      AnagramsViewModel.swift
      AnagramsSolver.swift          # Permutation search with trie
    WordBites/
      WordBitesView.swift
      WordBitesViewModel.swift
      WordBitesSolver.swift         # Fragment combination with trie
    Chess/
      ChessView.swift
      ChessViewModel.swift
      ChessBoardState.swift         # FEN generation, piece tracking
    Checkers/
      CheckersView.swift
      CheckersViewModel.swift
      CheckersState.swift           # GameState conformance
    FourInARow/
      FourInARowView.swift
      FourInARowViewModel.swift
      FourInARowState.swift         # GameState conformance
    Gomoku/
      GomokuView.swift
      GomokuViewModel.swift
      GomokuState.swift             # GameState conformance
    Mancala/
      MancalaView.swift
      MancalaViewModel.swift
      MancalaState.swift            # GameState conformance
    SeaBattle/
      SeaBattleView.swift
      SeaBattleViewModel.swift
  Resources/
    dictionary.txt                  # Word list (~270K words)
    nn-*.nnue                       # Stockfish NNUE weights
  Stockfish-Source/                  # Stockfish C++ source files
    src/
      ...
  Tests/
    TrieTests.swift
    MinimaxTests.swift
    WordHuntSolverTests.swift
    SeaBattleSolverTests.swift
    StockfishIntegrationTests.swift
```

---

## Build Configuration Notes

### Stockfish Compilation

- Add Stockfish C++ source files to a separate static library target in Xcode
- Set C++ Language Dialect to `C++17` (Stockfish requirement)
- Enable `-O2` or `-O3` optimization for the Stockfish target (debug builds will be unusably slow)
- The NNUE weights file can be embedded in the binary at compile time via Stockfish's `make` system, or bundled as a separate file in the app bundle
- **App Store note:** Stockfish is GPL-licensed. The app that links Stockfish must also be GPL-compatible, OR Stockfish must be run as a separate process. **This is a critical legal consideration that needs resolution before implementation.** Options: (1) open-source the app under GPL, (2) use Stockfish via XPC/process separation to avoid linking, (3) investigate whether App Store distribution of GPL apps is feasible. **Flag this for the roadmap.**

### Swift Concurrency Configuration

- Enable `SWIFT_STRICT_CONCURRENCY=complete` in build settings (Swift 6 mode)
- Mark solver classes as `@Sendable` or use actors for thread safety
- All engine computations run in `Task { }` blocks, never on `@MainActor`

### App Size Budget

| Component | Estimated Size |
|-----------|---------------|
| App binary (Swift + C++) | ~5-10MB |
| Stockfish NNUE weights | ~50-100MB |
| Dictionary text file | ~3-5MB |
| **Total** | **~60-115MB** |

**Note:** The NNUE weights dominate app size. If this is a concern, investigate Stockfish's "small net" option (~5MB) which trades some strength for size. For a helper app, the small net is likely sufficient.

---

## Installation / Setup

```bash
# No npm/package installs -- this is a native Xcode project

# 1. Create Xcode project (SwiftUI App template)
# 2. Set deployment target to iOS 17.0
# 3. Add word list to Resources/
# 4. Clone Stockfish source into Stockfish-Source/
git clone https://github.com/official-stockfish/Stockfish.git Stockfish-Source

# 5. Add Stockfish C++ files to Xcode project as static library target
# 6. Create bridging header for Obj-C++ interop
# 7. Build and run
```

---

## Version Verification Needed

The following versions could not be verified with live sources and MUST be checked before implementation:

| Item | Claimed | Verify At | Priority |
|------|---------|-----------|----------|
| Stockfish latest version | 16 or 17 | github.com/official-stockfish/Stockfish/releases | HIGH |
| Stockfish NNUE file size | ~50-100MB | Stockfish source/docs | HIGH |
| Stockfish GPL implications for iOS | GPL v3 | Stockfish LICENSE file + App Store guidelines | CRITICAL |
| `@Observable` availability | iOS 17+ | Apple developer docs | HIGH (likely correct) |
| Swift Testing `@Test` macro | Xcode 16+ | Apple developer docs | MEDIUM |
| ChessKitEngine / community Stockfish wrappers | Unknown | GitHub search, SPM registries | HIGH |
| NWL2023 word list availability | Public domain | NSA (National Scrabble Association) | MEDIUM |
| Stockfish small net availability | Unknown | Stockfish docs | LOW |

---

## Sources

All recommendations are based on training data (cutoff ~May 2025). Web search and Context7 tools were unavailable during this research session. Confidence levels reflect this limitation:

- **HIGH confidence items:** Core Swift/SwiftUI patterns, algorithm choices, architecture patterns. These are stable, well-established technologies unlikely to have changed significantly.
- **MEDIUM confidence items:** Specific version numbers, newer framework features. Likely correct but should be verified.
- **LOW confidence items:** Specific third-party library availability, exact file sizes. Must be verified before committing to the approach.

Key references (to verify):
- Apple Developer Documentation: developer.apple.com/documentation/swiftui
- Stockfish GitHub: github.com/official-stockfish/Stockfish
- Swift Evolution proposals: swift.org/swift-evolution
- Swift Package Index: swiftpackageindex.com (search for chess/Stockfish wrappers)
