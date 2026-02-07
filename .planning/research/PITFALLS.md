# Domain Pitfalls

**Domain:** iOS GamePigeon solver app (word games, board games, chess, battleship)
**Researched:** 2026-02-07
**Note:** WebSearch was unavailable during research. Findings are based on well-established domain knowledge. Confidence levels reflect this limitation.

---

## Critical Pitfalls

Mistakes that cause rewrites, App Store rejection, or fundamentally broken user experience.

---

### Pitfall 1: Naive Trie Consumes 500MB+ RAM with 270K Words

**What goes wrong:** A straightforward object-based trie (one Swift class/struct per node, each with a `[Character: TrieNode]` dictionary) for 270K words creates millions of node objects. Each node carries Swift object overhead (16+ bytes for class metadata), a Dictionary allocation (56+ bytes minimum even when empty), plus the character keys. Total memory easily reaches 300-600MB -- far beyond acceptable for a mobile app.

**Why it happens:** Developers prototype with the cleanest OOP trie implementation, it works fine with 1,000 test words, then they load the full dictionary and the app gets killed by the OS memory pressure watchdog (Jetsam) or becomes sluggish.

**Consequences:**
- App killed by iOS when memory exceeds ~1GB on older devices
- Slow launch (2-5 seconds just to build the trie)
- Background app gets evicted immediately, forcing full rebuild on return
- Users on iPhone SE / older iPads hit crashes

**Prevention:**
- **Use a compact trie representation.** Two best options:
  1. **Array-packed trie (recommended):** Store the trie as flat arrays -- one `[UInt8]` for labels, one `[UInt32]` for child offsets, one bitset for terminal flags. Pre-build at compile time, ship as a binary blob, and `mmap` it at runtime. Memory usage drops to ~3-8MB for 270K words. Loading is instant (just a file mapping, no parsing).
  2. **DAWG (Directed Acyclic Word Graph):** Merges shared suffixes, reducing node count by ~60-80%. More complex to build but extremely compact. Best if memory is the top concern.
- **Build the binary representation offline** (a build-time script), not at runtime. Ship the pre-compiled binary file in the app bundle.
- **Memory-map the file** using `Data(contentsOf:url, options: .mappedIfSafe)` or `mmap()`. This means the OS loads pages on demand and can evict them under memory pressure without killing your app.
- **Never load a text file and parse it into objects at runtime** for a production word list of this size.

**Warning signs:**
- Memory usage above 50MB after dictionary load (check Xcode Memory Gauge)
- App launch takes more than 0.5 seconds
- App gets killed when returning from background
- Instruments shows millions of small allocations during launch

**Detection:** Profile with Instruments Allocations tool on the oldest supported device.

**Confidence:** HIGH -- this is extremely well-documented across word game development communities. The object-overhead math is deterministic.

**Phase:** Must be solved in Phase 1 (Word Engine). Getting this wrong poisons every word game feature.

---

### Pitfall 2: Gomoku Minimax Explodes Without Aggressive Pruning

**What goes wrong:** Gomoku is played on a 15x15 board (225 intersections). A naive minimax considers all empty positions as legal moves. At depth 4, that is 225 * 224 * 223 * 222 = ~2.5 billion nodes. Even at depth 2, it is 225 * 224 = ~50,000 nodes per move -- and each node requires board evaluation. Alpha-beta pruning alone is not sufficient because the branching factor is too high.

**Why it happens:** Developers build minimax for Connect Four (7 columns, branching factor 7) and Checkers (branching factor ~8), see it works great at depth 8+, and assume the same engine scales to Gomoku. It does not. Gomoku's branching factor is 10-30x higher.

**Consequences:**
- Move computation takes 30+ seconds (unacceptable UX)
- App appears frozen, user kills it
- Reducing depth to compensate produces terrible moves (depth 2 Gomoku plays like a toddler)
- Fallback: developers try to add a time limit but get inconsistent move quality

