//
//  SimpleObject.swift
//  newtonsgravity
//
//  Created by Kutay Agbal on 09/10/2017.
//  Copyright © 2017 Kutay Agbal. All rights reserved.
//

import Foundation
import UIKit

class SimpleObject {
    var mass: Double//kg
    var radius: Double //meters
    var velocity: Velocity
    var color: UIColor
    var point : Point
    var oldPoint : Point
    
    init(mass: Double, radius: Double, velocity: Velocity, color: UIColor, point: Point) {
        self.mass = mass
        self.radius = radius
        self.velocity = velocity
        self.color = color
        self.point = point
        self.oldPoint = point
    }
}
