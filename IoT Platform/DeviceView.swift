//
//  DeviceView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/12/20.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI

struct DeviceView: View {
    var device: Device
    
    var serverCredential: ServerCredential
    
    @ObservedObject var controlHandler = ControlHandler()
    
    // Alias to device.controls to shorten codes
    var controls: [Control] {
        return device.controls
    }
    
    var numberOfRowsInTable: Int {
        if controlHandler.success == false {
            return 1
        } else {
            return controls.count
        }
    }
    
    // TODO: Bring back after being able to download state
    //@State var controlHandlers = [ControlHandler]()
    
    // Temp
    @State var switchState = false
    
    var body: some View {
        List(0..<numberOfRowsInTable) { index in
            if self.controlHandler.loading {
                HStack {
                    Spacer()
                    
                    Text("Loading... ")
                    ActivityIndicator(isAnimating: .constant(true), style: .medium, alwaysUseWhite: false)
                    
                    Spacer()
                }
            } else {
                if self.controlHandler.success {
                    HStack {
                        if self.controls[index].type == "switch" {
                            // Use custom binding to let ControlHandler handle the states
                            Toggle(isOn: Binding(get: {
                                self.controlHandler.getSwitchState(for: self.controls[index].parameterName)
                            }, set: { newValue in
                                self.controlHandler.setSwitchState(newValue, for: self.controls[index].parameterName)
                            })) {
                                Text(self.controls[index].displayName)
                            }
                        } else if self.controls[index].type == "label" {
                            Text(self.controls[index].displayName)
                            
                            Spacer()
                            
                            Text("Label")
                        } else if self.controls[index].type == "slider" {
                            // TODO: Slider
                        } else if self.controls[index].type == "button" {
                            // TODO: Button
                        } else {
                            // Unknown control
                            Text("Unknown Control")
                        }
                    }
                } else {
                    HStack {
                        Text("Error: ")
                        Text(self.controlHandler.errorString!)
                    }
                }
            }
        }
        .navigationBarTitle("Device: \(device.name)", displayMode: .inline)
        .onAppear {
            self.controlHandler.getControlStates(with: self.device, credential: self.serverCredential)
        }
        .onDisappear {
            self.controlHandler.cancel()
        }
    }
}

// MARK: - Control Handler
class ControlHandler: ObservableObject {
    @Published var loading = false
    
    var success = false
    
    var errorString: String?
    
    private var dataTask: URLSessionDataTask?
    
    private var statesManagers = [DeviceStateManager]()
    
    // TODO: Support system without central hub
    func getControlStates(with device: Device, credential: ServerCredential) {
        // Networking to download control state
        
        loading = true
        
        if dataTask != nil {
            cancel()
        }
        
        let urlString = "http://\(credential.server)/getstatus.py?device=\(device.name)"
        
        dataTask = URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            defer {
                DispatchQueue.main.async {
                    self.loading = false
                }
            }
            
            if error != nil {
                self.errorString = error!.localizedDescription
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            if httpResponse?.statusCode != 200 {
                self.errorString = "Wrong status code"
                return
            }
            
            if data == nil {
                self.errorString = "No data"
                return
            }
            
            let responseDict = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
            if responseDict == nil {
                self.errorString = "Can not read JSON data"
                return
            }
            
            let success = responseDict!["success"] as! Bool
            if success {
                // Create the states
                let allStatus = responseDict!["status"] as! [[String:Any]]
                for status in allStatus {
                    self.createControlStatus(with: device, status: status)
                }
                self.success = true
            } else {
                let error = responseDict!["error"]
                self.errorString = error as? String
            }
        }
        dataTask?.resume()
    }
    
    func cancel() {
        dataTask?.cancel()
        dataTask = nil
    }
    
    /// Create a control manager object for each control
    func createControlStatus(with device: Device, status: [String:Any]) {
        let paramName = status["parameterName"] as! String
        let control = device.control(with: paramName)!
        
        if control.type == "switch" {
            let currentState = status["state"] as! Bool
            
            let newSwitch = SwitchStateManager(state: currentState, control: control)
            
            statesManagers.append(newSwitch)
        }
        // TODO: Handle other types of controls
    }
    
    func getSwitchState(for parameterName: String) -> Bool {
        // Get manager for the device from array
        let stateManager = statesManagers.first { obj -> Bool in
            return obj.control.parameterName == parameterName
        } as! SwitchStateManager
        
        return stateManager.state
    }
    
    func setSwitchState(_ newState: Bool, for parameterName: String) {
        // STUB, need to update through server
        let stateManager = statesManagers.first { obj -> Bool in
            return obj.control.parameterName == parameterName
        } as! SwitchStateManager
        
        stateManager.state = newState
    }
}

// MARK: - State Managers
/// Subclass to implement custom states
class DeviceStateManager {
    var control: Control
    
    init(control: Control) {
        self.control = control
    }
}

class SwitchStateManager: DeviceStateManager {
    var state: Bool
    
    init(state: Bool, control: Control) {
        self.state = state
        super.init(control: control)
    }
}

// MARK: - Preview

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Have a default credential value so preview can run
            DeviceView(device: Device(name: "Preview Device", controls: [Control(displayName: "Test Control 1", type: "switch")]), serverCredential: ServerCredential())
        }
    }
}
