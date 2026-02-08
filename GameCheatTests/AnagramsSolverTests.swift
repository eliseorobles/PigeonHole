import Testing
@testable import GameCheat

struct AnagramsSolverTests {
    @Test func findsAnagramsForKnownLetters() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        let results = AnagramsSolver.solve(letters: "CATALOG", dictionary: dict)
        let words = Set(results.map(\.word))

        #expect(words.contains("cat"))
        #expect(words.contains("act"))
        #expect(words.contains("catalog"))
    }

    @Test func respectsMinLength() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        let results = AnagramsSolver.solve(letters: "CATALOG", dictionary: dict, minLength: 5)
        for result in results {
            #expect(result.word.count >= 5)
        }
    }

    @Test func noDuplicateWords() async {
        let dict = await loadDictionaryForTests()
        #expect(dict.isLoaded)

        let results = AnagramsSolver.solve(letters: "TESTING", dictionary: dict)
        let words = results.map(\.word)
        let unique = Set(words)
        #expect(words.count == unique.count)
    }
}