**Prevention:**
- **Candidate move reduction (mandatory):** Only consider moves within 2 cells of existing stones. On a typical mid-game board, this reduces branching factor from 200+ to 15-30. This single optimization is the difference between "works" and "doesn't work."
- **Move ordering:** Evaluate candidate moves with a cheap heuristic first, sort best-first. Alpha-beta pruning's efficiency depends entirely on move ordering -- perfect ordering makes alpha-beta O(b^(d/2)) instead of O(b^d).
- **Iterative deepening:** Search depth 1, then 2, then 3... Stop when time runs out. Return the best move from the deepest completed search. This gives consistent response times regardless of position complexity.
- **Threat-space search:** For Gomoku specifically, detect forcing sequences (threats that must be answered) and search those deeply while cutting non-forcing branches.
- **Transposition table:** Cache evaluated positions using Zobrist hashing. Gomoku has many transpositions (A then B = B then A).
- **Set a time budget** (e.g., 2 seconds max), not a depth limit.

**Warning signs:**
- Any move taking more than 3 seconds on a modern iPhone
- Search depth below 4 produces weak play
- Profiler shows most time in move generation, not evaluation

**Detection:** Test with mid-game positions (30+ stones placed) at various depths. Measure wall-clock time.

**Confidence:** HIGH -- minimax scaling with branching factor is mathematical fact. Gomoku-specific pruning is standard in game AI literature.

**Phase:** Must be designed in the board game engine phase. The generic minimax engine must support pluggable candidate move generation (not just "all legal moves"), or Gomoku will be unusable.

---

### Pitfall 3: Stockfish iOS Integration is a Build System Nightmare

**What goes wrong:** Stockfish is a large C++17 codebase (~30 files, heavy use of templates, intrinsics, and platform-specific SIMD). Getting it to compile for iOS (arm64) with the right flags, link correctly with Swift, and run without violating App Store rules requires significant build system work that is poorly documented.

**Why it happens:** Stockfish is designed for desktop (Linux/macOS/Windows CLI). iOS is a secondary target. The build system assumes `make` and g++/clang CLI, not Xcode. Additionally, Stockfish uses NNUE evaluation (a neural network), which requires a ~40MB binary weights file that must be embedded correctly.

**Consequences:**
- Days lost fighting compiler errors (C++17 features, missing POSIX APIs on iOS)
- NNUE weights file not found at runtime -- engine crashes or falls back to classical evaluation (much weaker play)
- App binary bloats by 40-60MB from NNUE weights
- Threading model conflicts with iOS (Stockfish spawns pthreads)
- App Store rejection if Stockfish tries to use disallowed APIs

**Prevention:**
- **Use an existing iOS-compatible Stockfish wrapper.** Search for `chesskit-swift`, `stockfish-ios`, or similar packages on GitHub. Several community projects maintain Xcode-compatible builds. Do NOT try to integrate raw Stockfish source yourself.
- **If wrapping manually:**
  - Compile Stockfish as a static library (`.a`) for arm64
  - Use an Objective-C++ bridging layer (`.mm` files) between Swift and C++
  - Embed the NNUE file (`nn-*.nnue`) in the app bundle and pass its path to Stockfish at initialization
  - Disable `POSIX` thread affinity calls (not available on iOS)
  - Strip x86 / desktop-only code paths
- **Pin a specific Stockfish version** (e.g., Stockfish 16). Do not track `master` -- breaking changes are frequent.
- **NNUE weights:** Include the weights file in the Xcode target's "Copy Bundle Resources" phase. At runtime, resolve via `Bundle.main.path(forResource:ofType:)`. Test that this path is correct on a real device, not just simulator.
- **Threading:** Stockfish defaults to using all available CPU cores. On iOS, cap threads to 1-2. More threads drain battery and trigger thermal throttling. Set via UCI option `Threads`.

**Warning signs:**
- Build errors mentioning `aligned_alloc`, `posix_memalign`, or `pthread_setaffinity_np`
- Engine returns garbage moves or crashes on real device but works on simulator
- NNUE file not found logs in console
- App binary exceeds 100MB before App Store thinning

**Detection:** Build and run on a real device (not simulator) early. Simulator uses x86/Rosetta and masks arm64-specific issues.

**Confidence:** MEDIUM -- well-known problems in chess programming communities, but specific Swift wrapper availability as of 2026 needs verification. The underlying technical issues are certain.

