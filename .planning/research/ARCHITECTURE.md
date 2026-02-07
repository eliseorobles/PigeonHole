# Architecture Patterns

**Domain:** iOS Multi-Game Solver (GamePigeon Helper)
**Researched:** 2026-02-07
**Note:** Web search and Context7 were unavailable. All recommendations are based on training knowledge of SwiftUI, algorithm design, and Stockfish integration patterns. Confidence levels are marked accordingly.

## Recommended Architecture

### High-Level Structure

```
GameCheat/
├── App/
│   ├── GameCheatApp.swift              # @main entry point
│   └── ContentView.swift               # Root NavigationStack
│
├── Core/
│   ├── WordEngine/
│   │   ├── Trie.swift                  # Trie data structure
│   │   ├── TrieNode.swift              # Node with children + isWord flag
│   │   └── WordDictionary.swift        # Loads words.txt, builds Trie, exposes search API
│   │
│   ├── MinimaxEngine/
│   │   ├── GameState.swift             # Protocol: board state, moves, evaluation
│   │   ├── MinimaxSolver.swift         # Generic minimax + alpha-beta pruning
│   │   └── TranspositionTable.swift    # Zobrist hashing cache (optional, phase 2+)
│   │
│   ├── StockfishEngine/
│   │   ├── StockfishProcess.swift      # Pipes to/from Stockfish binary via UCI
│   │   └── UCIProtocol.swift           # UCI command formatting + response parsing
│   │
│   └── BattleshipEngine/
│       ├── ProbabilityGrid.swift       # Density heatmap calculation
│       └── HuntTargetStrategy.swift    # Hunt/target mode state machine
│
├── Games/
│   ├── WordHunt/
│   │   ├── WordHuntView.swift          # 4x4 letter grid input UI
│   │   ├── WordHuntViewModel.swift     # Drives DFS pathfinding on grid
│   │   ├── WordHuntSolver.swift        # DFS with adjacency + Trie prefix pruning
│   │   └── WordHuntResult.swift        # Word + path (sequence of grid positions)
│   │
│   ├── Anagrams/
│   │   ├── AnagramsView.swift          # Letter input UI
│   │   ├── AnagramsViewModel.swift     # Drives subset search
│   │   ├── AnagramsSolver.swift        # Subset permutation search with Trie pruning
│   │   └── AnagramsResult.swift        # Word + letters used
│   │
│   ├── WordBites/
│   │   ├── WordBitesView.swift         # Fragment input UI (single letters + 2-letter blocks)
│   │   ├── WordBitesViewModel.swift    # Drives fragment combination search
│   │   ├── WordBitesSolver.swift       # Combine fragments, check Trie
│   │   └── WordBitesResult.swift       # Word + fragments used
│   │
│   ├── Chess/
│   │   ├── ChessView.swift             # Tap-based board UI + skill slider
│   │   ├── ChessViewModel.swift        # Manages Stockfish communication
│   │   ├── ChessBoard.swift            # Board model, FEN generation
│   │   └── ChessPiece.swift            # Piece types, colors
│   │
│   ├── Checkers/
│   │   ├── CheckersView.swift          # Board UI
│   │   ├── CheckersViewModel.swift     # Drives minimax search
│   │   ├── CheckersState.swift         # Conforms to GameState protocol
│   │   └── CheckersEval.swift          # Position evaluation heuristic
│   │
│   ├── FourInARow/
│   │   ├── FourInARowView.swift        # Column-drop UI
│   │   ├── FourInARowViewModel.swift   # Drives minimax search
│   │   ├── FourInARowState.swift       # Conforms to GameState protocol
│   │   └── FourInARowEval.swift        # Window-based evaluation
│   │
│   ├── Gomoku/
│   │   ├── GomokuView.swift            # 15x15 (or smaller) board UI
│   │   ├── GomokuViewModel.swift       # Drives minimax search
│   │   ├── GomokuState.swift           # Conforms to GameState protocol
│   │   └── GomokuEval.swift            # Threat-based evaluation
│   │
│   ├── Mancala/
│   │   ├── MancalaView.swift           # Pit/store UI
│   │   ├── MancalaViewModel.swift      # Drives minimax search
│   │   ├── MancalaState.swift          # Conforms to GameState protocol
│   │   └── MancalaEval.swift           # Store-difference evaluation
│   │
│   └── SeaBattle/
│       ├── SeaBattleView.swift         # 10x10 tap grid + heatmap overlay
│       ├── SeaBattleViewModel.swift    # Manages hit/miss state, drives probability calc
│       └── SeaBattleResult.swift       # Cell probabilities for heatmap coloring
│
├── Shared/
│   ├── Views/
│   │   ├── GamePickerView.swift        # Home screen grid of games
│   │   ├── BoardGridView.swift         # Reusable grid component (used by multiple games)
│   │   └── ResultsListView.swift       # Reusable scrollable results list
│   ├── Models/
│   │   ├── GridPosition.swift          # Row/col coordinate
│   │   └── GameType.swift              # Enum of all supported games
│   └── Extensions/
│       └── Array+Extensions.swift      # Grid helpers, etc.
│
└── Resources/
    └── words.txt                       # ~270K word dictionary, bundled in app
```

