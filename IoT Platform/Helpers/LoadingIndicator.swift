//
//  LoadingIndicator.swift
//  IoT Platform
//
//  Created by Tom Shen on 2020/4/1.
//  Copyright © 2020 Tom Shen. All rights reserved.
//

import SwiftUI

struct LoadingIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Loading...")
            ActivityIndicator(isAnimating: true, style: .medium, alwaysUseWhite: false)
            Spacer()
        }
    }
}
