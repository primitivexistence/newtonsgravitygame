//
//  Point.swift
//  newtonsgravity
//
//  Created by Kutay Agbal on 09/10/2017.
//  Copyright © 2017 Kutay Agbal. All rights reserved.
//

import Foundation

class Point {
    var x: Double
    var y: Double
    var z: Double = 0.0
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}
