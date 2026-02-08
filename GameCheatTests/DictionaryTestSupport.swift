import Foundation
@testable import GameCheat

func loadDictionaryForTests(timeout: TimeInterval = 5.0) async -> WordDictionary {
    let dict = WordDictionary.shared
    dict.load()

    let deadline = Date().addingTimeInterval(timeout)
    while !dict.isLoaded && Date() < deadline {
        try? await Task.sleep(for: .milliseconds(50))
    }

    return dict
}
