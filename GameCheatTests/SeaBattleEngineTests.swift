import Testing
@testable import GameCheat

struct SeaBattleEngineTests {
    @Test func blockedCellsHaveZeroProbability() {
        var grid = SeaBattleGrid()
        grid[0, 0] = .miss
        grid[0, 1] = .sunk(shipSize: 2)

        let probabilities = ProbabilityCalculator.calculate(grid: grid, remainingShips: [5, 4, 3, 3, 2])
        #expect(probabilities[0][0] == 0)
        #expect(probabilities[0][1] == 0)
    }

    @Test func hitCellTriggersTargetMode() {
        var grid = SeaBattleGrid()
        grid[4, 4] = .hit

        #expect(HuntTargetStrategy.determineMode(grid: grid) == .target)
    }
}
