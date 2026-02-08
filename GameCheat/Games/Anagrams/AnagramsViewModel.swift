import Foundation
import Observation

@MainActor
@Observable
final class AnagramsViewModel {
    var letters: String = "" {
        didSet {
            let filtered = letters.uppercased().filter { $0.isLetter }
            if filtered != letters {
                letters = filtered
            }
        }
    }

    var results: [AnagramsResult] = []
    var isSolving = false
    var minLength = 3

    var filteredResults: [AnagramsResult] {
        results.filter { $0.word.count >= minLength }
    }

    var resultsByLength: [(length: Int, words: [AnagramsResult])] {
        Dictionary(grouping: filteredResults) { $0.word.count }
            .sorted { $0.key > $1.key }
            .map { (length: $0.key, words: $0.value.sorted { $0.word < $1.word }) }
    }

    var canSolve: Bool {
        letters.count >= 2 && WordDictionary.shared.isLoaded && !isSolving
    }

    func solve() {
        guard canSolve else { return }
        isSolving = true
        let inputLetters = letters
        let dictionary = WordDictionary.shared
        Task.detached(priority: .userInitiated) {
            let found = AnagramsSolver.solve(letters: inputLetters, dictionary: dictionary)
            await MainActor.run {
                self.results = found
                self.isSolving = false
                AppTheme.notificationSuccess()
            }
        }
    }

    func clear() {
        letters = ""
        results = []
        isSolving = false
        minLength = 3
    }
}
