extension Ballistics {
    /// The motion along one axis of a body thrown with a velocity, pulled at a constant rate and slowed by
    /// drag in proportion to its speed: v′ = drag × (terminal − v). Its velocity tends to `terminal`, the
    /// speed at which pull and drag balance, and its position is a formula in the time.
    ///
    /// Under this drag the axes do not interact, so a flight in the plane or in space is one trajectory per
    /// axis with the same drag: the axis of the pull with its terminal velocity, the others with zero.
    public struct Trajectory<Scalar: BinaryFloatingPoint> {
        /// The velocity it is thrown with, in units of length per unit of time.
        public let velocity: Scalar

        /// The share of the difference from the terminal velocity it loses per unit of time.
        public let drag: Scalar

        /// The velocity it tends to, the pull divided by the drag; zero along an axis without pull.
        public let terminal: Scalar

        /// A trajectory from a velocity, a positive drag and a terminal velocity, all finite.
        public init(velocity: Scalar, drag: Scalar, terminal: Scalar) throws(Error) {
            guard velocity.isFinite else { throw .velocity }
            guard drag.isFinite, drag > 0 else { throw .drag }
            guard terminal.isFinite else { throw .terminal }
            self.velocity = velocity
            self.drag = drag
            self.terminal = terminal
        }
    }
}

extension Ballistics.Trajectory: Equatable {}
extension Ballistics.Trajectory: Hashable {}
extension Ballistics.Trajectory: Sendable where Scalar: Sendable {}

extension Ballistics.Trajectory where Scalar: Exponential.`Protocol` {
    /// How far it has moved from where it was thrown after a time:
    /// terminal × t + (velocity − terminal) / drag × (1 − e^(−drag × t)).
    public func position(at time: Scalar) -> Scalar {
        terminal * time + (velocity - terminal) / drag * (1 - Scalar.exp(-drag * time))
    }

    /// Its velocity after a time: terminal + (velocity − terminal) × e^(−drag × t).
    public func velocity(at time: Scalar) -> Scalar {
        terminal + (velocity - terminal) * Scalar.exp(-drag * time)
    }

    /// The time at which it stops moving against the pull and turns, the top of a throw upward; zero when
    /// it is not thrown against the pull.
    public var apex: Scalar {
        velocity * terminal < 0 ? Scalar.log((terminal - velocity) / terminal) / drag : 0
    }

    /// The time after its apex at which it has moved `depth` from where it was thrown, in the direction of
    /// the pull, found by sixty halvings; past the apex it moves ever further, so there is one such time.
    /// The apex itself, to within the halving, for a depth it has passed by then; nil without pull.
    public func landing(at depth: Scalar) -> Scalar? {
        guard terminal != 0 else { return nil }
        let sign: Scalar = terminal < 0 ? -1 : 1
        var early = apex
        var late = early + Swift.max(sign * depth - sign * position(at: early), 0) / (sign * terminal) + 10 / drag
        for _ in 0..<60 {
            let middle = (early + late) / 2
            if sign * position(at: middle) < sign * depth { early = middle } else { late = middle }
        }
        return late
    }
}
