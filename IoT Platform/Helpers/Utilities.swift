//
//  Utilities.swift
//  Student Bulletin 13
//
//  Created by Tom Shen on 2019/8/24.
//  Copyright © 2019 Tom Shen. All rights reserved.
//

import UIKit

func delay(seconds: Double, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds, execute: block)
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
