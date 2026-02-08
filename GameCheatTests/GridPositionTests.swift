import Testing
@testable import GameCheat

struct GridPositionTests {
    @Test func adjacentHorizontal() {
        let a = GridPosition(row: 1, col: 1)
        let b = GridPosition(row: 1, col: 2)
        #expect(a.isAdjacent(to: b) == true)
    }

    @Test func adjacentVertical() {
        let a = GridPosition(row: 1, col: 1)
        let b = GridPosition(row: 2, col: 1)
        #expect(a.isAdjacent(to: b) == true)
    }

    @Test func adjacentDiagonal() {
        let a = GridPosition(row: 0, col: 0)
        let b = GridPosition(row: 1, col: 1)
        #expect(a.isAdjacent(to: b) == true)
    }

    @Test func notAdjacentTooFar() {
        let a = GridPosition(row: 0, col: 0)
        let b = GridPosition(row: 2, col: 2)
        #expect(a.isAdjacent(to: b) == false)
    }

    @Test func notAdjacentSelf() {
        let a = GridPosition(row: 1, col: 1)
        #expect(a.isAdjacent(to: a) == false)
    }

    @Test func allEightDirections() {
        let center = GridPosition(row: 1, col: 1)
        let neighbors = [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0),                               GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ]
        for neighbor in neighbors {
            #expect(center.isAdjacent(to: neighbor) == true)
        }
    }
}
