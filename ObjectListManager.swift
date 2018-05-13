//
//  ObjectListManager.swift
//  newtonsgravity_game
//
//  Created by KTY-MAC on 8.01.2018.
//  Copyright © 2018 Kutay Agbal. All rights reserved.
//

import Foundation
import UIKit

//Singleton
private let _sharedObjListManager = ObjectListManager()

class ObjectListManager{
    class var sharedObjListManager: ObjectListManager {
        return _sharedObjListManager
    }
    
    fileprivate var _objList: [SimpleObject] = []
    fileprivate var _followObj: SimpleObject = SimpleObject(mass: -1, radius: -1, velocity: Velocity(magnitude: 0.0, xAngle: 0.0, yAngle: 0.0, zAngle: 0.0), color: UIColor.black, point: Point(x: 0.0, y: 0.0, z: 0.0))
    
    fileprivate let concurrentObjListQueue = DispatchQueue(label: "newtonsgravitygame,objListQueue", attributes: .concurrent)
    
    var objectList: [SimpleObject] {
        var objListCopy: [SimpleObject]!
        concurrentObjListQueue.sync {
            objListCopy = self._objList
        }
        return objListCopy
    }
    
    var followObj: SimpleObject {
        var followObjCopy: SimpleObject!
        concurrentObjListQueue.sync {
            followObjCopy = self._followObj
        }
        return followObjCopy
    }
    
    func addObject(_ obj: SimpleObject) {
        concurrentObjListQueue.async(flags: .barrier) {
            if self._followObj.mass != -1{
                if self._followObj.mass < obj.mass{
                    self._objList.append(self._followObj)
                    self._followObj = obj
                }else{
                    self._objList.append(obj)
                }
            }else{
                //First object
                self._followObj = obj
            }
        }
    }
    
    func removeObject(_ objIndex: Int) {
        concurrentObjListQueue.async(flags: .barrier) {
            self._objList.remove(at: objIndex)
        }
    }
}