### Component Boundaries

| Component | Responsibility | Communicates With | Boundary Rule |
|-----------|---------------|-------------------|---------------|
| **WordDictionary** | Loads dictionary, builds Trie, answers `isWord()` and `hasPrefix()` queries | WordHunt/Anagrams/WordBites solvers | Pure data structure. No UI knowledge. Singleton loaded once at app launch. |
| **MinimaxSolver** | Generic game tree search with alpha-beta pruning | Checkers/FourInARow/Gomoku/Mancala states via `GameState` protocol | Knows nothing about specific games. Receives a `GameState`, returns a `Move`. |
| **StockfishProcess** | Manages Stockfish binary lifecycle, sends UCI commands, reads responses | ChessViewModel only | Runs on background thread. Communicates via UCI text protocol over pipes. |
| **BattleshipEngine** | Calculates cell probabilities given known hits/misses/sinks and remaining ships | SeaBattleViewModel only | Pure computation. No UI knowledge. |
| **Game ViewModels** | Translate user input into engine calls, format results for views | Their respective View + their respective Core engine | Own the game-specific logic (grid adjacency, move legality for input validation). |
| **Game Views** | Display input controls and results | Their respective ViewModel only | No direct engine access. Pure SwiftUI views. |
| **GamePickerView** | Navigation hub, launches game-specific views | NavigationStack + all game views via navigation destinations | Knows game list, knows nothing about game logic. |

### Data Flow

#### Word Games (Word Hunt / Anagrams / Word Bites)

```
App Launch
    │
    ▼
WordDictionary.shared (singleton)
    │  Loads words.txt from Bundle
    │  Builds Trie in background
    ▼
Trie (in memory, ~15-25 MB for 270K words)
    │
    ├──── WordHuntSolver.solve(grid: [[Character]]) → [WordHuntResult]
    │     Uses: trie.hasPrefix() for DFS pruning
    │     Uses: trie.isWord() for word validation
    │     DFS explores all paths on 4x4 grid with adjacency constraint
    │
    ├──── AnagramsSolver.solve(letters: [Character]) → [AnagramsResult]
    │     Uses: trie.hasPrefix() for pruning
    │     Uses: trie.isWord() for validation
    │     Sorted subset search (backtracking over sorted letter counts)
    │
    └──── WordBitesSolver.solve(fragments: [Fragment]) → [WordBitesResult]
          Uses: trie.hasPrefix() for pruning
          Uses: trie.isWord() for validation
          Fragment combination search
```

#### Board Games (Checkers / Four in a Row / Gomoku / Mancala)

```
User taps board to set up position
    │
    ▼
GameSpecificViewModel
    │  Validates input, builds initial GameState
    ▼
MinimaxSolver.bestMove(state: GameState, depth: Int) → Move
    │  Alpha-beta pruning
    │  Calls state.generateMoves()
    │  Calls state.evaluate()
    │  Calls state.apply(move:) → new GameState
    ▼
Returns best Move to ViewModel
    │
    ▼
ViewModel updates View with recommended move highlighted
```

