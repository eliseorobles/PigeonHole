import Foundation

struct MancalaState: GameState, Hashable {
    typealias Move = Int

    // [0...5] player one pits, [6] player one store,
    // [7...12] player two pits, [13] player two store
    var pits: [Int]
    var currentPlayer: Player

    init(pits: [Int]? = nil, currentPlayer: Player = .one) {
        self.pits = pits ?? [4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 0]
        self.currentPlayer = currentPlayer
    }

    static var initial: MancalaState {
        MancalaState()
    }

    var winner: Player? {
        let one = pits[6]
        let two = pits[13]
        if one == two { return nil }
        return one > two ? .one : .two
    }

    var isTerminal: Bool {
        sideStoneCount(for: .one) == 0 || sideStoneCount(for: .two) == 0
    }

    func generateMoves() -> [Int] {
        let offsets = currentPlayer == .one ? (0..<6) : (7..<13)
        return offsets
            .filter { pits[$0] > 0 }
            .map { currentPlayer == .one ? $0 : ($0 - 7) }
    }

    func applying(_ move: Int) -> MancalaState {
        guard (0..<6).contains(move), generateMoves().contains(move) else { return self }

        var next = self
        let start = absolutePitIndex(relativeMove: move, for: currentPlayer)
        var stones = next.pits[start]
        next.pits[start] = 0
        var index = start

        while stones > 0 {
            index = (index + 1) % 14
            if currentPlayer == .one && index == 13 { continue }
            if currentPlayer == .two && index == 6 { continue }
            next.pits[index] += 1
            stones -= 1
        }

        if isOwnPit(index, for: currentPlayer),
           next.pits[index] == 1 {
            let opposite = 12 - index
            if next.pits[opposite] > 0 {
                let store = currentPlayer == .one ? 6 : 13
                next.pits[store] += next.pits[opposite] + 1
                next.pits[opposite] = 0
                next.pits[index] = 0
            }
        }

        let ownStore = currentPlayer == .one ? 6 : 13
        if index != ownStore {
            next.currentPlayer = currentPlayer.opponent
        }

        next.collectRemainderIfGameOver()
        return next
    }

    func evaluate() -> Double {
        let oneStore = pits[6]
        let twoStore = pits[13]
        let oneSide = sideStoneCount(for: .one)
        let twoSide = sideStoneCount(for: .two)
        let raw = Double((oneStore - twoStore) * 6 + (oneSide - twoSide))

        if isTerminal {
            let terminal = Double((oneStore - twoStore) * 100)
            return currentPlayer == .one ? terminal : -terminal
        }

        return currentPlayer == .one ? raw : -raw
    }

    func absolutePitIndex(relativeMove: Int, for player: Player) -> Int {
        player == .one ? relativeMove : (relativeMove + 7)
    }

    func sideStoneCount(for player: Player) -> Int {
        if player == .one {
            return pits[0...5].reduce(0, +)
        }
        return pits[7...12].reduce(0, +)
    }

    private func isOwnPit(_ index: Int, for player: Player) -> Bool {
        if player == .one {
            return (0...5).contains(index)
        }
        return (7...12).contains(index)
    }

    private mutating func collectRemainderIfGameOver() {
        let oneEmpty = sideStoneCount(for: .one) == 0
        let twoEmpty = sideStoneCount(for: .two) == 0
        guard oneEmpty || twoEmpty else { return }

        let oneRemainder = sideStoneCount(for: .one)
        let twoRemainder = sideStoneCount(for: .two)

        pits[6] += oneRemainder
        pits[13] += twoRemainder

        for idx in 0...5 {
            pits[idx] = 0
        }
        for idx in 7...12 {
            pits[idx] = 0
        }
    }
}
