import SwiftUI

struct GamePickerView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(GameType.allCases) { game in
                    NavigationLink(value: game) {
                        GameCardView(game: game)
                    }
                    .disabled(!game.isAvailable)
                }
            }
            .padding()
        }
        .navigationTitle("GameCheat")
        .navigationDestination(for: GameType.self) { game in
            destinationView(for: game)
        }
    }

    @ViewBuilder
    private func destinationView(for game: GameType) -> some View {
        switch game {
        case .wordHunt:
            WordHuntView()
        case .anagrams:
            AnagramsView()
        case .fourInARow:
            FourInARowView()
        case .mancala:
            MancalaView()
        case .chess:
            ChessView()
        case .seaBattle:
            SeaBattleView()
        }
    }
}

struct GameCardView: View {
    let game: GameType

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: game.iconName)
                .font(.system(size: 36))
                .foregroundStyle(game.isAvailable ? .blue : .gray)

            Text(game.displayName)
                .font(.headline)
                .foregroundStyle(game.isAvailable ? .primary : .secondary)

            Text(game.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !game.isAvailable {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.gray.opacity(0.2), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(game.isAvailable ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
