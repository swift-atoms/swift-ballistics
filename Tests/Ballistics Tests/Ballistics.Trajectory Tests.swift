public import Ballistics
import Foundation
import Testing

extension Double: @retroactive Exponential.`Protocol` {
    public static func exp(_ x: Double) -> Double { Foundation.exp(x) }
    public static func expm1(_ x: Double) -> Double { Foundation.expm1(x) }
    public static func exp2(_ x: Double) -> Double { Foundation.exp2(x) }
    public static func log(_ x: Double) -> Double { Foundation.log(x) }
    public static func log1p(_ x: Double) -> Double { Foundation.log1p(x) }
    public static func log2(_ x: Double) -> Double { Foundation.log2(x) }
    public static func log10(_ x: Double) -> Double { Foundation.log10(x) }
}

private typealias Trajectory = Ballistics.Trajectory<Double>

@Suite
struct `Ballistics.Trajectory Tests` {
    @Test
    func `A trajectory has finite velocity and terminal velocity and positive finite drag`() throws {
        let throwing = try Trajectory(velocity: -900, drag: 2.5, terminal: 480)
        #expect(throwing.velocity == -900 && throwing.drag == 2.5 && throwing.terminal == 480)
        #expect(throws: Trajectory.Error.velocity) { try Trajectory(velocity: .nan, drag: 1, terminal: 1) }
        #expect(throws: Trajectory.Error.drag) { try Trajectory(velocity: 1, drag: 0, terminal: 1) }
        #expect(throws: Trajectory.Error.drag) { try Trajectory(velocity: 1, drag: .infinity, terminal: 1) }
        #expect(throws: Trajectory.Error.terminal) { try Trajectory(velocity: 1, drag: 1, terminal: -.infinity) }
    }

    @Test
    func `It starts where it was thrown, with the velocity it was thrown with, and tends to the terminal velocity`() throws {
        let throwing = try Trajectory(velocity: -900, drag: 2.5, terminal: 480)
        #expect(throwing.position(at: 0) == 0)
        #expect(throwing.velocity(at: 0) == -900)
        #expect(abs(throwing.velocity(at: 40) - 480) < 1e-9)
        let across = try Trajectory(velocity: 300, drag: 3, terminal: 0)
        #expect(abs(across.position(at: 40) - 100) < 1e-9)
    }

    @Test
    func `Its velocity is the rate of change of its position, and obeys the law of motion`() throws {
        let throwing = try Trajectory(velocity: -700, drag: 2.2, terminal: 520)
        let step = 1e-6
        for time in [0.05, 0.3, 0.9, 2.0] {
            let slope = (throwing.position(at: time + step) - throwing.position(at: time - step)) / (2 * step)
            #expect(abs(slope - throwing.velocity(at: time)) < 1e-4)
            let acceleration = (throwing.velocity(at: time + step) - throwing.velocity(at: time - step)) / (2 * step)
            #expect(abs(acceleration - 2.2 * (520 - throwing.velocity(at: time))) < 1e-3)
        }
    }

    @Test
    func `The apex is where the velocity is zero, and zero for a throw with the pull`() throws {
        let up = try Trajectory(velocity: -1200, drag: 3, terminal: 450)
        #expect(abs(up.velocity(at: up.apex)) < 1e-9)
        #expect(up.position(at: up.apex) < up.position(at: up.apex - 0.01))
        #expect(up.position(at: up.apex) < up.position(at: up.apex + 0.01))
        #expect(try Trajectory(velocity: 100, drag: 3, terminal: 450).apex == 0)
        #expect(try Trajectory(velocity: -100, drag: 3, terminal: 0).apex == 0)
        let mirrored = try Trajectory(velocity: 1200, drag: 3, terminal: -450)
        #expect(mirrored.apex == up.apex)
    }

    @Test
    func `It lands at a depth once, after its apex`() throws {
        let up = try Trajectory(velocity: -1500, drag: 2.4, terminal: 500)
        let landing = try #require(up.landing(at: 300))
        #expect(landing > up.apex)
        #expect(abs(up.position(at: landing) - 300) < 1e-6)
        let mirrored = try Trajectory(velocity: 1500, drag: 2.4, terminal: -500)
        let under = try #require(mirrored.landing(at: -300))
        #expect(abs(under - landing) < 1e-9)
        let passed = try #require(up.landing(at: -1e6))
        #expect(abs(passed - up.apex) < 1e-9)
        #expect(try Trajectory(velocity: 10, drag: 1, terminal: 0).landing(at: 5) == nil)
    }

    @Test
    func `A frame is the same however it is reached`() throws {
        let throwing = try Trajectory(velocity: -800, drag: 2.7, terminal: 430)
        let (first, second) = (0.4, 0.75)
        let later = try Trajectory(velocity: throwing.velocity(at: first), drag: 2.7, terminal: 430)
        #expect(abs(throwing.position(at: first) + later.position(at: second) - throwing.position(at: first + second)) < 1e-9)
    }
}
