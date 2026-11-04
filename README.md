# swift-sockets

Use this package when you want TCP or UDP over IPv4 or IPv6 from async Swift code without picking the waiting strategy at every call site. Build an `IO<Sockets.Capabilities>` once, then open sockets on it: `Sockets.TCP.Listener` to accept connections, `Sockets.TCP.Connection.connect(to:io:)` to dial out, and `Sockets.UDP.Endpoint` for datagrams. If you want readiness or completion I/O for descriptors that aren't sockets, use swift-io-kernel, which this package builds on.

## Laws

- `IO.blocking()` runs every operation as an ordinary blocking system call on one thread of a shared pool. `IO.blocking(on:)` uses the executor you give it. A blocking `IO` never waits for readiness, so a thread blocked in accept sleeps in the kernel instead of spinning.
- `IO.events()` and `IO.events(on:)` make each socket non-blocking when it is prepared. An operation that would block waits for readiness on the event actor and then tries again. A connect that is in progress waits until the socket is writable and then reports the socket's pending error, if any.
- With an events `IO`, a cancelled task's read fails with `Sockets.Error.cancelled`, and the socket is deregistered so closing it still delivers end of file to the peer. The package adds no timeouts. A deadline is a task that cancels the operation.
- An `IO` made by `IO.events()` owns its event actor. Shutting it down can be repeated, makes every later operation fail with `Sockets.Error.ioShutdown`, and still lets close release a descriptor. An `IO` made by `IO.events(on:)` leaves the actor to its owner, and its shutdown does nothing.
- `Sockets.TCP.Listener.blocking(address:io:backlog:)` and `Sockets.TCP.Listener.reactive(address:io:backlog:)` do the same thing. The `IO` decides how the listener waits. The backlog defaults to the system maximum.
- `Sockets.TCP.Listener.accept(io:)` waits through the listener's own `IO` and prepares the accepted connection with the `IO` you pass, which may differ. A spurious wake-up with nothing to accept is retried.
- A connection reset by the peer is reported as `Sockets.Error.connectionReset`. Every other system error keeps its code. Errors from closing a socket are ignored.
- Reads and writes return as soon as the kernel transfers anything, so a short count is normal and a read of 0 is end of file.
