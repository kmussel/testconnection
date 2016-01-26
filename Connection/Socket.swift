//
//  Socket.swift
//  Pilot
//
//  Created by Wesley Cope on 12/9/15.
//  Copyright © 2015 Wess Cope. All rights reserved.
//

import Foundation
import Darwin
import Darwin.C

enum SocketError : ErrorType, CustomStringConvertible {
    case Connection(String, Int32)
    case Bind(String, Int32)
    case Listen(String, Int32)
    case Accept(String, Int32)
    
    var description:String {
        var name            = ""
        var type:String     = ""
        var number:Int32    = 0
        
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

public class Socket {
    private let sock_stream     = SOCK_STREAM
    private let socket_accept   = Darwin.accept
    private let socket_bind     = Darwin.bind
    private let socket_close    = Darwin.close
    private let socket_listen   = Darwin.listen
    private let socket_read     = Darwin.read
    private let socket_send     = Darwin.send
    private let socket_shutdown = Darwin.shutdown

    typealias Connection    = Int32
    typealias Port          = UInt16
    
    let connection:Connection
    var port:Port = 80
    lazy var address:sockaddr_in = {
        let htons = (self.port << 8) + (self.port >> 8)
        
        return sockaddr_in(
            sin_len     : __uint8_t(sizeof(sockaddr_in)),
            sin_family  : sa_family_t(AF_INET),
            sin_port    : htons,
            sin_addr    : in_addr(s_addr: in_addr_t(0)),
            sin_zero    : (0, 0, 0, 0, 0, 0, 0, 0)
        )
    }()
    
    init() throws {
        connection  = socket(AF_INET, sock_stream, 0)
        
        if connection < 1 {
            throw SocketError.Connection(__FUNCTION__, errno)
        }
        
        var buffer:Int32 = 1024
        guard setsockopt(connection, SOL_SOCKET, SO_REUSEADDR, &buffer, socklen_t(sizeof(Int32))) > -1 else {
            throw SocketError.Connection(__FUNCTION__, errno)
        }
    }
    
    private init(connection:Connection) {
        self.connection = connection
    }
    
    func bind(port:Port) throws {
        self.port = port
        
        let length  = socklen_t(UInt8(sizeof(sockaddr_in)))
        let pointer = UnsafeMutablePointer<sockaddr>(withUnsafeMutablePointer(&address, { $0 }))
        
        guard socket_bind(connection, pointer, length) < 0 else {
            throw SocketError.Bind(__FUNCTION__, errno)
        }
    }
    
    func listen() throws {
        if socket_listen(connection, 0) < 0 {
            throw SocketError.Listen(__FUNCTION__, errno)
        }
    }
    
    func accept() throws -> Socket {
        let incoming = socket_accept(connection, nil, nil)
        if incoming < 0 {
            throw SocketError.Accept(__FUNCTION__, errno)
        }
        
        return Socket(connection: connection)
    }
    
    func close() {
        socket_close(connection)
    }
    
    func shutdown() {
        socket_shutdown(connection, Int32(SHUT_RDWR))
    }
    
    func write(message:String) {
        message.withCString { bytes in
            socket_send(connection, bytes, Int(strlen(bytes)), 0)
        }
    }
    
    func read(bytes:Int) throws -> [CChar] {
        let data    = Data(capacity: bytes)
        let bytes   = socket_read(connection, data.bytes, data.capacity)
        
        return Array(data.characters[0..<bytes])
    }
}










