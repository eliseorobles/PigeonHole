import Foundation

final class Trie: @unchecked Sendable {
    let root = TrieNode()

    func insert(_ word: String) {
        var current = root
        for char in word.lowercased() {
            guard let idx = TrieNode.index(for: char) else { return }
            if current.children[idx] == nil {
                current.children[idx] = TrieNode()
            }
            current = current.children[idx]!
        }
        current.isWord = true
    }

    func search(_ word: String) -> Bool {
        guard let node = findNode(word.lowercased()) else { return false }
        return node.isWord
    }

    func startsWith(_ prefix: String) -> Bool {
        findNode(prefix.lowercased()) != nil
    }

    private func findNode(_ str: String) -> TrieNode? {
        var current = root
        for char in str {
            guard let idx = TrieNode.index(for: char) else { return nil }
            guard let child = current.children[idx] else { return nil }
            current = child
        }
        return current
    }
}
