internal import IO_Kernel
public import Kernel

extension Sockets {

    public enum Error: Swift.Error, Equatable {

        case descriptor(Kernel.Descriptor.Validity.Error)

        case registration(Registration)

        case closed(Direction)

        case connectionReset

        case notConnected

        case cancelled

        case ioShutdown

        case timeout

        case platform(Error::Error.Code)
    }
}

extension Sockets.Error {

    internal init(_ failure: Kernel.Event.Failure) {
        switch failure {
        case .left(.cancelled):
            self = .cancelled

        case .left(.shutdown):
            self = .ioShutdown

        case .left(.timeout):
            self = .timeout

        case .right(let error):
            switch error {
            case .platform(let code):
                self.init(code: code)

            case .invalidDescriptor:
                self = .descriptor(.invalid)

            case .alreadyRegistered:
                self = .registration(.duplicate)

            case .notRegistered:
                self = .registration(.missing)

            case .deregistered:
                self = .registration(.removed)

            case .readClosed:
                self = .closed(.read)

            case .writeClosed:
                self = .closed(.write)

            case .notConnected:
                self = .notConnected
            }
        }
    }
}

extension Sockets.Error {

    internal init(_ error: Kernel.IO.Read.Error) {
        self.init(code: error.code)
    }

    internal init(_ error: Kernel.IO.Write.Error) {
        self.init(code: error.code)
    }

    internal init(_ error: Kernel.Socket.Error) {
        self.init(code: error.code)
    }

    internal init(_ error: Kernel.File.Control.Error) {
        switch error {
        case .handle(let error):
            self = .descriptor(error)

        case .platform(let error):
            self.init(code: error.code)
        }
    }

    internal init(code: Error::Error.Code) {
        self =
            if code == .ECONNRESET {
                .connectionReset
            } else {
                .platform(code)
            }
    }
}
