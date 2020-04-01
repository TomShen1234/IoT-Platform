//
//  MainMenuView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/12/1.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI
import Combine

struct MainMenuView: View {
    var serverCredential: ServerCredential
    @ObservedObject var clientStore = IoTClientStore()
    
    /// Forced unwrapped alias of clientStore.devicesArray
    /// Used to shorten code, **use with care**.
    var devicesArray: DevicesArray {
        return clientStore.devicesArray!
    }
    
    var body: some View {
        VStack {
            if !clientStore.completed {
                // Loading
                VStack {
                    Text("Server: \(serverCredential.server)")
                    LoadingIndicator()
                }
            } else {
                if clientStore.success {
                    // Success
                    List(0..<self.devicesArray.devicesCount) { index in
                        NavigationLink(destination: DeviceView(device: self.devicesArray.devices[index], serverCredential: self.serverCredential)) {
                            Text("Device \(index): \(self.clientStore.devicesArray!.devices[index].name)")
                        }
                    }
                } else {
                    // Error
                    VStack {
                        Text("Server: \(serverCredential.server)")
                        Text("Error retrieving devices:")
                        Text(clientStore.errorString)
                            .multilineTextAlignment(.center)
                        // TODO: Add retry button
                    }
                }
            }
        }
        .navigationBarTitle("Devices", displayMode: .inline)
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
    
    var dataTasks = Set<AnyCancellable>()
    
    func discover() {
        if serverAddress.count == 0 {
            errorString = "Please set server URL."
            completed = true
            return
        }
        
        if !serverAddress.starts(with: "http://") && !serverAddress.starts(with: "https://") {
            serverAddress = "http://" + serverAddress
        }
        
        URLSession.shared.dataTaskPublisher(for: URL(string: serverAddress + "/discover.py")!)
            .tryMap { output in
                try HTTPError.assertHTTPStatus(output.response)
                
                return output.data
            }
            .decode(type: DevicesArray.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
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
                
                self.completed = true
            }) { results in
                self.devicesArray = results
            }
            .store(in: &dataTasks)
    }
}

// MARK: - Preview
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainMenuView(serverCredential: ServerCredential())
        }
    }
}
