import SwiftUI

struct WordHuntView: View {
    @State private var viewModel = WordHuntViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                letterInputSection
                gridSection
                solveButton
                if !viewModel.results.isEmpty {
                    navigationBar
                    resultsSection
                }
            }
            .padding()
        }
        .navigationTitle("Word Hunt")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Letter Input

    private var letterInputSection: some View {
        VStack(spacing: 8) {
            TextField("Enter 16 letters (e.g., ABCDEFGHIJKLMNOP)", text: $viewModel.letterInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isInputFocused)

            Text("\(viewModel.letterInput.count)/16 letters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Grid Display

    private var gridSection: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                GridRow {
                    ForEach(0..<4, id: \.self) { col in
                        gridCell(row: row, col: col)
                    }
                }
            }
        }
        .overlay {
            if viewModel.selectedResult != nil {
                pathOverlay
            }
        }
        .padding(8)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
    }

    private func gridCell(row: Int, col: Int) -> some View {
        let pos = GridPosition(row: row, col: col)
        let isInPath = viewModel.currentResult?.path.contains(pos) ?? false
        let pathIndex = viewModel.currentResult?.path.firstIndex(of: pos)

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isInPath ? Color.yellow.opacity(0.4) : Color(.systemGray6))

            if isInPath, let idx = pathIndex {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)

                Text("\(idx + 1)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
            }

            Text(String(viewModel.grid[row][col]))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
        }
        .frame(minHeight: 60)
    }

    // MARK: - Path Overlay

    private var pathOverlay: some View {
        GeometryReader { geo in
            if let result = viewModel.currentResult, result.path.count >= 2 {
                let cellW = geo.size.width / 4
                let cellH = geo.size.height / 4

                Path { path in
                    for (i, pos) in result.path.enumerated() {
                        let x = (CGFloat(pos.col) + 0.5) * cellW
                        let y = (CGFloat(pos.row) + 0.5) * cellH
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Arrow at end
                if let last = result.path.last, result.path.count >= 2 {
                    let prev = result.path[result.path.count - 2]
                    let endX = (CGFloat(last.col) + 0.5) * cellW
                    let endY = (CGFloat(last.row) + 0.5) * cellH
                    let prevX = (CGFloat(prev.col) + 0.5) * cellW
                    let prevY = (CGFloat(prev.row) + 0.5) * cellH
                    let angle = atan2(endY - prevY, endX - prevX)
                    let arrowLen: CGFloat = 10

                    Path { path in
                        path.move(to: CGPoint(x: endX, y: endY))
                        path.addLine(to: CGPoint(
                            x: endX - arrowLen * cos(angle - .pi / 6),
                            y: endY - arrowLen * sin(angle - .pi / 6)
                        ))
                        path.move(to: CGPoint(x: endX, y: endY))
                        path.addLine(to: CGPoint(
                            x: endX - arrowLen * cos(angle + .pi / 6),
                            y: endY - arrowLen * sin(angle + .pi / 6)
                        ))
                    }
                    .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Solve Button

    private var solveButton: some View {
        Button {
            viewModel.solve()
        } label: {
            HStack {
                if viewModel.isSearching {
                    ProgressView()
                        .tint(.white)
                }
                Text(viewModel.isSearching ? "Searching..." : "Solve")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .disabled(!viewModel.canSolve)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button {
                viewModel.previousWord()
                AppTheme.impactLight()
            } label: {
                Image(systemName: "chevron.left")
                Text("Prev")
            }
            .disabled(viewModel.currentIndex <= 0)

            Spacer()

            Text("\(viewModel.currentIndex + 1) of \(viewModel.filteredResults.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.nextWord()
                AppTheme.impactLight()
            } label: {
                Text("Next")
                Image(systemName: "chevron.right")
            }
            .disabled(viewModel.currentIndex >= viewModel.filteredResults.count - 1)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(viewModel.filteredResults.count) words")
                    .font(.headline)
                Text("(\(viewModel.totalScore) pts)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    viewModel.toggleSortOrder()
                } label: {
                    Image(systemName: viewModel.sortByLength ? "textformat.size.smaller" : "star.fill")
                    Text(viewModel.sortByLength ? "Shortest" : "Score")
                }
                .font(.caption)

                Picker("Min Length", selection: $viewModel.minWordLength) {
                    ForEach(3..<9) { len in
                        Text("\(len)+").tag(len)
                    }
                }
                .pickerStyle(.menu)
            }

            LazyVStack(spacing: 2) {
                ForEach(Array(viewModel.filteredResults.enumerated()), id: \.element.id) { index, result in
                    Button {
                        viewModel.currentIndex = index
                        AppTheme.impactLight()
                    } label: {
                        HStack {
                            Text(result.word.uppercased())
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)

                            Spacer()

                            Text("\(result.word.count) letters")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(result.score) pts")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.currentIndex == index
                                ? Color.blue.opacity(0.1)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                }
            }
        }
    }
}
