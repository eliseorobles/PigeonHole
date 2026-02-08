import Foundation
import Observation

private final class WordDictionaryBundleLocator {}

@Observable
final class WordDictionary: @unchecked Sendable {
    static let shared = WordDictionary()

    private(set) var isLoaded = false
    private let trie = Trie()

    private init() {}

    func load() {
        guard !isLoaded else { return }
        Task.detached(priority: .userInitiated) { [self] in
            let words = Self.readWordList()
            if words.isEmpty {
                for word in Self.fallbackWords {
                    trie.insert(word)
                }
            } else {
                for word in words {
                    trie.insert(word)
                }
            }
            await MainActor.run {
                self.isLoaded = true
            }
        }
    }

    func isWord(_ word: String) -> Bool {
        trie.search(word)
    }

    func hasPrefix(_ prefix: String) -> Bool {
        trie.startsWith(prefix)
    }

    var trieRoot: TrieNode {
        trie.root
    }

    private static func readWordList() -> [String] {
        for bundle in candidateBundles {
            guard let url = bundle.url(forResource: "words", withExtension: "txt"),
                  let contents = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }

            let parsed = contents
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty && $0.count >= 3 && $0.count <= 16 }

            if !parsed.isEmpty {
                return parsed
            }
        }
        return []
    }

    private static var candidateBundles: [Bundle] {
        var bundles: [Bundle] = [
            Bundle.main,
            Bundle(for: WordDictionaryBundleLocator.self)
        ]
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        var seen = Set<URL>()
        return bundles.filter { bundle in
            let url = bundle.bundleURL
            if seen.contains(url) {
                return false
            }
            seen.insert(url)
            return true
        }
    }

    private static let fallbackWords: [String] = [
        "act", "cat", "dog", "find", "catalog", "testing", "test", "stone", "tones", "notes", "note"
    ]
}
