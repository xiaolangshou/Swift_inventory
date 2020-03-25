//
//  HPMouse.swift
//  FactoryDemo
//
//  Created by Thomas Lau on 2020/3/7.
//  Copyright © 2020 TLLTD. All rights reserved.
//

import Foundation

class HPMouse: Mouse {
    
    static let shared = HPMouse()
    
    func logo() {
        print("hp logo")
    }
}
