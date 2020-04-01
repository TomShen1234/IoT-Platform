//
//  StateManagers.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/1/7.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import Foundation
import Combine

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
    
    private var dataTasks = Set<AnyCancellable>()
    
    init(state: Bool, control: Control) {
        self.state = state
        self.loading = false
        self.enabled = true
        super.init(control: control)
    }
    
    func updateState(to device: String, with serverCredential: ServerCredential, direct: Bool, _ completion: @escaping (_ success: Bool) -> Void) {
        let newState = ["device":control.parameterName, "state":state] as [String : Any]
        
        let json = try? JSONSerialization.data(withJSONObject: newState, options: .fragmentsAllowed)
        
        guard let jsonObj = json, let jsonString = String(data: jsonObj, encoding: .utf8) else {
            // Reset
            completion(false)
            return
        }
        
        let jsonStringEncoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let urlString: String
        if direct {
            urlString = "http://\(serverCredential.server)/run.py?device=\(device)&command=\(jsonStringEncoded)"
        } else {
            // Through a central server
            urlString = "http://\(serverCredential.server)/execute.py?device=\(device)&command=\(jsonStringEncoded)"
        }
        
        //print(urlString)
        
        URLSession.shared.dataTaskPublisher(for: URL(string: urlString)!)
            .tryMap { output -> Bool in
                try HTTPError.assertHTTPStatus(output.response)
                
                let returnedData = try JSONSerialization.jsonObject(with: output.data, options: .allowFragments)
                
                guard let dict = returnedData as? [String:Any] else {
                    throw HTTPError.invalidData
                }
                
                guard let success = dict["success"] as? Int else {
                    throw HTTPError.invalidData
                }
                
                return success == 1
            }
            .retry(1) // Retry 1 time before failing
            .replaceError(with: false) // Just discard the error if still fails
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .sink { value in
                completion(value)
            }
            .store(in: &dataTasks)
    }
}
