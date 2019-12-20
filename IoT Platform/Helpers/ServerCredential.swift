//
//  ServerCredential.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/12/1.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import Foundation

struct ServerCredential {
    var server: String
    var password: String
    
    init() {
        server = ""
        password = ""
    }
}
