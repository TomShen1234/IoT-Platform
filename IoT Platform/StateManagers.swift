//
//  StateManagers.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/1/7.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import Foundation

/// Subclass to implement custom states
class DeviceStateManager {
    var control: Control
    
    init(control: Control) {
        self.control = control
    }
}

// MARK: - Switch
class SwitchStateManager: DeviceStateManager {
    var state: Bool
    
    var loading: Bool
    
    var enabled: Bool
    
    init(state: Bool, control: Control) {
        self.state = state
        self.loading = false
        self.enabled = true
        super.init(control: control)
    }
    
    func updateState(to device: String, with serverCredential: ServerCredential, _ completion: @escaping (_ success: Bool) -> Void) {
        let newState = ["device":control.parameterName, "state":state] as [String : Any]
        
        let json = try? JSONSerialization.data(withJSONObject: newState, options: .fragmentsAllowed)
        
        guard let jsonObj = json, let jsonString = String(data: jsonObj, encoding: .utf8) else {
            // Reset
            completion(false)
            return
        }
        
        let jsonStringEncoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let urlString = "http://\(serverCredential.server)/execute.py?device=\(device)&command=\(jsonStringEncoded)"
        
        //print(urlString)
        
        URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            if httpResponse?.statusCode != 200 {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if data == nil {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let dict = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
            
            if dict == nil {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let success = dict!["success"] as! Int
            if success == 1 {
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                // No success, fail
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
}
