//
//  DiscoverView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/3/31.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import SwiftUI

struct DiscoverView: View {
    // Just use the old login store to track state,
    // password is no longer used for now
    @ObservedObject var deviceHelper = DeviceDiscoverHelper()
    
    var body: some View {
        NavigationView {
            List {
                Picker("Mode", selection: $deviceHelper.pickerMode) {
                    Text("Server").tag(0)
                    Text("Client").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if deviceHelper.searching {
                    LoadingIndicator()
                }
                
                ForEach(deviceHelper.foundDevices) { device in
                    NavigationLink(destination: self.destination(for: device)) {
                        Text(device.name)
                    }
                }
            }
            .navigationBarTitle("Discover")
        }
        .onAppear {
            self.deviceHelper.startDiscoveringDevices()
        }
    }
    
    func destination(for device: BonjourDevice) -> AnyView {
        let credential = self.credential(for: device)
        
        if device.type.contains("iotserver") {
            return AnyView(MainMenuView(serverCredential: credential))
        } else if device.type.contains("iotdevice") {
            let targetDevice = Device(name: device.name)
            return AnyView(DeviceView(device: targetDevice, serverCredential: credential))
        }
        
        fatalError("Mode not supported!")
    }
    
    func credential(for device: BonjourDevice) -> ServerCredential {
        var credential = ServerCredential()
        credential.server = device.name + ".local"
        credential.password = ""
        return credential
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}

// MARK: - Bonjour Helper

class DeviceDiscoverHelper: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    enum DiscoverMode: Int {
        case server = 0
        case client = 1
    }
    
    @Published var foundDevices = [BonjourDevice]()
    
    var discoverProgress = [BonjourDevice]()
    
    let browser = NetServiceBrowser()
    
    var pickerMode: Int = 0 {
        didSet {
            self.mode = DiscoverMode(rawValue: pickerMode)!
        }
    }
    var mode: DiscoverMode = .server {
        didSet {
            //print("Mode set: \(mode)!")
            cancelDiscovery()
            startDiscoveringDevices()
        }
    }
    
    // Don't start multiple times
    @Published var searching = false
    
    func startDiscoveringDevices() {
        foundDevices.removeAll()
        discoverProgress.removeAll()
        
        if searching {
            return
        }
        
        browser.stop()
        
        browser.delegate = self
        
        let deviceType: String
        switch mode {
        case .server:
            deviceType = "_iotserver._tcp."
        case .client:
            deviceType = "_iotdevice._tcp."
        }
        browser.searchForServices(ofType: deviceType, inDomain: "")
    }
    
    func cancelDiscovery() {
        browser.stop()
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("Begin searching")
        
        searching = true
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Resolve error: ", sender, errorDict)
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Searching stopped")
        
        searching = false
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered a service!")
        print("Service name: ", service.name)
        print("Service type: ", service.type)
        print("Service domain: ", service.domain)
        
        service.delegate = self
        //service.resolve(withTimeout: 5)
        
        // Create device from discovered service
        let device = BonjourDevice(name: service.name, type: service.type)
        discoverProgress.append(device)
        
        if !moreComing {
            browser.stop()
            
            // Commit discovery
            foundDevices = discoverProgress
        }
    }
}

struct BonjourDevice: Identifiable {
    let id = UUID()
    var name: String
    var type: String
}
