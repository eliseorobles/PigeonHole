import SwiftUI

struct SeaBattleView: View {
    @State private var viewModel = SeaBattleViewModel()
    @State private var marker: CellMarker = .miss
    private let cellSpacing: CGFloat = 3
    private let rowLabelWidth: CGFloat = 20
    private let columnLabels = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                markerSection
                gridSection
                legendSection
                shipsSection
                recommendationSection
            }
            .padding()
        }
        .navigationTitle("Sea Battle")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.resetGrid()
                }
            }
        }
    }

    private var markerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cell marker")
                .font(.subheadline.bold())

            Picker("Cell marker", selection: $marker) {
                ForEach(CellMarker.allCases) { marker in
                    Text(marker.rawValue).tag(marker)
                }
            }
            .pickerStyle(.segmented)

            Text(marker.helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var gridSection: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - 16
            let cellSize = (availableWidth - rowLabelWidth - cellSpacing * 9) / 10

            VStack(spacing: 6) {
                HStack(spacing: cellSpacing) {
                    Color.clear
                        .frame(width: rowLabelWidth, height: 12)
                    ForEach(columnLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize, height: 12)
                    }
                }

                ForEach(0..<10, id: \.self) { row in
                    HStack(spacing: cellSpacing) {
                        Text("\(row + 1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: rowLabelWidth, height: cellSize)

                        ForEach(0..<10, id: \.self) { col in
                            let pos = GridPosition(row: row, col: col)
                            let state = viewModel.grid[pos]
                            let probability = viewModel.probability(at: pos)
                            let isRecommended = viewModel.recommendedShot == pos

                            Button {
                                viewModel.setCellState(at: pos, to: marker.cellState)
                                AppTheme.impactLight()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(cellColor(for: state, probability: probability))

                                    if isRecommended, state == .empty {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.blue, lineWidth: 2)
                                            .opacity(pulseOpacity)
                                    }

                                    Text(cellLabel(for: state, isRecommended: isRecommended))
                                        .font(.system(size: max(cellSize * 0.4, 9), weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: cellSize, height: cellSize)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1.05, contentMode: .fit)
    }

    @State private var isPulsing = false

    private var pulseOpacity: Double {
        isPulsing ? 1.0 : 0.3
    }

    private var shipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remaining ships: \(viewModel.remainingShips.map(String.init).joined(separator: ", "))")
                .font(.subheadline)

            Text("Mark ship sunk after all of its cells are marked Hit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(availableShipSizes, id: \.self) { size in
                    Button("Mark \(size) sunk") {
                        viewModel.markSunkBySize(size)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canMarkSunk(shipSize: size))
                }
            }
        }
    }

    private var legendSection: some View {
        HStack(spacing: 8) {
            legendItem(color: .gray, text: "Miss")
            legendItem(color: .orange, text: "Hit")
            legendItem(color: .black, text: "Sunk")
            legendItem(color: Color(red: 0.9, green: 0.2, blue: 0.1), text: "High chance")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationSection: some View {
        Group {
            if let shot = viewModel.recommendedShot {
                Text("Recommended shot: \(coordinate(for: shot))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            } else {
                Text("No recommendation available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private var availableShipSizes: [Int] {
        Array(Set(viewModel.remainingShips)).sorted(by: >)
    }

    private func cellLabel(for state: CellState, isRecommended: Bool) -> String {
        switch state {
        case .empty:
            return isRecommended ? "X" : ""
        case .miss:
            return "M"
        case .hit:
            return "H"
        case .sunk:
            return "S"
        }
    }

    private func cellColor(for state: CellState, probability: Double) -> Color {
        switch state {
        case .miss:
            return .gray
        case .hit:
            return .orange
        case .sunk:
            return .black
        case .empty:
            let clamped = max(0.0, min(1.0, probability))
            if clamped < 0.5 {
                let t = clamped / 0.5
                return Color(
                    red: 0.55 + 0.35 * t,
                    green: 0.55 - 0.15 * t,
                    blue: 0.55 - 0.45 * t
                )
            } else {
                let t = (clamped - 0.5) / 0.5
                return Color(
                    red: 0.9 + 0.1 * t,
                    green: 0.4 - 0.2 * t,
                    blue: 0.1 - 0.05 * t
                )
            }
        }
    }

    private func coordinate(for pos: GridPosition) -> String {
        "\(columnLabels[pos.col])\(pos.row + 1)"
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(.systemGray6), in: Capsule())
    }
}

private enum CellMarker: String, CaseIterable, Identifiable {
    case clear = "Clear"
    case miss = "Miss"
    case hit = "Hit"

    var id: String { rawValue }

    var cellState: CellState {
        switch self {
        case .clear:
            return .empty
        case .miss:
            return .miss
        case .hit:
            return .hit
        }
    }

    var helpText: String {
        switch self {
        case .clear:
            return "Use Clear to remove a mark from a cell."
        case .miss:
            return "Use Miss when your shot did not hit a ship."
        case .hit:
            return "Use Hit when your shot struck a ship segment."
        }
    }
}
