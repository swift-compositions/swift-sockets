public import IO_Kernel
public import Kernel
public import Span

extension Sockets.TCP {

    public struct Connection: ~Copyable, Sendable {

        public let descriptor: Kernel.Descriptor

        public let peer: Kernel.Socket.Address.Storage

        public let io: IO<Sockets.Capabilities>

        internal init(
            descriptor: consuming Kernel.Descriptor,
            peer: Kernel.Socket.Address.Storage,
            io: IO<Sockets.Capabilities>
        ) {
            self.descriptor = descriptor
            self.peer = peer
            self.io = io
        }
    }
}

extension Sockets.TCP.Connection {

    public borrowing func read(
        into buffer: Span.Raw.Mutable
    ) async throws(Sockets.Error) -> Int {
        unsafe try await io.read(from: descriptor, into: buffer)
    }

    public borrowing func write(
        from buffer: Span.Raw
    ) async throws(Sockets.Error) -> Int {
        unsafe try await io.write(to: descriptor, from: buffer)
    }

    public consuming func close() async {
        await io.close(consume descriptor)
    }
}

extension Sockets.TCP.Connection {

    public borrowing func shutdown(
        how: Kernel.Socket.Shutdown.How
    ) throws(Sockets.Error) {
        do throws(Kernel.Socket.Shutdown.Error) {
            try Kernel.Socket.Shutdown.shutdown(descriptor, how: how)
        } catch {
            switch error {
            case .platform(let err): throw .platform(err.code)
            }
        }
    }
}

extension Sockets.TCP.Connection {

    public static func connect(
        to address: Kernel.Socket.Address.IPv4,
        io: IO<Sockets.Capabilities>
    ) async throws(Sockets.Error) -> sending Sockets.TCP.Connection {
        let socket: Kernel.Descriptor
        do throws(Kernel.Socket.Error) {
            socket = try Kernel.Socket.Create.create(domain: .inet, kind: .stream)
        } catch {
            throw Sockets.Error(error)
        }
        try io.prepare(socket)
        try await io.connect(socket, to: address.storage, length: Kernel.Socket.Address.IPv4.size)
        return Sockets.TCP.Connection(descriptor: consume socket, peer: address.storage, io: io)
    }

    public static func connect(
        to address: Kernel.Socket.Address.IPv6,
        io: IO<Sockets.Capabilities>
    ) async throws(Sockets.Error) -> sending Sockets.TCP.Connection {
        let socket: Kernel.Descriptor
        do throws(Kernel.Socket.Error) {
            socket = try Kernel.Socket.Create.create(domain: .inet6, kind: .stream)
        } catch {
            throw Sockets.Error(error)
        }
        try io.prepare(socket)
        try await io.connect(socket, to: address.storage, length: Kernel.Socket.Address.IPv6.size)
        return Sockets.TCP.Connection(descriptor: consume socket, peer: address.storage, io: io)
    }
}

extension Sockets.TCP.Connection {

    package static func connectReactively(
        _ descriptor: borrowing Kernel.Descriptor,
        to address: Kernel.Socket.Address.Storage,
        length: Kernel.Socket.Address.Length,
        ready: (borrowing Kernel.Descriptor, Kernel.Event.Interest) async throws(Sockets.Error) ->
            Void
    ) async throws(Sockets.Error) {

        do throws(Kernel.Socket.Error) {
            try ISO_9945.Kernel.Socket.Connect.connect(descriptor, address: address, length: length)
            return
        } catch {
            let code = error.code
            guard code.isInterrupted || code.isInProgress else {
                throw Sockets.Error(error)
            }
        }

        try await ready(descriptor, .write)

        let pending: Error::Error.Code
        do throws(Kernel.Socket.Error) {
            pending = try ISO_9945.Kernel.Socket.getError(descriptor)
        } catch {
            throw Sockets.Error(error)
        }
        guard pending == .posix(0) else {
            throw .platform(pending)
        }
    }

}
