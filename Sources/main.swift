/*
This source file is part of the Swift.org open source project

Copyright 2015 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See http://swift.org/LICENSE.txt for license information
See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

#if os(Linux)
    import Glibc
srandom(UInt32(clock()))
#endif

import Foundation
//import Connection

var server = try Server(port:8188)
print("CREATED SERVER")
print(server)
try server.serve(){(socket) -> Void in
//        print("INSDIE SERVE")
//        print(socket)
    let message       = "Hello World\n"
    let contentLength = message.utf8.count
    
//    let sd = socket.socketDescriptors
    //    print("THE SD = \(sd.count)\n")
    let fd = socket.descriptor // socket.socketDescriptors[0]
    //    print("THE FD = \(fd)\n")
    //    server.socket?.write(fd:fd, message:"HTTP/1.1 200 OK\n")
    //    server.socket?.write(fd:fd, message:"Server: Pilot Example \n")
    //    server.socket?.write(fd:fd, message:"Content-length: \(contentLength)\n")
    //    server.socket?.write(fd:fd, message:"Content-type: text-plain\n")
    //    server.socket?.write(fd:fd, message:"\r\n")
    //    server.socket?.write(fd:fd, message:message)
    socket.write(fd:fd, message:"HTTP/1.1 200 OK\n")
    socket.write(fd:fd, message:"Server: Pilot Example \n")
    socket.write(fd:fd, message:"Content-length: \(contentLength)\n")
    socket.write(fd:fd, message:"Content-type: text-plain\n")
    socket.write(fd:fd, message:"\r\n")
    socket.write(fd:fd, message:message)
    

    
        var index = 0
        for index = 0; index < 300000; ++index {
    //        print("index is \(index)")
    //        j = j+1
        }
    
    socket.close()
    
    
}

