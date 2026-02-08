import Testing
@testable import GameCheat

struct WordHuntSolverTests {
    @Test func findsWordsInKnownGrid() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        // Grid:
        // C A T S
        // D O G E
        // F I N D
        // H E L P
        let grid: [[Character]] = [
            ["C", "A", "T", "S"],
            ["D", "O", "G", "E"],
            ["F", "I", "N", "D"],
            ["H", "E", "L", "P"]
        ]

        let results = WordHuntSolver.solve(grid: grid, dictionary: dict)
        let words = Set(results.map(\.word))

        // Should find common words
        #expect(words.contains("cat"))
        #expect(words.contains("dog"))
        #expect(words.contains("find"))
    }

    @Test func pathsAreValid() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        let grid: [[Character]] = [
            ["C", "A", "T", "S"],
            ["D", "O", "G", "E"],
            ["F", "I", "N", "D"],
            ["H", "E", "L", "P"]
        ]

        let results = WordHuntSolver.solve(grid: grid, dictionary: dict)

        for result in results {
            // Path should have same length as word
            #expect(result.path.count == result.word.count)

            // Each consecutive pair should be adjacent
            for i in 1..<result.path.count {
                #expect(result.path[i - 1].isAdjacent(to: result.path[i]))
            }

            // No duplicate positions in path
            let uniquePositions = Set(result.path)
            #expect(uniquePositions.count == result.path.count)
        }
    }

    @Test func noDuplicateWords() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        let grid: [[Character]] = [
            ["A", "B", "C", "D"],
            ["E", "F", "G", "H"],
            ["I", "J", "K", "L"],
            ["M", "N", "O", "P"]
        ]

        let results = WordHuntSolver.solve(grid: grid, dictionary: dict)
        let words = results.map(\.word)
        let uniqueWords = Set(words)
        #expect(words.count == uniqueWords.count)
    }
}
