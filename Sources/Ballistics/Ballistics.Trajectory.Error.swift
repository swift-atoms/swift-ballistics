extension Ballistics.Trajectory {
    /// Why a trajectory could not be made: the named value is out of range.
    public enum Error: Swift::Error, Equatable, Sendable {
        /// The velocity is not finite.
        case velocity

        /// The drag is not positive and finite.
        case drag

        /// The terminal velocity is not finite.
        case terminal
    }
}
