extension Ballistics.Trajectory {
    /// Why a trajectory could not be made: the named value is out of range.
    public enum Error: Swift::Error, Equatable, Sendable {
        /// The velocity is not finite.
        case velocity

        /// The acceleration is not finite.
        case acceleration

        /// The drag is negative or not finite.
        case drag
    }
}