**Phase:** Chess integration phase. Do a spike/proof-of-concept EARLY (before building the chess UI) to validate the build works. If the wrapper doesn't exist or doesn't work, the fallback is significant effort.

---

### Pitfall 4: App Store Rejection for "Cheat" Framing

**What goes wrong:** Apple rejects the app during review for violating App Store Review Guidelines, specifically:
- **Guideline 1.1.6** (false information / misleading)
- **Guideline 4.0** (design -- minimum functionality)
- **Guideline 3.1.2(a)** if it references another app's trademarks

The app name "GameCheat" or any description mentioning "cheat" is a red flag. Mentioning "GamePigeon" by name in the App Store listing invokes trademark concerns.

**Why it happens:** Developers build the app, submit it with an honest name like "GamePigeon Cheat" or "Word Hunt Cheat Tool", and get rejected. Then they rename it but the description still says "cheat at games" and get rejected again. The review process is opaque -- you often don't know exactly which guideline you violated until the rejection email.

**Consequences:**
- Rejection delays launch by 1-2 weeks per attempt
- Repeated rejections may trigger extended review (all future submissions manually reviewed)
- Account standing affected after 3+ rejections
- Worst case: app permanently banned, developer account at risk

**Prevention:**
- **Never use "cheat" in the app name, subtitle, keywords, or description.** Use terms like "helper", "companion", "solver", "assistant", "strategy guide", "word finder", "game toolkit".
- **Never mention "GamePigeon" by name** in the App Store listing (title, subtitle, description, keywords). This is someone else's trademark. You can say "iMessage games" or "popular word and board games" generically.
- **Frame the app as a learning/strategy tool**, not a cheating tool. Example: "Improve your word game vocabulary" or "Learn optimal board game strategies."
- **Include standalone value.** If the app ONLY works as a cheat for another app, Apple may reject for "limited functionality" or "not useful on its own." Add value framing: dictionary explorer, strategy trainer, word learning tool.
- **Screenshots must not show iMessage or GamePigeon UI.** Show only your app's interface.
- **Prepare for reviewer questions.** Have a demo account or clear instructions showing the app works standalone without requiring GamePigeon installed.
- **Use App Review notes** (the text field during submission) to preemptively explain: "This is a word game solver and strategy tool. It works standalone and does not require any other app."

**Warning signs:**
- Any marketing copy containing the word "cheat"
- App Store listing that references a specific third-party app by name
- Screenshots showing another app's interface
- App description that implies the sole purpose is to gain unfair advantage

**Detection:** Before submission, have someone unfamiliar with the project read the listing and ask "Does this sound like a cheating tool?" If yes, rewrite.

**Confidence:** HIGH -- App Store Review Guidelines are public and well-documented. Trademark-related rejections are extensively reported in developer communities.

**Phase:** Must be decided before Phase 1 even starts (app naming, project structure). But the real gate is the submission phase. Prepare marketing copy during development, not the night before submission.

---

### Pitfall 5: Dictionary Mismatch -- Solver Finds Words GamePigeon Doesn't Accept

**What goes wrong:** The app uses TWL06 (or SOWPODS, or another standard word list), but GamePigeon uses its own internal dictionary. The solver finds words that GamePigeon marks invalid, or misses words that GamePigeon accepts. Users try the suggested words, they get rejected in-game, and the app feels broken.

**Why it happens:** There is no public documentation of which dictionary GamePigeon uses. Standard word lists differ significantly -- TWL06 has ~178K words, SOWPODS has ~267K, and various "common English" lists differ in their inclusion of proper nouns, abbreviations, slang, and archaic words.

**Consequences:**
- Users lose trust after 2-3 failed word suggestions
- False positives (suggesting invalid words) are worse than false negatives (missing valid words)
- User complaints and low ratings
- No easy fix without reverse-engineering GamePigeon's dictionary

