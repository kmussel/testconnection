//
//  Socket.swift
//  Connection
//
//  Created by Jeremy Tregunna on 2016-01-27.
//  Copyright © 2016 Pilot Foundation. All rights reserved.
//

import Darwin

enum SocketError: ErrorType, CustomStringConvertible {
    case Connection(String, Int32)
    case Bind(String, Int32)
    case Listen(String, Int32)
    case Accept(String, Int32)

    var description: String {
        var name             = ""
        var type: String     = ""
        var number: Int32    = 0

        switch self {
        case .Connection(let what, let errno):
            name    = "Connection"
            type    = what
            number  = errno

        case .Bind(let what, let errno):
            name    = "Bind"
            type    = what
            number  = errno

        case .Accept(let what, let errno):
            name    = "Accept"
            type    = what
            number  = errno

        default:
            name    = ""
            type    = __FUNCTION__
            number  = errno
        }

        return "\(name) error: (\(type)) - Errorno: \(number)"
    }
}

internal func Connection_fcntl(fd fd: CInt, cmd: CInt, value: CInt) -> CInt {
    typealias FcntlType = @convention(c) (CInt, CInt, CInt) -> CInt
    let fcntlAddr = dlsym(UnsafeMutablePointer<Void>(bitPattern: Int(-2)), "fcntl")
    let fcntl = unsafeBitCast(fcntlAddr, FcntlType.self)
    return fcntl(fd, cmd, value)
}

public class Socket {
    var status: Int32 = 0
    var hints: addrinfo
    var servinfo: UnsafeMutablePointer<addrinfo> = nil
    var socketDescriptors: Array<Int32>

    init(family: Int32, port: UInt16, nonblocking: Bool = false) throws {
        socketDescriptors = Array<Int32>()
        hints = addrinfo(ai_flags: AI_PASSIVE,
                         ai_family: family,
                         ai_socktype: SOCK_STREAM,
                         ai_protocol: 0,
                         ai_addrlen: 0,
                         ai_canonname: nil,
                         ai_addr: nil,
                         ai_next: nil)
        status = getaddrinfo(nil, String(port), &hints, &servinfo)

        var info = servinfo
#if DEBUG
        if status != 0 {
            print("*** Error from getaddrinfo: \(String.fromCString(gai_strerror(status)))")
        }

        // Print a list of the IP addresses we found.
        while info != nil {
            let addr = info.memory
            let desc = sockaddrDescription(addr.ai_addr)
            print("\(desc)");
            info = addr.ai_next
        }
#endif

        if status != 0 {
            throw SocketError.Connection(String.fromCString(gai_strerror(status))!, errno)
        }

        info = servinfo
        while info != nil {
            let addr = info.memory
            let fd = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol)
            if fd == -1 {
                continue
            }
            try bind(fd, addr: addr)
            if status == -1 {
                Darwin.close(fd)
            }
            // This can be used if we have another runloop keeping the application alive.
            if nonblocking {
                Connection_fcntl(fd: fd, cmd: F_SETFL, value: Connection_fcntl(fd: fd, cmd: F_GETFL, value: 0))
            }
            socketDescriptors.append(fd)

            info = addr.ai_next
        }

        try listen()

#if DEBUG
        print("Socket descriptor: \(socketDescriptor.description)")
#endif
    }

    private init(fd: Int32) {
        status = 0
        hints = addrinfo()
        self.socketDescriptors = [fd]
    }

    deinit {
        if servinfo != nil {
            freeaddrinfo(servinfo)
        }
    }

    public func description() -> String {
        return "<Socket fds: \(socketDescriptors) open: \(socketDescriptors.count == 0)>"
    }

    internal func bind(fd: Int32, addr: addrinfo) throws {
        status = Darwin.bind(fd, addr.ai_addr, addr.ai_addrlen)
        if status == -1 {
            Darwin.close(fd);
            throw SocketError.Bind(__FUNCTION__, errno)
        }
#if DEBUG
        print("Bind status: \(status)")
#endif
    }

    internal func listen() throws {
        for fd in socketDescriptors {
            if Darwin.listen(fd, 0) < 0 {
                throw SocketError.Listen(__FUNCTION__, errno)
            }
        }
    }
    
    internal func accept(block: (Socket) -> Void) throws {
        for fd in socketDescriptors {
            let incoming = Darwin.accept(fd, nil, nil)
            if incoming > 0 {
                block(Socket(fd: incoming))
            } else {
                throw SocketError.Accept(__FUNCTION__, errno)
            }
        }
    }

    internal func close() {
        for fd in socketDescriptors {
            Darwin.close(fd)
        }
    }

    internal func shutdown() {
        for fd in socketDescriptors {
            Darwin.shutdown(fd, Int32(SHUT_RDWR))
        }
    }

    public func write(fd fd: Int32, message: String) {
        message.withCString { bytes in
            Darwin.send(fd, bytes, Int(strlen(bytes)), 0)
        }
    }

    public func read(fd fd: Int32, bytes: Int) throws -> [CChar] {
        let data    = Data(capacity: bytes)
        let bytes   = Darwin.read(fd, data.bytes, data.capacity)

        return Array(data.characters[0..<bytes])
    }

    private func sockaddrDescription(addr: UnsafePointer<sockaddr>) -> String
    {
        var host : String?
        var port : String?

        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        var servBuffer = [CChar](count: Int(NI_MAXSERV), repeatedValue: 0)

        if getnameinfo(addr, socklen_t(addr.memory.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &servBuffer, socklen_t(servBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) == 0 {
                host = String.fromCString(hostBuffer)
                port = String.fromCString(servBuffer)
        }
        return "host: " + (host ?? "?") + " port: " + (port ?? "?")
    }
}
