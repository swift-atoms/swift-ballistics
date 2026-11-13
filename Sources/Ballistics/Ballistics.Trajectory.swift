extension Ballistics {
    /// The motion along one axis of a body thrown with a velocity, under a constant acceleration and a drag
    /// in proportion to its velocity: v′ = acceleration − drag × v. With drag its velocity tends to
    /// acceleration / drag, the terminal velocity; without, it is the motion under constant acceleration.
    ///
    /// Under this drag the axes do not interact, so a flight in the plane or in space is one trajectory per
    /// axis with the same drag: the axis of the pull with its acceleration, the others with zero.
    public struct Trajectory<Scalar: BinaryFloatingPoint> {
        /// The velocity it is thrown with, in units of length per unit of time.
        public let velocity: Scalar

        /// The constant acceleration, such as gravity along the vertical; zero along an axis without pull.
        public let acceleration: Scalar

        /// The share of its velocity that drag takes away per unit of time; zero in a vacuum.
        public let drag: Scalar

        /// A trajectory from a finite velocity, a finite acceleration and a finite drag of zero or more.
        public init(velocity: Scalar, acceleration: Scalar, drag: Scalar) throws(Error) {
            guard velocity.isFinite else { throw .velocity }
            guard acceleration.isFinite else { throw .acceleration }
            guard drag.isFinite, drag >= 0 else { throw .drag }
            self.velocity = velocity
            self.acceleration = acceleration
            self.drag = drag
        }
    }
}

extension Ballistics.Trajectory: Equatable {}
extension Ballistics.Trajectory: Hashable {}
extension Ballistics.Trajectory: Sendable where Scalar: Sendable {}

extension Ballistics.Trajectory where Scalar: Exponential.`Protocol` {
    /// How far it has moved from where it was thrown after a time t: v × t × φ₁(k × t) + a × t² × φ₂(k × t),
    /// with φ₁(z) = (1 − e^(−z)) / z and φ₂(z) = (z − 1 + e^(−z)) / z², which are 1 and 1/2 at z = 0. Without
    /// drag it is v × t + a × t² / 2.
    public func position(at time: Scalar) -> Scalar {
        let z = drag * time
        return velocity * time * Self.first(z) + acceleration * time * time * Self.second(z)
    }

    /// Its velocity after a time t: v × e^(−k × t) + a × t × φ₁(k × t); without drag, v + a × t.
    public func velocity(at time: Scalar) -> Scalar {
        let z = drag * time
        return velocity * Scalar.exp(-z) + acceleration * time * Self.first(z)
    }

    /// (1 − e^(−z)) / z, and 1 at zero.
    private static func first(_ z: Scalar) -> Scalar {
        z == 0 ? 1 : -Scalar.expm1(-z) / z
    }

    /// (z − 1 + e^(−z)) / z², by its Taylor series near zero, where the direct form cancels.
    private static func second(_ z: Scalar) -> Scalar {
        guard abs(z) < 1 / 8 else { return (z + Scalar.expm1(-z)) / (z * z) }
        var term: Scalar = 1 / 2
        var sum: Scalar = term
        (3...14).forEach { power in
            term *= -z / Scalar(power)
            sum += term
        }
        return sum
    }

    /// The time at which it stops moving against the acceleration and turns, the top of a throw upward:
    /// log(1 − k × v / a) / k, or −v / a without drag. Zero when it is not thrown against the acceleration.
    public var apex: Scalar {
        guard velocity * acceleration < 0 else { return 0 }
        guard drag > 0 else { return -velocity / acceleration }
        return Scalar.log1p(-drag * velocity / acceleration) / drag
    }

    /// The time after its apex at which it is at a position, the one time it gets there moving with the
    /// acceleration; nil for a position it never reaches after its apex, and without acceleration.
    ///
    /// Without drag it is the apex plus √(2 × (position − position at apex) / a). With drag it is found by
    /// halving a bracket that is sure to hold it until the halves meet in the scalar.
    public func landing(at position: Scalar) -> Scalar? {
        guard acceleration != 0 else { return nil }
        let early = apex
        let remaining = (position - self.position(at: early)) / acceleration
        guard remaining >= 0 else { return nil }
        guard remaining > 0 else { return early }
        guard drag > 0 else { return early + (2 * remaining).squareRoot() }
        let sign: Scalar = acceleration < 0 ? -1 : 1
        var (low, high) = (early, early + remaining * drag + 1 / drag)
        while true {
            let middle = low + (high - low) / 2
            guard middle > low, middle < high else { return high }
            if sign * self.position(at: middle) < sign * position { low = middle } else { high = middle }
        }
    }
}
