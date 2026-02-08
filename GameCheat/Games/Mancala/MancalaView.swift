import SwiftUI

struct MancalaView: View {
    @State private var viewModel = MancalaViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(viewModel.statusText)
                    .font(.headline)

                boardSection
                controlsSection

                if let recommendedPit = viewModel.recommendedPit {
                    Text("Recommended pit: \(recommendedPit + 1)")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                if let analysis = viewModel.analysisSummary {
                    Text(analysis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Mancala")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
    }

    private var boardSection: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let storeWidth: CGFloat = 56
            let pitSpacing: CGFloat = 8
            let boardPadding: CGFloat = 10
            let pitsAreaWidth = availableWidth - storeWidth * 2 - boardPadding * 2 - 24
            let pitWidth = (pitsAreaWidth - pitSpacing * 5) / 6
            let pitHeight = pitWidth * 1.22

            HStack(spacing: 12) {
                storeView(player: .two, height: pitHeight * 2 + 10)

                VStack(spacing: 10) {
                    HStack(spacing: pitSpacing) {
                        ForEach((0..<6).reversed(), id: \.self) { relativePit in
                            pitButton(relativePit: relativePit, player: .two, width: pitWidth, height: pitHeight)
                        }
                    }

                    HStack(spacing: pitSpacing) {
                        ForEach(0..<6, id: \.self) { relativePit in
                            pitButton(relativePit: relativePit, player: .one, width: pitWidth, height: pitHeight)
                        }
                    }
                }

                storeView(player: .one, height: pitHeight * 2 + 10)
            }
            .padding(boardPadding)
            .background(Color.brown.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(2.8, contentMode: .fit)
    }

    private var controlsSection: some View {
        HStack(spacing: 12) {
            Stepper("Depth: \(viewModel.searchDepth)", value: $viewModel.searchDepth, in: 2...10)

            Spacer()

            Button {
                viewModel.solve()
            } label: {
                if viewModel.isSolving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Solve")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.state.isTerminal || viewModel.isSolving)
        }
    }

    private func pitButton(relativePit: Int, player: Player, width: CGFloat, height: CGFloat) -> some View {
        Button {
            viewModel.play(relativePit: relativePit)
            AppTheme.impactLight()
        } label: {
            VStack(spacing: 4) {
                Text("\(viewModel.stones(relativePit: relativePit, player: player))")
                    .font(.headline)
                    .contentTransition(.numericText())
                Text("P\(relativePit + 1)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: width, height: height)
            .background(
                pitBackground(relativePit: relativePit, player: player),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isPlayable(relativePit: relativePit, player: player))
    }

    private func storeView(player: Player, height: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(player == .one ? "P1" : "P2")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(viewModel.store(for: player))")
                .font(.title3.bold())
                .contentTransition(.numericText())
        }
        .frame(width: 56, height: height)
        .background(Color.brown.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }

    private func pitBackground(relativePit: Int, player: Player) -> Color {
        if viewModel.recommendedPit == relativePit, player == viewModel.state.currentPlayer {
            return Color.blue.opacity(0.3)
        }
        if viewModel.isPlayable(relativePit: relativePit, player: player) {
            return Color.brown.opacity(0.35)
        }
        return Color(.systemGray6)
    }
}
