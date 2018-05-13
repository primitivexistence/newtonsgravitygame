//
//  Velocity.swift
//  newtonsgravity
//
//  Created by Kutay Agbal on 09/10/2017.
//  Copyright © 2017 Kutay Agbal. All rights reserved.
//

import Foundation

class Velocity {
    var magnitude: Double
    var angle: Double?
    var xAngle: Double?
    var yAngle: Double?
    var zAngle: Double = 0.0
    
    init(magnitude: Double, xAngle: Double, yAngle: Double, zAngle: Double) {
        self.xAngle = xAngle
        self.yAngle = yAngle
        self.zAngle = zAngle
        self.magnitude = magnitude
    }
}