#### Chess (Stockfish)

```
User taps to place/move pieces on board
    │
    ▼
ChessViewModel
    │  Converts board to FEN string
    ▼
StockfishProcess (background thread)
    │  Sends: "position fen [FEN]"
    │  Sends: "setoption name Skill Level value [0-20]"
    │  Sends: "go movetime [ms]"
    │  Reads: "bestmove [move]"
    ▼
ChessViewModel receives best move
    │  Parses algebraic notation
    ▼
ChessView highlights recommended move on board
```

#### Sea Battle

```
User taps grid to mark hits (red) / misses (white)
User configures remaining ships
    │
    ▼
SeaBattleViewModel
    │  Tracks: hits[], misses[], sunkShips[], remainingShips[]
    ▼
ProbabilityGrid.calculate(hits:misses:sunkShips:remainingShips:) → [[Double]]
    │  For each remaining ship:
    │    Try every valid placement
    │    Increment cell counters for valid placements
    │  Normalize to probabilities
    ▼
SeaBattleViewModel receives probability grid
    │
    ▼
SeaBattleView renders heatmap overlay (color intensity = probability)
    Highlights highest-probability cell(s)
```

### Navigation Architecture

```
GameCheatApp (@main)
    │
    ▼
NavigationStack {
    GamePickerView               ← Root: Grid/list of game icons
        │
        ├─ NavigationLink → WordHuntView
        ├─ NavigationLink → AnagramsView
        ├─ NavigationLink → WordBitesView
        ├─ NavigationLink → ChessView
        ├─ NavigationLink → CheckersView
        ├─ NavigationLink → FourInARowView
        ├─ NavigationLink → GomokuView
        ├─ NavigationLink → MancalaView
        └─ NavigationLink → SeaBattleView
}
```

Use `NavigationStack` (not the deprecated `NavigationView`) with `navigationDestination(for:)` for type-safe navigation. Each game is a `NavigationLink` from the picker to the game-specific view. Results appear inline within the game view (not a separate navigation push) because users need to reference results while looking at the game.

**Confidence: HIGH** -- NavigationStack is the standard SwiftUI navigation pattern since iOS 16.

## Patterns to Follow

### Pattern 1: Protocol-Oriented Generic Engine (Minimax)

**What:** Define a `GameState` protocol that the minimax solver operates on generically. Each game provides its own conforming type.
**When:** Any time multiple games share the same search algorithm but differ in rules.
**Why:** Write minimax once. Add a new game by conforming to the protocol -- zero changes to the engine.

**Confidence: HIGH** -- This is textbook protocol-oriented design in Swift.

```swift
// MARK: - Core/MinimaxEngine/GameState.swift

protocol GameState: Hashable {
    associatedtype Move: Hashable

    var currentPlayer: Player { get }

    /// Generate all legal moves from this state.
    func generateMoves() -> [Move]

    /// Apply a move, returning the new state. Must not mutate self.
    func applying(_ move: Move) -> Self

    /// Heuristic evaluation from the perspective of the maximizing player.
    /// Positive = good for maximizer, negative = good for minimizer.
    func evaluate() -> Double

    /// Is this a terminal state (win/loss/draw)?
    var isTerminal: Bool { get }
}

enum Player {
    case maximizer, minimizer
    var opponent: Player {
        self == .maximizer ? .minimizer : .maximizer
    }
}
```

