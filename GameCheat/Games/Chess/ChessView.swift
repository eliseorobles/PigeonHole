import SwiftUI

struct ChessView: View {
    @State private var viewModel = ChessViewModel()
    private let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    private let rankLabelWidth: CGFloat = 18

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusSection
                boardSection
                controlsSection

                Text(viewModel.bestMoveLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Chess")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.sideToMoveLabel)
                .font(.headline)
            Text(viewModel.interactionHint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let selectedPieceLabel = viewModel.selectedPieceLabel {
                Text(selectedPieceLabel)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var boardSection: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let squareSize = (availableWidth - rankLabelWidth * 2 - 16) / 8

            VStack(spacing: 6) {
                fileLabelsRow(squareSize: squareSize)
                HStack(spacing: 8) {
                    rankLabelsColumn(squareSize: squareSize)
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<8, id: \.self) { col in
                                        squareButton(row: row, col: col, size: squareSize)
                                    }
                                }
                            }
                        }
                        .overlay(
                            Rectangle()
                                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                        )

                        bestMoveArrow(squareSize: squareSize)
                    }
                    rankLabelsColumn(squareSize: squareSize)
                }
                fileLabelsRow(squareSize: squareSize)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1.05, contentMode: .fit)
    }

    private var controlsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Skill: \(viewModel.skillLevel)")
                    .font(.caption.bold())
                Stepper("", value: $viewModel.skillLevel, in: 0...20)
                    .labelsHidden()

                Spacer()

                Button("Play Suggested Move") {
                    viewModel.applyBestMove()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.bestMove == nil || viewModel.isAnalyzing)
            }

            if viewModel.isAnalyzing {
                ProgressView("Analyzing...")
                    .font(.caption)
            }
        }
    }

    private func fileLabelsRow(squareSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: rankLabelWidth, height: 14)
            ForEach(files, id: \.self) { file in
                Text(file)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: squareSize, height: 14)
            }
            Color.clear
                .frame(width: rankLabelWidth, height: 14)
        }
    }

    private func rankLabelsColumn(squareSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach((1...8).reversed(), id: \.self) { rank in
                Text("\(rank)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: rankLabelWidth, height: squareSize)
            }
        }
    }

    private func squareButton(row: Int, col: Int, size: CGFloat) -> some View {
        let square = ChessSquare(row: row, col: col)

        return Button {
            viewModel.tap(square: square)
        } label: {
            ZStack {
                Rectangle()
                    .fill(squareColor(row: row, col: col, square: square))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.16), lineWidth: 0.4)
                    )

                if viewModel.isLegalTarget(square) {
                    legalTargetMarker(for: square)
                }

                if let piece = viewModel.piece(at: square) {
                    Text(piece.symbol)
                        .font(.system(size: size * 0.7))
                        .foregroundStyle(piece.color == .white ? Color.white : Color.black)
                        .shadow(
                            color: piece.color == .white ? Color.black.opacity(0.55) : Color.clear,
                            radius: 1,
                            x: 0,
                            y: 1
                        )
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func bestMoveArrow(squareSize: CGFloat) -> some View {
        if let move = viewModel.bestMove {
            let fromX = (CGFloat(move.from.col) + 0.5) * squareSize
            let fromY = (CGFloat(move.from.row) + 0.5) * squareSize
            let toX = (CGFloat(move.to.col) + 0.5) * squareSize
            let toY = (CGFloat(move.to.row) + 0.5) * squareSize
            let angle = atan2(toY - fromY, toX - fromX)
            let arrowLen: CGFloat = 12

            Path { path in
                path.move(to: CGPoint(x: fromX, y: fromY))
                path.addLine(to: CGPoint(x: toX, y: toY))
            }
            .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Path { path in
                path.move(to: CGPoint(x: toX, y: toY))
                path.addLine(to: CGPoint(
                    x: toX - arrowLen * cos(angle - .pi / 6),
                    y: toY - arrowLen * sin(angle - .pi / 6)
                ))
                path.move(to: CGPoint(x: toX, y: toY))
                path.addLine(to: CGPoint(
                    x: toX - arrowLen * cos(angle + .pi / 6),
                    y: toY - arrowLen * sin(angle + .pi / 6)
                ))
            }
            .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
    }

    @ViewBuilder
    private func legalTargetMarker(for square: ChessSquare) -> some View {
        if viewModel.piece(at: square) == nil {
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 10, height: 10)
        } else {
            Circle()
                .stroke(Color.red.opacity(0.8), lineWidth: 3)
                .padding(4)
        }
    }

    private func squareColor(row: Int, col: Int, square: ChessSquare) -> Color {
        if viewModel.isSelected(square) {
            return Color(red: 0.59, green: 0.78, blue: 0.47)
        }
        if viewModel.isLegalTarget(square) {
            return Color(red: 0.83, green: 0.89, blue: 0.95)
        }
        let isLight = (row + col).isMultiple(of: 2)
        return isLight
            ? Color(red: 0.95, green: 0.90, blue: 0.82)
            : Color(red: 0.73, green: 0.56, blue: 0.40)
    }
}
