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
    func `A trajectory has finite velocity and acceleration and a finite drag of zero or more`() throws {
        let throwing = try Trajectory(velocity: -900, acceleration: 1200, drag: 2.5)
        #expect(throwing.velocity == -900 && throwing.acceleration == 1200 && throwing.drag == 2.5)
        #expect(try Trajectory(velocity: 1, acceleration: 1, drag: 0).drag == 0)
        #expect(throws: Trajectory.Error.velocity) { try Trajectory(velocity: .nan, acceleration: 1, drag: 1) }
        #expect(throws: Trajectory.Error.acceleration) { try Trajectory(velocity: 1, acceleration: -.infinity, drag: 1) }
        #expect(throws: Trajectory.Error.drag) { try Trajectory(velocity: 1, acceleration: 1, drag: -1) }
        #expect(throws: Trajectory.Error.drag) { try Trajectory(velocity: 1, acceleration: 1, drag: .infinity) }
    }

    @Test
    func `It starts where it was thrown, with the velocity it was thrown with, and tends to the terminal velocity`() throws {
        let throwing = try Trajectory(velocity: -900, acceleration: 1200, drag: 2.5)
        #expect(throwing.position(at: 0) == 0)
        #expect(throwing.velocity(at: 0) == -900)
        #expect(abs(throwing.velocity(at: 40) - 480) < 1e-9)
        let across = try Trajectory(velocity: 300, acceleration: 0, drag: 3)
        #expect(abs(across.position(at: 40) - 100) < 1e-9)
    }

    @Test
    func `Its velocity is the rate of change of its position, and obeys the law of motion`() throws {
        for drag in [2.2, 0] {
            let throwing = try Trajectory(velocity: -700, acceleration: 1144, drag: drag)
            let step = 1e-6
            for time in [0.05, 0.3, 0.9, 2.0] {
                let slope = (throwing.position(at: time + step) - throwing.position(at: time - step)) / (2 * step)
                #expect(abs(slope - throwing.velocity(at: time)) < 1e-4)
                let change = (throwing.velocity(at: time + step) - throwing.velocity(at: time - step)) / (2 * step)
                #expect(abs(change - (1144 - drag * throwing.velocity(at: time))) < 1e-3)
            }
        }
    }

    @Test
    func `Without drag it is the motion under constant acceleration, and a little drag is close to it`() throws {
        let vacuum = try Trajectory(velocity: -20, acceleration: 9.81, drag: 0)
        let thin = try Trajectory(velocity: -20, acceleration: 9.81, drag: 1e-9)
        for time in [0.0, 0.5, 1, 3] {
            #expect(vacuum.position(at: time) == -20 * time + 9.81 * time * time / 2)
            #expect(abs(thin.position(at: time) - vacuum.position(at: time)) < 1e-6)
            #expect(abs(thin.velocity(at: time) - vacuum.velocity(at: time)) < 1e-6)
        }
        #expect(abs(vacuum.apex - 20 / 9.81) < 1e-15)
        #expect(abs(thin.apex - vacuum.apex) < 1e-6)
    }

    @Test
    func `The apex is where the velocity is zero, and zero for a throw with the acceleration`() throws {
        let up = try Trajectory(velocity: -1200, acceleration: 1350, drag: 3)
        #expect(abs(up.velocity(at: up.apex)) < 1e-9)
        #expect(up.position(at: up.apex) < up.position(at: up.apex - 0.01))
        #expect(up.position(at: up.apex) < up.position(at: up.apex + 0.01))
        #expect(try Trajectory(velocity: 100, acceleration: 1350, drag: 3).apex == 0)
        #expect(try Trajectory(velocity: -100, acceleration: 0, drag: 3).apex == 0)
        let mirrored = try Trajectory(velocity: 1200, acceleration: -1350, drag: 3)
        #expect(mirrored.apex == up.apex)
    }

    @Test
    func `It reaches a position after its apex once, and never one behind its apex`() throws {
        for drag in [2.4, 0] {
            let up = try Trajectory(velocity: -1500, acceleration: 1200, drag: drag)
            let landing = try #require(up.landing(at: 300))
            #expect(landing > up.apex)
            #expect(abs(up.position(at: landing) - 300) < 1e-9)
            #expect(up.position(at: landing.nextDown) < 300 || up.position(at: landing.nextDown) == up.position(at: landing))
            let mirrored = try Trajectory(velocity: 1500, acceleration: -1200, drag: drag)
            let under = try #require(mirrored.landing(at: -300))
            #expect(abs(under - landing) < 1e-9)
            let top = up.position(at: up.apex)
            #expect(try #require(up.landing(at: top)) == up.apex)
            #expect(up.landing(at: top - 1) == nil)
        }
        #expect(try Trajectory(velocity: 10, acceleration: 0, drag: 1).landing(at: 5) == nil)
    }

    @Test
    func `A frame is the same however it is reached`() throws {
        let throwing = try Trajectory(velocity: -800, acceleration: 1161, drag: 2.7)
        let (first, second) = (0.4, 0.75)
        let later = try Trajectory(velocity: throwing.velocity(at: first), acceleration: 1161, drag: 2.7)
        #expect(abs(throwing.position(at: first) + later.position(at: second) - throwing.position(at: first + second)) < 1e-9)
    }
}