**Prevention:**
- **Acknowledge this limitation upfront in the app UI.** A small note: "Word list may differ slightly from game dictionary. Most common words are covered."
- **Use a broadly inclusive dictionary** (like SOWPODS/Collins) rather than a restrictive one. False negatives (missing a valid word) are less frustrating than false positives (suggesting an invalid word). However, a too-broad list produces more false positives.
- **Empirical testing:** Play games with the solver, note which words are accepted/rejected, and build a correction list over time.
- **Allow users to report invalid words** with a simple thumbs-down or "word not accepted" button. Store this data to improve the word list in updates.
- **Sort results by word commonality/length**, not just alphabetically. Common words are more likely to be in any dictionary. This naturally pushes reliable suggestions to the top.
- **Consider maintaining a small exclusion list** of known false positives discovered through testing.

**Warning signs:**
- No testing of solver output against actual GamePigeon games
- Using a very obscure word list (too many archaic or technical words)
- Zero user feedback mechanism for word validity

**Detection:** Before launch, play 20+ real Word Hunt games using the solver. Track acceptance rate. Target 95%+.

**Confidence:** HIGH -- dictionary mismatch is the most commonly reported issue in word game solver reviews on the App Store.

**Phase:** Word engine phase. The dictionary choice and feedback mechanism should be designed early. The correction list grows post-launch.

---

## Moderate Pitfalls

---

### Pitfall 6: Trie Loading Blocks App Launch

**What goes wrong:** The trie/dictionary is loaded synchronously on the main thread during app launch. With a text-based dictionary, parsing 270K lines takes 1-3 seconds. The app appears frozen with a blank screen, and if it exceeds 20 seconds, the iOS watchdog kills it (SIGKILL, `0x8badf00d`).

**Prevention:**
- **Pre-compile the trie to a binary format** (see Pitfall 1). An `mmap`-ed binary file loads in <1ms.
- **If using text parsing, do it on a background thread.** Show the game picker immediately; load the dictionary when the user navigates to a word game. Use `Task { }` (Swift concurrency) to load off the main actor.
- **Lazy loading:** Only build the trie when the user first opens a word game, not at app launch. Cache the built trie in memory for subsequent uses.

**Warning signs:**
- App takes more than 0.3 seconds to show first screen
- `Time Profiler` shows dictionary loading on the main thread
- Launch time exceeds 1 second on the oldest supported device

**Confidence:** HIGH

**Phase:** Phase 1 (Word Engine). This is a direct consequence of dictionary format decisions.

---

### Pitfall 7: Minimax Evaluation Function is Too Expensive

**What goes wrong:** The board evaluation function (called at every leaf node of the search tree) does expensive work like scanning the entire board for patterns, computing threat counts, or allocating memory. Since evaluation is called thousands to millions of times per move, even small inefficiencies multiply catastrophically.

**Prevention:**
- **Incremental evaluation:** Update the score when a move is made/unmade, rather than recomputing from scratch. Maintain running score deltas.
- **Avoid allocations in the hot path.** No `Array.append`, no string operations, no object creation inside the evaluation function. Use pre-allocated buffers.
- **Profile the evaluation function in isolation.** It should take <1 microsecond per call. If it takes 10us, your depth-6 search that evaluates 500K nodes will take 5 seconds instead of 0.5 seconds.
- **Use bitboards where appropriate** (especially for Connect Four and Gomoku line detection). Bitwise operations are orders of magnitude faster than loop-based pattern scanning.

**Warning signs:**
- Time Profiler shows >50% of CPU time in the evaluation function
- Board evaluation allocates memory (visible in Instruments Allocations)
- Move computation time scales worse than expected with depth

**Confidence:** HIGH

**Phase:** Board game engine phase. The evaluation function interface must be designed for incremental updates from the start.

---

### Pitfall 8: Sea Battle Probability Engine Doesn't Account for Ship Constraints Properly

