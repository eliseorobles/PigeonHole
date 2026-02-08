import SwiftUI

struct FourInARowView: View {
    @State private var viewModel = FourInARowViewModel()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: FourInARowState.columns)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                controlsSection
                dropButtonsSection
                boardSection
                if let analysis = viewModel.analysisSummary {
                    Text(analysis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Four in a Row")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            if let winnerText = viewModel.winnerText {
                Text(winnerText)
                    .font(.title3.bold())
            } else {
                Text("\(viewModel.currentPlayerName) to move")
                    .font(.headline)
            }

            if let column = viewModel.recommendedColumn {
                Text("Recommended: Column \(column + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 12) {
            Stepper("Depth: \(viewModel.searchDepth)", value: $viewModel.searchDepth, in: 2...8)

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
            .disabled(!viewModel.canPlay)
        }
    }

    private var dropButtonsSection: some View {
        GeometryReader { geo in
            let buttonWidth = (geo.size.width - CGFloat(FourInARowState.columns - 1) * 4) / CGFloat(FourInARowState.columns)

            HStack(spacing: 4) {
                ForEach(0..<FourInARowState.columns, id: \.self) { column in
                    Button {
                        viewModel.drop(in: column)
                        AppTheme.impactMedium()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                            .frame(width: buttonWidth, height: 32)
                            .background(
                                viewModel.recommendedColumn == column
                                    ? Color.blue.opacity(0.25)
                                    : Color(.systemGray5),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canPlay || !viewModel.state.generateMoves().contains(column))
                }
            }
        }
        .frame(height: 32)
    }

    private var boardSection: some View {
        GeometryReader { geo in
            let circleSize = (geo.size.width - CGFloat(FourInARowState.columns - 1) * 4 - 16) / CGFloat(FourInARowState.columns)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<FourInARowState.rows, id: \.self) { row in
                    ForEach(0..<FourInARowState.columns, id: \.self) { col in
                        Circle()
                            .fill(cellColor(row: row, col: col))
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .frame(height: circleSize)
                    }
                }
            }
            .padding(8)
            .background(Color.blue.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(CGFloat(FourInARowState.columns) / CGFloat(FourInARowState.rows), contentMode: .fit)
    }

    private func cellColor(row: Int, col: Int) -> Color {
        switch viewModel.board[row][col] {
        case .one:
            return .red
        case .two:
            return .yellow
        case .none:
            return Color(.systemGray6)
        }
    }
}
