import Foundation
import Observation

@MainActor
@Observable
final class WordHuntViewModel {
    var letterInput: String = "" {
        didSet {
            let filtered = letterInput.uppercased().filter { $0.isLetter }
            if filtered != letterInput {
                letterInput = filtered
            }
            if letterInput.count > 16 {
                letterInput = String(letterInput.prefix(16))
            }
            if letterInput.count == 16, results.isEmpty, !isSearching {
                solve()
            }
        }
    }

    var results: [WordHuntResult] = []
    var selectedResult: WordHuntResult?
    var isSearching = false
    var minWordLength = 3
    var currentIndex = 0
    var sortByLength = true

    var grid: [[Character]] {
        let chars = Array(letterInput.uppercased())
        var g: [[Character]] = []
        for row in 0..<4 {
            var rowChars: [Character] = []
            for col in 0..<4 {
                let idx = row * 4 + col
                if idx < chars.count {
                    rowChars.append(chars[idx])
                } else {
                    rowChars.append(" ")
                }
            }
            g.append(rowChars)
        }
        return g
    }

    var filteredResults: [WordHuntResult] {
        let filtered = results.filter { $0.word.count >= minWordLength }
        if sortByLength {
            return filtered.sorted { a, b in
                if a.word.count != b.word.count {
                    return a.word.count < b.word.count
                }
                return a.word < b.word
            }
        } else {
            return filtered.sorted { a, b in
                if a.score != b.score {
                    return a.score > b.score
                }
                return a.word < b.word
            }
        }
    }

    var totalScore: Int {
        filteredResults.reduce(0) { $0 + $1.score }
    }

    var canSolve: Bool {
        letterInput.count == 16 && WordDictionary.shared.isLoaded && !isSearching
    }

    var currentResult: WordHuntResult? {
        guard !filteredResults.isEmpty, currentIndex >= 0, currentIndex < filteredResults.count else {
            return nil
        }
        return filteredResults[currentIndex]
    }

    func nextWord() {
        if currentIndex < filteredResults.count - 1 {
            currentIndex += 1
        }
    }

    func previousWord() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    func toggleSortOrder() {
        sortByLength.toggle()
        currentIndex = 0
    }

    func solve() {
        guard canSolve else { return }
        isSearching = true
        selectedResult = nil
        currentIndex = 0
        let currentGrid = grid
        let dictionary = WordDictionary.shared
        Task.detached(priority: .userInitiated) {
            let found = WordHuntSolver.solve(grid: currentGrid, dictionary: dictionary)
            await MainActor.run {
                self.results = found
                self.isSearching = false
            }
        }
    }

    func reset() {
        letterInput = ""
        results = []
        selectedResult = nil
        isSearching = false
        minWordLength = 3
        currentIndex = 0
        sortByLength = true
    }
}
