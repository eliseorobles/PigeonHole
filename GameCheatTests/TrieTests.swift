import Testing
@testable import GameCheat

struct TrieTests {
    @Test func insertAndSearchFindsWord() {
        let trie = Trie()
        trie.insert("hello")
        #expect(trie.search("hello") == true)
    }

    @Test func searchReturnsFalseForMissingWord() {
        let trie = Trie()
        trie.insert("hello")
        #expect(trie.search("world") == false)
    }

    @Test func searchReturnsFalseForPrefix() {
        let trie = Trie()
        trie.insert("hello")
        #expect(trie.search("hel") == false)
    }

    @Test func startsWithReturnsTrueForPrefix() {
        let trie = Trie()
        trie.insert("hello")
        #expect(trie.startsWith("hel") == true)
    }

    @Test func startsWithReturnsFalseForNonPrefix() {
        let trie = Trie()
        trie.insert("hello")
        #expect(trie.startsWith("abc") == false)
    }

    @Test func caseInsensitive() {
        let trie = Trie()
        trie.insert("Hello")
        #expect(trie.search("hello") == true)
        #expect(trie.search("HELLO") == true)
    }

    @Test func multipleWords() {
        let trie = Trie()
        trie.insert("cat")
        trie.insert("car")
        trie.insert("card")
        #expect(trie.search("cat") == true)
        #expect(trie.search("car") == true)
        #expect(trie.search("card") == true)
        #expect(trie.search("ca") == false)
        #expect(trie.startsWith("ca") == true)
    }
}
