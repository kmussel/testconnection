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
    var socketDescriptor: Int32

    init(family: Int32, port: UInt16) throws {
        hints = addrinfo(ai_flags: AI_PASSIVE,
                         ai_family: family,
                         ai_socktype: SOCK_STREAM,
                         ai_protocol: 0,
                         ai_addrlen: 0,
                         ai_canonname: nil,
                         ai_addr: nil,
                         ai_next: nil)
        status = getaddrinfo(nil, String(port), &hints, &servinfo)

#if DEBUG
        if status != 0 {
            print("*** Error from getaddrinfo: \(String.fromCString(gai_strerror(status)))")
        }

        // Print a list of the IP addresses we found.
        var info = servinfo
        while info != nil {
            let addr = info.memory
            let desc = sockaddrDescription(addr.ai_addr)
            print("\(desc)");
            info = addr.ai_next
        }
#endif

        if status != 0 {
            socketDescriptor = -1
            throw SocketError.Connection(String.fromCString(gai_strerror(status))!, errno)
        }

        // TODO: all the addresses above?
        socketDescriptor = socket(servinfo.memory.ai_family, servinfo.memory.ai_socktype, servinfo.memory.ai_protocol)
        if socketDescriptor < 1 {
            throw SocketError.Connection(__FUNCTION__, errno)
        }

        Connection_fcntl(fd: socketDescriptor, cmd: 0, value: 0)
#if DEBUG
        print("Socket descriptor: \(socketDescriptor.description)")
#endif
    }

    private init(fd: Int32) {
        status = 0
        hints = addrinfo()
        self.socketDescriptor = fd
    }

    deinit {
        if servinfo != nil {
            freeaddrinfo(servinfo)
        }
    }

    public func bind() throws {
        status = Darwin.bind(socketDescriptor, servinfo.memory.ai_addr, servinfo.memory.ai_addrlen)
        if status == -1 {
            close(socketDescriptor);
            throw SocketError.Bind(__FUNCTION__, errno)
        }
#if DEBUG
        print("Bind status: \(status)")
#endif
    }

    public func listen() throws {
        if Darwin.listen(socketDescriptor, 0) < 0 {
            throw SocketError.Listen(__FUNCTION__, errno)
        }
    }
    
    public func accept() throws -> Socket {
        let incoming = Darwin.accept(socketDescriptor, nil, nil)
        if incoming < 0 {
            throw SocketError.Accept(__FUNCTION__, errno)
        }
        
        return Socket(fd: socketDescriptor)
    }

    public func close() {
        Darwin.close(socketDescriptor)
    }

    func write(message: String) {
        message.withCString { bytes in
            Darwin.send(socketDescriptor, bytes, Int(strlen(bytes)), 0)
        }
    }

    func read(bytes: Int) throws -> [CChar] {
        let data    = Data(capacity: bytes)
        let bytes   = Darwin.read(socketDescriptor, data.bytes, data.capacity)

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
