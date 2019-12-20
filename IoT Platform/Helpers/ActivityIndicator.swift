//
//  ActivityIndicator.swift
//  Student Bulletin 13
//
//  Created by Tom Shen on 2019/8/24.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

// Thanks:
//https://stackoverflow.com/questions/56496638/activity-indicator-in-swiftui

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    let alwaysUseWhite: Bool

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: style)
        spinner.hidesWhenStopped = true
        if alwaysUseWhite {
            spinner.overrideUserInterfaceStyle = .dark
        }
        return spinner
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
