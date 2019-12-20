//
//  ContentView.swift
//  IoT Platform
//
//  Created by Tom Shen on 2019/11/2.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var loginStore: Login
    
    var body: some View {
        LoginContainer(serverName: $loginStore.server, password: $loginStore.password, finished: $loginStore.login)
            .alert(isPresented: $loginStore.failure) { () -> Alert in
                Alert(title: Text("Error"), message: Text(loginStore.errStr), dismissButton: .default(Text("Close")) {
                    self.loginStore.login = false
                })
            }
    }
}

struct LoginContainer: View {
    @Binding var serverName: String
    @Binding var password: String
    
    @Binding var finished: Bool
    
    var body: some View {
        VStack {
            Text("Welcome! Please login with your server's credential.")
                .multilineTextAlignment(.center)
            
            TextField("Enter Server Address", text: $serverName)
                .padding(.top)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Enter Password", text: $password)
                .padding(.vertical)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Spacer()
                
                Button(action: {
                    // Button Action
                    self.finished = true
                    
                    hideKeyboard()
                }) {
                    Text("Login")
                        .padding(.leading)
                }
                .disabled(!(serverName.count > 0 && password.count > 0))
                
                Spacer()
                
                ActivityIndicator(isAnimating: $finished, style: .medium, alwaysUseWhite: false)
            }
        }.frame(width: 250)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(loginStore: Login())
    }
}