**What goes wrong:** A naive probability heatmap for Battleship/Sea Battle places ships randomly and counts how often each cell is occupied. But it fails to account for:
1. Already-sunk ships (must remove from remaining ship list)
2. Hit cells that must be part of an unsunk ship (constraint propagation)
3. Adjacent-cell rules (some variants don't allow ships to touch)
4. The transition from "hunt mode" (random searching) to "target mode" (following up a hit) is implemented incorrectly, missing edge cases like multiple unsunk ships with overlapping search areas.

**Prevention:**
- **Track game state carefully:** Maintain a list of remaining (unsunk) ships. When a ship is fully sunk, remove it from the probability calculation.
- **Constraint-based enumeration:** For each remaining ship, enumerate all valid placements given known hits, misses, and sinks. Count placements per cell. This naturally handles constraints.
- **Target mode logic:** When a hit is registered but the ship isn't sunk, adjacent cells get massive probability boosts. When two hits are collinear, only cells along that line should be boosted (the ship's orientation is determined).
- **Handle edge cases:** What if two unsunk ships are adjacent? What if a hit could belong to either of two ships? The probability engine must handle ambiguity.
- **Test with known configurations.** Set up a board where you know the answer and verify the heatmap highlights the right cells.

**Warning signs:**
- Heatmap suggests cells adjacent to already-sunk ships
- After a hit, probability doesn't spike on adjacent cells
- Probability doesn't account for remaining ship sizes

**Confidence:** HIGH -- Battleship probability algorithms are well-studied. The math is straightforward but the state management has many edge cases.

**Phase:** Sea Battle engine phase. The state model (remaining ships, hit/miss/sunk tracking) is the core design challenge.

---

### Pitfall 9: SwiftUI Grid Performance with Complex Board States

**What goes wrong:** Board game UIs (especially the 15x15 Gomoku grid or 10x10 Sea Battle grid) use SwiftUI `LazyVGrid` or nested `ForEach`. When the board state changes (after computing a move), SwiftUI re-renders the entire grid. With 100-225 cells, each containing tap handlers, conditional styling, and possibly animations, the UI stutters noticeably.

**Prevention:**
- **Use `Equatable` conformance on cell views** and apply `.equatable()` modifier so SwiftUI skips cells that haven't changed.
- **Avoid re-creating cell views on every state change.** Use `@State` or `@Binding` at the cell level, not a single `@Published` board array that invalidates everything.
- **For grids >100 cells, consider `Canvas` rendering** instead of SwiftUI views. `Canvas` draws directly with Core Graphics -- no view diffing overhead. Overlay a transparent grid of tap targets on top.
- **Profile with SwiftUI Instruments** to identify unnecessary view updates.

**Warning signs:**
- Visible stutter when placing a piece or revealing a cell
- Xcode SwiftUI preview is slow to render the board
- `View body` called for all 225 cells when only 1 changed

**Confidence:** MEDIUM -- SwiftUI performance characteristics vary by iOS version. iOS 17+ has significant improvements over earlier versions, but large grids remain a known pain point.

**Phase:** UI implementation phase. Choose the rendering approach (SwiftUI views vs Canvas) early for board games.

---

### Pitfall 10: Word Hunt Path-Finding Returns Invalid Swipe Paths

**What goes wrong:** The solver finds valid words in the 4x4 grid but the paths it returns are not valid swipe paths. In Word Hunt, you can only swipe to adjacent cells (including diagonals), and you cannot revisit a cell in the same word. A DFS that doesn't enforce these constraints will return words that exist in the grid but can't actually be swiped.

**Prevention:**
- **DFS must track visited cells per path** (not globally). Use a bitmask (16 bits for 4x4 grid) for O(1) visited checks.
- **Adjacency must be strictly enforced.** Two cells are adjacent if they differ by at most 1 in both row and column. Precompute the adjacency list for all 16 cells.
- **Return the actual path (sequence of cell coordinates), not just the word.** Users need to know which cells to swipe and in what order.
- **Handle duplicate letters correctly.** If the grid has two 'E' cells, the solver may find the same word via different paths. Deduplicate by word string but keep the shortest/first path found.

**Warning signs:**
- Solver suggests a word but user can't find the swipe path
- Same word appears multiple times in results
- Words include non-adjacent cell transitions

**Confidence:** HIGH

**Phase:** Phase 1 (Word Hunt). This is the core algorithm and must be correct from day one. Word Hunt is the highest-value feature.

---

### Pitfall 11: Stockfish UCI Protocol Mishandling

