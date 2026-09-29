public import IO_Kernel
public import Kernel
public import Span_Raw

extension IO.Kernel where Capabilities == Sockets.Capabilities {

    @inlinable
    public func prepare(
        _ fd: borrowing Kernel::Kernel.Descriptor
    ) throws(Sockets.Error) {
        try capabilities.prepare(fd)
    }

    @inlinable
    public func read(
        from fd: borrowing Kernel::Kernel.Descriptor,
        into buffer: Span.Raw.Mutable
    ) async throws(Sockets.Error) -> Int {
        try await capabilities.read(fd, buffer)
    }

    @inlinable
    public func write(
        to fd: borrowing Kernel::Kernel.Descriptor,
        from buffer: Span.Raw
    ) async throws(Sockets.Error) -> Int {
        try await capabilities.write(fd, buffer)
    }

    @inlinable
    public func close(_ fd: consuming Kernel::Kernel.Descriptor) async {
        await capabilities.close(consume fd)
    }

    @inlinable
    public func ready(
        from fd: borrowing Kernel::Kernel.Descriptor,
        interest: Kernel::Kernel.Event.Interest
    ) async throws(Sockets.Error) {
        try await capabilities.ready(fd, interest)
    }

    @inlinable
    public func connect(
        _ fd: borrowing Kernel::Kernel.Descriptor,
        to address: Kernel::Kernel.Socket.Address.Storage,
        length: Kernel::Kernel.Socket.Address.Length
    ) async throws(Sockets.Error) {
        try await capabilities.connect(fd, address, length)
    }

    @inlinable
    public func send(
        on fd: borrowing Kernel::Kernel.Descriptor,
        from buffer: Span.Raw,
        to address: Kernel::Kernel.Socket.Address.Storage,
        length: Kernel::Kernel.Socket.Address.Length
    ) async throws(Sockets.Error) -> Int {
        try await capabilities.send(fd, buffer, address, length)
    }

    @inlinable
    public func receive(
        on fd: borrowing Kernel::Kernel.Descriptor,
        into buffer: Span.Raw.Mutable
    ) async throws(Sockets.Error) -> (
        count: Int, peer: Kernel::Kernel.Socket.Address.Storage, length: Kernel::Kernel.Socket.Address.Length
    ) {
        try await capabilities.receive(fd, buffer)
    }

    @inlinable
    public var unownedExecutor: UnownedSerialExecutor {
        unsafe runner.executor()
    }
}
