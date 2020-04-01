//
//  DeviceView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/12/20.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI
import Combine

struct DeviceView: View {
    var device: Device
    
    var serverCredential: ServerCredential
    
    @ObservedObject var controlHandler = ControlHandler()
    
    // Alias to device.controls to shorten codes
    var controls: [Control] {
        return device.controls
    }
    
    // TODO: Bring back after being able to download state
    //@State var controlHandlers = [ControlHandler]()
    
    // Temp
    @State var switchState = false
    
    var body: some View {
        List {
            if self.controlHandler.loading {
                LoadingIndicator()
            } else {
                if self.controlHandler.success {
                    ForEach(self.controls, id: \.parameterName) { control in
                        ControlCell(control: control,
                                    controlHandler: self.controlHandler,
                                    device: self.device,
                                    serverCredential: self.serverCredential)
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
            if self.device.direct {
                // Direct, without central server
                self.controlHandler.downloadControlInfoState(with: self.device, credential: self.serverCredential)
            } else {
                // Connecting through server
                self.controlHandler.getControlStates(with: self.device, credential: self.serverCredential)
            }
        }
        .onDisappear {
            self.controlHandler.cancel()
        }
    }
}

struct ControlCell: View {
    var control: Control
    var controlHandler: ControlHandler
    var device: Device
    var serverCredential: ServerCredential
    
    var body: some View {
        HStack {
            if control.type == "switch" {
                // Use custom binding to let ControlHandler handle the states
                Text(control.displayName)
                
                Spacer()
                
                ActivityIndicator(isAnimating: controlHandler.getSwitchLoadingState(for: control.parameterName), style: .medium, alwaysUseWhite: false)
                
                Toggle(isOn: switchBinding()) {
                    Text("Title")
                }.labelsHidden()
            } else if control.type == "label" {
                Text(control.displayName)
                
                Spacer()
                
                Text("Label")
            } else if control.type == "slider" {
                // TODO: Slider
            } else if control.type == "button" {
                // TODO: Button
            } else {
                // Unknown control
                Text("Unknown Control")
            }
        }
    }
    
    /// Create a binding that toggles a switch
    func switchBinding() -> Binding<Bool> {
        return Binding(get: {
            self.controlHandler.getSwitchState(for: self.control.parameterName)
        }, set: { newValue in
            self.controlHandler.setSwitchState(newValue, to: self.device, with: self.serverCredential, for: self.control.parameterName)
        })
    }
}

// MARK: - Control Handler
class ControlHandler: ObservableObject {
    /// Store downloaded result of function `downloadControlInfoState` in a tuple
    typealias DownloadResult = (controls: [Control], allStatus: [[String:Any]])
    
    @Published var loading = true
    
    var success = false
    
    var errorString: String?
    
    private var dataTask: AnyCancellable?
    
    private var statesManagers = [DeviceStateManager]()
    
    /// Use when accessing control without central hub
    func downloadControlInfoState(with device: Device, credential: ServerCredential) {
        loading = true
        
        dataTask?.cancel()
        
        let cfgurlString = "http://\(credential.server)/config.json"
        
        dataTask = URLSession.shared.dataTaskPublisher(for: URL(string: cfgurlString)!)
            .tryMap { output -> Data in
                try HTTPError.assertHTTPStatus(output.response)
                
                return output.data
            }
            .decode(type: [Control].self, decoder: JSONDecoder())
            .flatMap{ controls -> AnyPublisher<DownloadResult, Error> in
                // Also download the status in the same publisher
                // Result will be mapped into a tuple
                let urlString = "http://\(credential.server)/status.py"
                
                return self.statusDownloadPublisher(with: URL(string: urlString)!)
                    .map { allStatus in
                        return (controls, allStatus)
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // Controls should be already set, continuing
                    self.success = true
                case .failure(let error):
                    if let httpError = error as? HTTPError {
                        self.errorString = httpError.getErrorString()
                    } else {
                        self.errorString = error.localizedDescription
                    }
                }
                self.loading = false
            }) { result in
                // Set the control
                device.controls = result.controls
                
                let allStatus = result.allStatus
                for status in allStatus {
                    self.createControlStatus(with: device, status: status)
                }
            }
    }
    
    func getControlStates(with device: Device, credential: ServerCredential) {
        // Networking to download control state
        
        loading = true
        
        dataTask?.cancel()
        
        let urlString = "http://\(credential.server)/getstatus.py?device=\(device.name)"
        
        dataTask = statusDownloadPublisher(with: URL(string: urlString)!)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.success = true
                case .failure(let error):
                    if let httpError = error as? HTTPError {
                        self.errorString = httpError.getErrorString()
                    } else {
                        self.errorString = error.localizedDescription
                    }
                }
                
                self.loading = false
            }) { allStatus in
                for status in allStatus {
                    self.createControlStatus(with: device, status: status)
                }
            }
    }
    
    func cancel() {
        dataTask?.cancel()
    }
    
    /// Returns a publisher that fetches the status of all controls from the `url` parameter
    func statusDownloadPublisher(with url: URL) -> AnyPublisher<[[String:Any]], Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output -> [[String: Any]] in
                try HTTPError.assertHTTPStatus(output.response)
            
                let response = try JSONSerialization.jsonObject(with:   output.data,  options: .allowFragments) as? [String:Any]
            
                guard let responseUnwrapped = response else {
                    throw HTTPError.invalidData
                }
            
                let successVal = responseUnwrapped["success"]
                guard let success = successVal as? Bool, success else {
                    if let error = responseUnwrapped["error"] as? String {
                        throw HTTPError.custom(error: error)
                    } else {
                        throw HTTPError.custom(error: "Unknown error while  parsing  downloaded data!")
                    }
                }
            
                guard let allStatus = responseUnwrapped["status"] as?       [[String:Any]] else {
                    throw HTTPError.custom(error: "Cannot get status values!")
                }
            
                return allStatus
            }
            .eraseToAnyPublisher()
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
    
    // MARK: - Switch Functions
    
    func getSwitchState(for parameterName: String) -> Bool {
        // Get manager for the device from array
        let stateManager = statesManagers.first { obj -> Bool in
            return obj.control.parameterName == parameterName
        } as! SwitchStateManager
        
        return stateManager.state
    }
    
    func getSwitchLoadingState(for parameterName: String) -> Bool {
        // Get manager for the device from array
        let stateManager = statesManagers.first { obj -> Bool in
            return obj.control.parameterName == parameterName
        } as! SwitchStateManager
        
        return stateManager.loading
    }
    
    func setSwitchState(_ newState: Bool, to device: Device, with serverCredential: ServerCredential, for parameterName: String) {
        // STUB, need to update through server
        let stateManager = statesManagers.first { obj -> Bool in
            return obj.control.parameterName == parameterName
        } as! SwitchStateManager
        
        stateManager.loading = true
        
        stateManager.state = newState
        
        objectWillChange.send()
        
        stateManager.updateState(to: device.name, with: serverCredential, direct: device.direct) { (success) in
            if !success {
                stateManager.state.toggle()
            }
            
            stateManager.loading = false
            
            self.objectWillChange.send()
        }
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
