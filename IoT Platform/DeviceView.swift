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
    
    // Alias to device.controls to shorten codes
    var controls: [Control] {
        return device.controls
    }
    
    // TODO: Bring back after being able to download state
    //@State var controlHandlers = [ControlHandler]()
    
    // Temp
    @State var switchState = false
    
    var body: some View {
        // TODO: Download state datas before presenting all controls
        List(0..<controls.count) { index in
            HStack {
                if self.controls[index].type == "switch" {
                    // TODO: Use downloaded data to set initial
                    Toggle(isOn: self.$switchState) {
                        Text(self.controls[index].displayName)
                    }
                } else if self.controls[index].type == "label" {
                    Text(self.controls[index].displayName)
                    
                    Spacer()
                    
                    Text("Label")
                }
            }
        }
            .navigationBarTitle("Device: \(device.name)", displayMode: .inline)
    }
    
    /*
    func createSwitchBinding(with control: Control, initial: Bool) -> Binding<Bool> {
        let newHandler = SwitchHandler(control: control, initialState: initial)
        controlHandlers.append(newHandler)
        
        return newHandler.$switchState
    }*/
}

/// Handle all controls
class ControlHandler {
    var control: Control
    
    init(control: Control) {
        self.control = control
    }
}

/// Handle Switches
class SwitchHandler: ControlHandler {
    @State var switchState: Bool
    
    init(control: Control, initialState: Bool) {
        switchState = initialState
        
        super.init(control: control)
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceView(device: Device(name: "Preview Device", controls: [Control(displayName: "Test Control 1", type: "switch")]))
        }
    }
}
