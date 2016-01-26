//
//  Data.swift
//  Pilot
//
//  Created by Wesley Cope on 12/9/15.
//  Copyright © 2015 Wess Cope. All rights reserved.
//

import Foundation
import Darwin

class Data {
    let bytes:UnsafeMutablePointer<Int8>
    let capacity:Int

    var characters:[CChar] {
        var data = [CChar](count: capacity, repeatedValue: 0)
        memcpy(&data, bytes, data.count)
        
        return data
    }
    
    var string:String? {
        return String.fromCString(characters)
    }
    
    init(capacity:Int) {
        bytes           = UnsafeMutablePointer<Int8>(malloc(capacity + 1))
        self.capacity   = capacity
    }
    
    deinit {
        free(bytes)
    }
}