```swift
// MARK: - Core/MinimaxEngine/MinimaxSolver.swift

struct MinimaxSolver {

    /// Returns the best move for the current player.
    static func bestMove<S: GameState>(
        state: S,
        depth: Int,
        maximizing: Bool = true
    ) -> S.Move? {
        var bestMove: S.Move?
        var bestValue = maximizing ? -Double.infinity : Double.infinity

        for move in state.generateMoves() {
            let newState = state.applying(move)
            let value = minimax(
                state: newState,
                depth: depth - 1,
                alpha: -Double.infinity,
                beta: Double.infinity,
                maximizing: !maximizing
            )

            if maximizing ? (value > bestValue) : (value < bestValue) {
                bestValue = value
                bestMove = move
            }
        }

        return bestMove
    }

    private static func minimax<S: GameState>(
        state: S,
        depth: Int,
        alpha: Double,
        beta: Double,
        maximizing: Bool
    ) -> Double {
        if depth == 0 || state.isTerminal {
            return state.evaluate()
        }

        var alpha = alpha
        var beta = beta

        if maximizing {
            var value = -Double.infinity
            for move in state.generateMoves() {
                value = max(value, minimax(
                    state: state.applying(move),
                    depth: depth - 1,
                    alpha: alpha,
                    beta: beta,
                    maximizing: false
                ))
                alpha = max(alpha, value)
                if alpha >= beta { break } // Beta cutoff
            }
            return value
        } else {
            var value = Double.infinity
            for move in state.generateMoves() {
                value = min(value, minimax(
                    state: state.applying(move),
                    depth: depth - 1,
                    alpha: alpha,
                    beta: beta,
                    maximizing: true
                ))
                beta = min(beta, value)
                if alpha >= beta { break } // Alpha cutoff
            }
            return value
        }
    }
}
```

```swift
// MARK: - Games/FourInARow/FourInARowState.swift (example conformance)

struct FourInARowState: GameState {
    typealias Move = Int  // Column index (0-6)

    let board: [[CellState]]  // 6 rows x 7 columns
    let currentPlayer: Player

    func generateMoves() -> [Int] {
        (0..<7).filter { board[0][$0] == .empty }
    }

    func applying(_ move: Int) -> FourInARowState {
        var newBoard = board
        // Drop piece in lowest empty row of column
        for row in stride(from: 5, through: 0, by: -1) {
            if newBoard[row][move] == .empty {
                newBoard[row][move] = currentPlayer == .maximizer ? .red : .yellow
                break
            }
        }
        return FourInARowState(board: newBoard, currentPlayer: currentPlayer.opponent)
    }

    func evaluate() -> Double {
        // Window-based evaluation: count 2s, 3s, 4s in a row
        // Return large positive for maximizer win, negative for loss
        // ...implementation...
        0.0
    }

    var isTerminal: Bool {
        // Check for 4-in-a-row or full board
        false
    }
}
```

### Pattern 2: Singleton Dictionary with Async Loading

**What:** Load the 270K-word dictionary once at app launch on a background thread. Surface a loading state in the UI until ready.
**When:** Any shared resource that is expensive to initialize and used by multiple features.
**Why:** Trie construction from 270K words takes ~0.5-1.5 seconds. Must not block the main thread. Must only happen once.

**Confidence: HIGH** -- Standard iOS resource loading pattern.

```swift
// MARK: - Core/WordEngine/WordDictionary.swift

@MainActor
final class WordDictionary: ObservableObject {
    static let shared = WordDictionary()

    @Published private(set) var isLoaded = false
    private var trie = Trie()

    private init() {}

    func loadIfNeeded() {
        guard !isLoaded else { return }
        Task.detached(priority: .userInitiated) { [self] in
            let trie = await self.buildTrie()
            await MainActor.run {
                self.trie = trie
                self.isLoaded = true
            }
        }
    }

    private func buildTrie() async -> Trie {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "txt"),
              let contents = try? String(contentsOf: url) else {
            return Trie()
        }
        let trie = Trie()
        for word in contents.split(separator: "\n") {
            trie.insert(String(word).lowercased())
        }
        return trie
    }

    func isWord(_ word: String) -> Bool { trie.search(word.lowercased()) }
    func hasPrefix(_ prefix: String) -> Bool { trie.startsWith(prefix.lowercased()) }
}
```

### Pattern 3: ViewModel per Game (MVVM)

