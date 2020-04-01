import UIKit

var str = "{\"devicesCount\": 2, \"devices\": [{\"name\": \"clientpi2\", \"controls\": [{\"displayName\": \"Light 2\", \"parameterName\": \"state\", \"type\": \"switch\", \"gpio\": 4}]}, {\"name\": \"clientpi1\", \"controls\": [{\"displayName\": \"Light 1\", \"parameterName\": \"state\", \"type\": \"switch\", \"gpio\": 4}]}]}"
//
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
}

class Control: Codable, CustomStringConvertible {
    var description: String {
        return "Control Name: \(displayName), Parameter: \(parameterName)"
    }
    
    var displayName: String
    var parameterName: String
}

let decodedObject = try! JSONDecoder().decode(DevicesArray.self, from: str.data(using: .utf8)!)

print(decodedObject)


