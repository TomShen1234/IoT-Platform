//
//  Types.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/1/4.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import Foundation

class DevicesArray: Codable, CustomStringConvertible {
    var description: String {
        return "Device Count: \(devicesCount), Devices: \(devices)"
    }
    
    var devicesCount: Int
    var devices: [Device]
}

class Device: Codable, CustomStringConvertible {
    var description: String {
        return "Device name: \(name), Controls: \(controls)"
    }
    
    var name: String
    var controls: [Control]
    
    // For previews
    init(name: String, controls: [Control]) {
        self.name = name
        self.controls = controls
    }
    
    /// Returns control with specified parameter name or nil
    func control(with paramName: String) -> Control? {
        return controls.first { (control) -> Bool in
            return control.parameterName == paramName
        }
    }
}

class Control: Codable, CustomStringConvertible {
    var description: String {
        return "Control Name: \(displayName), Parameter: \(parameterName), Type: \(type), Class: \(className)"
    }
    
    var displayName: String
    var parameterName: String
    var type: String
    var className: String
    
    // For previews, does not have function when previewing live
    init(displayName: String, type: String) {
        self.displayName = displayName
        self.type = type
        // No function, doesn't do anything
        self.className = ""
        self.parameterName = ""
    }
}