**What:** Each game has its own `@Observable` (or `ObservableObject`) ViewModel that owns state and talks to the engine.
**When:** Always. Every game view needs a ViewModel.
**Why:** Keeps views declarative (SwiftUI's strength). Keeps engine logic testable without UI. Clear separation of concerns.

**Confidence: HIGH** -- Standard SwiftUI MVVM.

```swift
// MARK: - Games/WordHunt/WordHuntViewModel.swift

@Observable
final class WordHuntViewModel {
    var grid: [[Character]] = Array(repeating: Array(repeating: " ", count: 4), count: 4)
    var results: [WordHuntResult] = []
    var isSearching = false

    private let dictionary = WordDictionary.shared

    func solve() {
        guard dictionary.isLoaded else { return }
        isSearching = true

        Task.detached(priority: .userInitiated) {
            let solver = WordHuntSolver(grid: self.grid, dictionary: self.dictionary)
            let results = solver.findAllWords()

            await MainActor.run {
                self.results = results.sorted { $0.word.count > $1.word.count }
                self.isSearching = false
            }
        }
    }
}
```

### Pattern 4: Stockfish as a Background Process via Pipes

**What:** Compile Stockfish C++ source into the app binary. Communicate via stdin/stdout pipes using the UCI (Universal Chess Interface) text protocol.
**When:** Chess game only.
**Why:** Stockfish is a C++ engine. iOS does not allow spawning child processes, so it must be compiled directly into the app as a library/framework and run on a background thread, communicating via in-memory pipes or direct function calls.

**Confidence: MEDIUM** -- Stockfish iOS integration is well-documented in the community, but specific Swift wrapper API details could not be verified with current tools. The general pattern (C++ compiled into app, UCI over pipes/direct calls) is well-established.

```swift
// MARK: - Core/StockfishEngine/StockfishBridge.swift (Conceptual)

/// Stockfish on iOS cannot use Process (sandboxing forbids it).
/// Instead, Stockfish C++ is compiled into the app as a static library.
/// Communication happens via:
///   Option A: An Objective-C++ bridge that calls Stockfish's main loop
///             with redirected stdin/stdout to in-memory buffers.
///   Option B: A community Swift package (e.g., "stockfish-swift" or
///             "ChessKitEngine") that wraps this for you.
///
/// The UCI protocol is text-based:
///   Send: "uci"           → Receive: "uciok"
///   Send: "isready"       → Receive: "readyok"
///   Send: "setoption name Skill Level value 10"
///   Send: "position fen [FEN string]"
///   Send: "go movetime 1000"
///   Receive: "bestmove e2e4"

actor StockfishEngine {
    private var isReady = false

    func start() async {
        // Initialize Stockfish library
        // Send "uci", wait for "uciok"
        // Send "isready", wait for "readyok"
        isReady = true
    }

    func setSkillLevel(_ level: Int) async {
        // Send "setoption name Skill Level value \(level)"
    }

    func bestMove(fen: String, moveTimeMs: Int = 1000) async -> String? {
        // Send "position fen \(fen)"
        // Send "go movetime \(moveTimeMs)"
        // Parse response for "bestmove [move]"
        // Return the move in algebraic notation
        nil
    }

    func stop() {
        // Send "quit"
    }
}
```

**Important iOS constraint:** You cannot use Foundation's `Process` class on iOS (it is macOS-only). Stockfish must be compiled as a static library linked into the app. Community packages handle this. Search for packages like `ChessKitEngine` or compile Stockfish source directly with an Objective-C++ bridge.

### Pattern 5: Bundled Dictionary as App Resource

**What:** Include `words.txt` in the Xcode project as a bundle resource. Load via `Bundle.main.url(forResource:withExtension:)`.
**When:** Any static data file the app needs.
**Why:** Simple, reliable, no network dependency. 270K words in plain text is approximately 2.5-3 MB -- trivial for an app bundle.

**Confidence: HIGH** -- Standard iOS resource bundling.

```
In Xcode:
1. Drag words.txt into the project navigator
2. Ensure "Copy items if needed" is checked
3. Ensure target membership is checked for the app target
4. Access via Bundle.main.url(forResource: "words", withExtension: "txt")
```

File size estimate for 270K words: ~2.5 MB uncompressed. App Store applies additional compression. This is well within acceptable app size.

## Anti-Patterns to Avoid

### Anti-Pattern 1: God ViewModel

**What:** Putting all game logic into one massive ViewModel or a single "GameManager" class.
**Why bad:** Violates single responsibility. Makes testing impossible. Makes adding new games painful. Creates merge conflicts if working on multiple games simultaneously.
**Instead:** One ViewModel per game. One shared engine per engine type. Clean protocol boundaries.

### Anti-Pattern 2: Synchronous Dictionary Loading

**What:** Loading and parsing 270K words on the main thread at app launch.
**Why bad:** The app will freeze for 1-2 seconds on launch. On older devices, the system watchdog may kill the app entirely (launch timeout).
**Instead:** Load in a background Task. Show a loading indicator. Gate word game "Solve" buttons on `dictionary.isLoaded`.

### Anti-Pattern 3: Minimax Without Alpha-Beta Pruning

**What:** Implementing plain minimax without alpha-beta pruning.
**Why bad:** Without pruning, the search tree is O(b^d) where b = branching factor and d = depth. With alpha-beta, this drops to O(b^(d/2)) in the best case -- effectively doubling your search depth for the same computation time. For Gomoku (b~200+), plain minimax is unusable beyond depth 2.
**Instead:** Always implement alpha-beta. For Gomoku, also consider move ordering (check center moves first, check moves near existing pieces first) to improve pruning efficiency.

### Anti-Pattern 4: Mutable GameState in Minimax

**What:** Using a mutable board that you modify and undo during minimax search.
**Why bad:** Extremely error-prone. Undo logic is a constant source of bugs, especially with complex games like Checkers (multi-jumps, king promotions). Debugging is nightmarish because state depends on call stack.
**Instead:** Use value types (structs) for GameState. `applying(_:)` returns a new copy. Swift's copy-on-write optimizes this well for arrays. The slight memory overhead is worth the correctness guarantee.

### Anti-Pattern 5: Reaching Into Other Games' Internals

**What:** One game's solver directly accessing another game's types or state.
**Why bad:** Creates coupling that makes it hard to modify or remove games independently.
**Instead:** Games share engines (WordDictionary, MinimaxSolver) but never reference each other. The shared engines know nothing about specific games.

## Scalability Considerations

| Concern | Current (10 games) | Future (20+ games) | Mitigation |
|---------|--------------------|--------------------|------------|
| App launch time | Trie loads in ~1s background | Same (dictionary is shared) | Already async, no issue |
| App binary size | ~5 MB (Stockfish ~3 MB, dict ~2.5 MB) | ~6 MB (more game logic is tiny) | Acceptable for App Store |
| Memory usage | ~20-30 MB (Trie ~20 MB, rest minimal) | Same (Trie dominates) | Fine for any iOS device since iPhone 6s |
| Minimax performance | Varies by game (see below) | Same per-game | Tune depth per game |
| Code organization | Clean with current structure | May want Swift Package modules | Split into local packages if needed |

### Minimax Depth Tuning Per Game

| Game | Branching Factor | Recommended Max Depth | Expected Computation Time | Notes |
|------|------------------|-----------------------|---------------------------|-------|
| Four in a Row | ~7 (columns) | 10-12 | < 1 second | Low branching, deep search feasible |
| Mancala | ~6 (pits) | 12-15 | < 1 second | Low branching, deep search feasible |
| Checkers | ~5-10 (moves) | 10-12 | 1-3 seconds | Multi-jump moves increase branching |
| Gomoku | ~200+ (empty cells) | 3-4 (with move restriction) | 1-3 seconds | MUST restrict candidate moves to neighbors of existing pieces |

**Critical note on Gomoku:** Naive move generation on a 15x15 board produces 200+ moves. Minimax at depth 4 with b=200 is 200^4 = 1.6 billion nodes -- impossible. Restrict candidate moves to cells within 1-2 spaces of existing pieces. This typically reduces branching to ~20-40 moves, making depth 4-6 feasible.

## Key Architectural Decisions

### Decision 1: Value Types (Structs) for Game State

Use structs, not classes, for all `GameState` conformances. This makes minimax search correct by construction -- no accidental mutation, no undo bugs. Swift's copy-on-write for arrays means this is efficient enough.

**Confidence: HIGH**

### Decision 2: `@Observable` over `ObservableObject`

Use the `@Observable` macro (iOS 17+) instead of `ObservableObject` + `@Published`. It is more ergonomic and more performant (fine-grained observation -- views only re-render when their specific observed properties change, not when any `@Published` property changes).

**Confidence: HIGH** -- `@Observable` is the recommended approach for iOS 17+ per Apple's WWDC23 guidance.

### Decision 3: Actor for Stockfish

Use a Swift `actor` for the Stockfish engine to guarantee thread safety. UCI communication is inherently sequential (send command, wait for response), and actor isolation enforces this naturally.

**Confidence: MEDIUM** -- Actor is the right concurrency primitive, but the specific Stockfish Swift wrapper you choose may impose its own concurrency model.

### Decision 4: Single NavigationStack (Not TabView)

Use a single `NavigationStack` with a game picker root, not a `TabView`. Rationale:
- 10 games do not fit in a tab bar (max 5 tabs + "More" is ugly)
- Users pick one game at a time, use it, then go back -- this is a stack-based flow
- A grid/list picker is more scalable and more visually appropriate for a game selection screen

**Confidence: HIGH**

### Decision 5: No Core Data / No Persistence (v1)

No database needed for v1. Game state is ephemeral -- user inputs board state, gets results, done. No history, no saved games, no user accounts. The dictionary is read-only from the bundle.

**Confidence: HIGH** -- Matches PROJECT.md scope.

## Build Order (Dependencies)

The dependency graph determines what must be built first:

```
Phase 1: Foundation
    ├── Trie + WordDictionary (no dependencies)
    ├── App shell + NavigationStack + GamePickerView (no dependencies)
    └── These are independent and can be built in parallel

Phase 2: First Game (Word Hunt)
    ├── Depends on: WordDictionary (Phase 1)
    ├── WordHuntSolver (DFS + adjacency + Trie pruning)
    ├── WordHuntView + ViewModel
    └── This proves the entire vertical stack works end-to-end

Phase 3: Other Word Games (Anagrams, Word Bites)
    ├── Depends on: WordDictionary (Phase 1)
    ├── These reuse the same Trie, just different search strategies
    └── Can be built in parallel with each other

Phase 4: Minimax Engine + First Board Game
    ├── GameState protocol + MinimaxSolver (no game dependencies)
    ├── Four in a Row as first conformance (simplest board game)
    └── Proves the generic engine works

Phase 5: Remaining Board Games
    ├── Depends on: MinimaxSolver (Phase 4)
    ├── Checkers, Gomoku, Mancala (each is independent)
    └── Can be built in parallel with each other

Phase 6: Chess (Stockfish)
    ├── Depends on: finding/integrating a Stockfish iOS package
    ├── Highest integration risk -- external C++ dependency
    └── Board UI + FEN generation + UCI communication

Phase 7: Sea Battle
    ├── No dependencies on other engines
    ├── Standalone probability engine
    └── Can actually be built at any point after Phase 1
```

**Key ordering rationale:**
1. Word games first because they are highest-value and lowest-risk (pure Swift, no external dependencies)
2. Minimax games second because they share a generic engine (build once, use four times)
3. Chess last among major features because Stockfish integration carries the most risk (C++ compilation, bridging, finding a maintained wrapper)
4. Sea Battle is standalone and can slot in wherever there is bandwidth

## Sources

- SwiftUI NavigationStack: Apple WWDC22 "The SwiftUI cookbook for navigation" (training knowledge, HIGH confidence)
- `@Observable` macro: Apple WWDC23 "Discover Observation in SwiftUI" (training knowledge, HIGH confidence)
- Minimax + alpha-beta pruning: Standard algorithm textbook knowledge (HIGH confidence)
- Trie data structure: Standard data structure knowledge (HIGH confidence)
- Stockfish UCI protocol: Universal Chess Interface specification (training knowledge, MEDIUM confidence -- specific iOS wrapper APIs not verified)
- iOS Process restrictions: Apple platform documentation -- `Process` is macOS-only, iOS apps must use compiled-in libraries (training knowledge, HIGH confidence)
- GamePigeon game rules: General knowledge of the games (HIGH confidence for mechanics, rules details should be verified during implementation)
