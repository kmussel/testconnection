//
//  Server.swift
//  Connection
//
//  Created by Jeremy Tregunna on 2016-01-28.
//  Copyright © 2016 Pilot Foundation. All rights reserved.
//

import Darwin
import Dispatch

public class Server {
    var socket: Socket?
    let acceptQueue: dispatch_queue_t
    let acceptGroup: dispatch_group_t

    init(port: UInt16) throws {
        socket = nil
        // Create our own here as we'll be indirectly using barriers...let's be polite and not use one of the global queues.
        acceptQueue = dispatch_queue_create("internal.connection.accept", DISPATCH_QUEUE_CONCURRENT)
        acceptGroup = dispatch_group_create()
        socket = try Socket(family: AF_UNSPEC, port: port, nonblocking: true)
    }

    // Our run loop. Yields an accepted socket.
    public func serve(block: (Socket) -> Void) throws {
        dispatch_group_async(acceptGroup, acceptQueue) {
            guard let socket = self.socket else {
#if DEBUG
                print("Socket is not listening for connections.")
#endif
                return
            }

            dispatch_group_enter(self.acceptGroup)
            do {
                try socket.accept { socket in
                    block(socket)
                    dispatch_group_leave(self.acceptGroup)
                }
            } catch {
#if DEBUG
                print("Socket error")
#endif
            }
        }
        dispatch_group_wait(acceptGroup, DISPATCH_TIME_FOREVER)
    }
}
