//
//  MainMenuView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/12/1.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI

struct MainMenuView: View {
    var serverCredential: ServerCredential
    @ObservedObject var clientStore = IoTClientStore()
    
    /// Forced unwrapped alias of clientStore.devicesArray
    /// Used to shorten code, **use with care**.
    var devicesArray: DevicesArray {
        return clientStore.devicesArray!
    }
    
    var body: some View {
        NavigationView {
            if !clientStore.completed {
                // Loading
                VStack {
                    Text("Server: \(serverCredential.server)")
                    HStack {
                        Text("Loading...")
                        ActivityIndicator(isAnimating: .constant(true), style: .medium, alwaysUseWhite: false)
                    }
                }
                .navigationBarTitle("Devices", displayMode: .automatic)
            } else {
                if clientStore.success {
                    // Success
                    List(0..<self.devicesArray.devicesCount) { index in
                        NavigationLink(destination: DeviceView(device: self.devicesArray.devices[index], serverCredential: self.serverCredential)) {
                            Text("Device \(index): \(self.clientStore.devicesArray!.devices[index].name)")
                        }
                    }
                    .navigationBarTitle("Devices: \(serverCredential.server)", displayMode: .automatic)
                } else {
                    // Error
                    VStack {
                        Text("Server: \(serverCredential.server)")
                        Text("Error retrieving devices:")
                        Text(clientStore.errorString)
                            .multilineTextAlignment(.center)
                        // TODO: Add retry button
                    }
                    .navigationBarTitle("Devices", displayMode: .automatic)
                }
            }
        }
        .animation(.easeInOut)
        .onAppear {
            self.clientStore.serverAddress = self.serverCredential.server
            self.clientStore.discover()
        }
    }
}

class IoTClientStore: ObservableObject {
    @Published var completed = false
    
    // Set server address
    var serverAddress: String = ""
    
    var success = false
    
    var errorString: String = ""
    
    var devicesArray: DevicesArray? = nil
    
    // TODO: Support system without central hub
    func discover() {
        if serverAddress.count == 0 {
            errorString = "Please set server URL."
            completed = true
            return
        }
        
        if !serverAddress.starts(with: "http://") && !serverAddress.starts(with: "https://") {
            serverAddress = "http://" + serverAddress
        }
        
        URLSession.shared.dataTask(with: URL(string: serverAddress + "/discover.py")!) { (data, response, error) in
            defer {
                DispatchQueue.main.async {
                    self.completed = true
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
            
            let devicesArray: DevicesArray
            do {
                devicesArray = try JSONDecoder().decode(DevicesArray.self, from: data!)
            } catch let error {
                self.errorString = error.localizedDescription
                return
            }
            
            self.devicesArray = devicesArray
            
            self.success = true
        }.resume()
    }
}

// MARK: - Preview
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(serverCredential: ServerCredential())
    }
}
