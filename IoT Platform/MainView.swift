//
//  MainView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/11/26.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var loginStore = Login()
    
    var body: some View {
        VStack {
            if loginStore.success == false {
                LoginView(loginStore: loginStore)
            } else {
                MainMenuView(serverCredential: loginStore.serverCredential)
            }
        }
        .animation(.easeInOut)
    }
}

// MARK: - Supporting classes

final class Login: ObservableObject {
    @Published var server: String = ""
    @Published var password: String = ""
    
    // Set to true to login
    @Published var login: Bool = false {
        didSet {
            if !login {
                return
            }
            
            // Login, set success or failure + errStr to true, then login to false to continue
            
            delay(seconds: 0.5) {
                self.success = true
                
                self.login = false
                
                self.serverCredential.server = self.server
                self.serverCredential.password = self.password
            }
        }
    }
    
    @Published var success: Bool = false
    @Published var failure: Bool = false
    @Published var errStr: String = ""
    
    var serverCredential: ServerCredential = ServerCredential()
}

// MARK: - Previews

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