**What goes wrong:** Stockfish communicates via the UCI (Universal Chess Interface) text protocol. The app sends a position and `go` command, then must parse the multi-line response correctly. Common mistakes:
- Not waiting for `bestmove` line before parsing (reading partial output)
- Not sending `isready` / waiting for `readyok` before sending positions
- Forgetting to send `ucinewgame` between games (engine's internal state leaks)
- Sending positions in incorrect FEN format (wrong castling rights, en passant square)

**Prevention:**
- **Use or study an existing UCI wrapper** rather than implementing the protocol from scratch. The protocol has subtle timing requirements.
- **Always follow the sequence:** `uci` -> wait for `uciok` -> set options -> `isready` -> wait for `readyok` -> `position` -> `go` -> wait for `bestmove`
- **Parse Stockfish output line by line**, looking for specific prefixes (`bestmove`, `info depth`, etc.). Do not assume fixed output format.
- **Implement timeout handling.** If `bestmove` doesn't arrive within N seconds, something is wrong -- don't hang forever.
- **FEN validation:** Validate FEN strings before sending to Stockfish. An invalid FEN can crash the engine or produce nonsense moves.

**Warning signs:**
- Engine occasionally returns wrong moves or hangs
- Inconsistent behavior between games
- Position after move doesn't match expected board state

**Confidence:** HIGH -- UCI protocol issues are the most common problem in chess engine integration.

**Phase:** Chess integration phase. Get UCI communication working with a test harness before building UI.

---

## Minor Pitfalls

---

### Pitfall 12: Mancala Rule Variations

**What goes wrong:** Mancala has dozens of regional rule variants (Kalah, Oware, Bao, etc.). GamePigeon uses a specific variant that may differ from what the developer implements. If capture rules, store-sowing rules, or end-game rules differ, the engine plays optimally for the wrong game.

**Prevention:**
- **Identify the exact GamePigeon Mancala variant** through gameplay testing before implementing. Key questions: Can you sow into the opponent's store? What happens when you land in your own store (extra turn)? What is the capture rule (landing in empty own pit captures opposite)?
- **Parameterize rules** so variant differences are configuration, not code changes.

**Warning signs:** Engine suggests moves that produce different outcomes than in the actual game.

**Confidence:** HIGH

**Phase:** Board game engine phase. Test rule parity before building the full engine.

---

### Pitfall 13: Checkers King/Multi-Jump Rules

**What goes wrong:** Similar to Mancala, Checkers has variant rules. Key differences: Can kings fly (move unlimited squares diagonally)? Is capturing mandatory? Can you choose which multi-jump path to take, or must you take the path that captures the most pieces? GamePigeon likely uses American Checkers (8x8, kings move one square, mandatory capture, but not necessarily maximum capture).

**Prevention:**
- **Test the exact variant** in GamePigeon before implementing.
- **Mandatory capture logic** is the most commonly botched rule. The engine must generate ONLY capture moves when captures are available, and must chain multi-jumps correctly.

**Warning signs:** Engine suggests non-capture moves when captures are available.

**Confidence:** HIGH

**Phase:** Board game engine phase.

---

### Pitfall 14: Excessive App Binary Size

**What goes wrong:** Between the dictionary file (~3-5MB as text, potentially much more as naive trie), Stockfish NNUE weights (~40MB), and the Stockfish engine binary itself (~5-10MB), the app can easily exceed 100MB before any app assets. Apple warns users before downloading apps over 200MB on cellular, which reduces downloads.

**Prevention:**
- **Compact dictionary format** (see Pitfall 1). Binary packed trie: ~5-8MB.
- **Consider Stockfish without NNUE** (classical evaluation only) for smaller binary. Tradeoff: significantly weaker play (roughly 300 Elo weaker). Alternative: use a smaller NNUE net if available.
- **Use Asset Catalogs with On-Demand Resources** for the Stockfish engine. Users who don't play Chess never download it. This requires iOS ODR API integration but can cut initial download size by 50MB.
- **App Thinning** handles architecture slicing automatically, but test the final binary size for arm64.

**Warning signs:**
- IPA exceeds 100MB before App Store processing
- Archive build size report shows large embedded resources

**Confidence:** MEDIUM -- NNUE file sizes and ODR specifics should be verified against current Stockfish versions.

**Phase:** Pre-submission / optimization phase. But architectural decisions (ODR vs bundled) should be made during the Chess integration phase.

---

### Pitfall 15: Not Testing on Older Supported Devices

**What goes wrong:** The app works fine on iPhone 15 Pro but crashes or crawls on iPhone SE 3rd gen (A15, 4GB RAM) or other lower-end devices that still run iOS 17. The minimax engine is particularly sensitive to device performance -- a search that takes 1 second on A17 Pro takes 3+ seconds on A13.

**Prevention:**
- **Test on the lowest-spec device that runs iOS 17.** iPhone SE 3rd gen (A15 Bionic, 4GB RAM) or iPhone X/8 if targeting iOS 17 (though these may not support iOS 17 -- verify).
- **Set time budgets, not depth budgets** for minimax. The engine adapts to device speed automatically.
- **Memory budget: stay under 100MB total app memory** to avoid Jetsam kills on low-memory devices.

**Warning signs:**
- Only testing on Simulator or latest-gen device
- No performance measurements on real devices

**Confidence:** HIGH

**Phase:** Every phase. Test on a real device from Phase 1.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation | Severity |
|-------------|---------------|------------|----------|
| Word Engine (Trie) | Memory explosion (P1), slow loading (P6), invalid paths (P10) | Binary packed trie, mmap, bitmask DFS | Critical |
| Word Engine (Dictionary) | Dictionary mismatch (P5) | Inclusive word list + user feedback mechanism | Critical |
| Board Game Engine (Generic) | Evaluation too expensive (P7) | Design for incremental evaluation from start | Moderate |
| Board Game Engine (Gomoku) | Search space explosion (P2) | Candidate move reduction mandatory | Critical |
| Board Game Engine (Checkers) | Rule variant mismatch (P13) | Test against GamePigeon before implementing | Moderate |
| Board Game Engine (Mancala) | Rule variant mismatch (P12) | Test against GamePigeon before implementing | Moderate |
| Chess (Stockfish) | Build system nightmare (P3), UCI mishandling (P11) | Use existing wrapper, spike early | Critical |
| Sea Battle | Probability engine bugs (P8) | Constraint-based enumeration, thorough testing | Moderate |
| UI (Board Games) | Grid performance (P9) | Choose Canvas vs Views early, profile | Moderate |
| App Submission | "Cheat" framing rejection (P4) | Careful naming/positioning from day one | Critical |
| Binary Size | Bloated IPA (P14) | ODR for Stockfish, compact dictionary | Minor |
| Cross-cutting | Older device crashes (P15) | Test on real low-end device throughout | Moderate |

---

## Pitfall Priority Matrix

**Must address before writing code:**
1. Dictionary format decision (P1 + P6) -- determines the entire word engine architecture
2. App naming and framing (P4) -- determines project identity and marketing
3. Minimax candidate move interface (P2) -- determines engine API design
4. Stockfish integration spike (P3) -- determines if Chess feature is feasible at planned effort

**Must address during implementation:**
5. Word Hunt path validation (P10)
6. Dictionary accuracy testing (P5)
7. Evaluation function performance (P7)
8. Sea Battle state management (P8)
9. UCI protocol correctness (P11)
10. Game rule variant verification (P12, P13)

**Must address before submission:**
11. Binary size optimization (P14)
12. Real device testing (P15)
13. App Store listing review (P4 -- final check)

---

## Sources

- Training data knowledge of trie data structures, game tree search, and iOS development patterns
- App Store Review Guidelines (publicly available at developer.apple.com/app-store/review/guidelines/)
- Stockfish documentation (stockfishchess.org)
- UCI protocol specification
- Battleship probability algorithms (well-studied in combinatorial game theory)

**Note:** WebSearch was unavailable during this research session. Key areas that should be verified with live sources:
- Current state of Stockfish iOS Swift wrappers (packages available on GitHub/SPM as of 2026)
- Current App Store review strictness around game helper/solver apps
- Stockfish NNUE file size in latest version
- iOS 17 minimum device compatibility list
