# swift-ballistics

Use this package when something thrown through air (confetti, sparks, a ball) should fly, slow and fall, and you need where it is at an instant without simulating the instants before it. Start from `Ballistics.Trajectory<Scalar>`, made from the velocity it is thrown with, a drag and the terminal velocity it tends to, and ask for `position(at:)`, `velocity(at:)`, its `apex` and the time it reaches a depth with `landing(at:)`. Each answer is a formula in the time, so frames can be computed alone, out of order and in parallel, and always agree. The scalar supplies `exp` and `log` through `Exponential.Protocol`; this package conforms no type. For a body on a spring, use swift-spring.

## Laws

- The motion is the exact solution of v′ = drag × (terminal − v) along one axis: a constant pull and a drag in proportion to the speed. A trajectory has a finite velocity, a positive finite drag and a finite terminal velocity; construction fails with `.velocity`, `.drag` or `.terminal`, checked in that order.
- The axes do not interact under this drag. A flight in the plane or in space is one trajectory per axis with the same drag: the terminal velocity along the pull, zero across it. Along an axis without pull the position tends to velocity / drag.
- `position(at:)` is terminal × t + (velocity − terminal) / drag × (1 − e^(−drag × t)), measured from where it was thrown; `velocity(at:)` is its derivative. At time zero they are zero and the velocity it was thrown with.
- `apex` is the time at which the velocity is zero, log((terminal − velocity) / terminal) / drag, when it is thrown against the pull, and zero otherwise.
- `landing(at:)` is the time after the apex at which the position reaches a depth in the direction of the pull, by sixty halvings of a bracket that is sure to hold it. A depth already passed at the apex gives the apex. Without pull it is `nil`.
- Results are as repeatable across platforms as the scalar's `exp` and `log`.
