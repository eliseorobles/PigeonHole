import SwiftUI

struct AnagramsView: View {
    @State private var viewModel = AnagramsViewModel()
    @FocusState private var isInputFocused: Bool
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputSection
                solveButton
                if !viewModel.results.isEmpty {
                    resultsSection
                }
            }
            .padding()
        }
        .navigationTitle("Anagrams")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    viewModel.clear()
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }

    private var inputSection: some View {
        VStack(spacing: 8) {
            TextField("Enter letters (e.g., CATALOG)", text: $viewModel.letters)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title3, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .focused($isInputFocused)

            Text("\(viewModel.letters.count) letters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var solveButton: some View {
        Button {
            viewModel.solve()
        } label: {
            HStack {
                if viewModel.isSolving {
                    ProgressView()
                        .tint(.white)
                }
                Text(viewModel.isSolving ? "Searching..." : "Solve")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canSolve)
    }

    private var resultsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(viewModel.filteredResults.count) words found")
                    .font(.headline)

                Spacer()

                Picker("Min Length", selection: $viewModel.minLength) {
                    ForEach(3..<9) { len in
                        Text("\(len)+").tag(len)
                    }
                }
                .pickerStyle(.menu)
            }

            ForEach(viewModel.resultsByLength, id: \.length) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(group.length) letters")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                        ForEach(group.words) { result in
                            Text(result.word.uppercased())
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
    }
}
