import SwiftUI

@main
struct GameCheatApp: App {
    init() {
        WordDictionary.shared.load()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GamePickerView()
            }
        }
    }
}
