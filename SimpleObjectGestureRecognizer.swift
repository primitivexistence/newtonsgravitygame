//
//  CustomGestureRecognizer.swift
//  newtonsgravity_game
//
//  Created by Kutay Agbal on 19/10/2017.
//  Copyright © 2017 Kutay Agbal. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class SimpleObjectGestureRecognizer: UIGestureRecognizer {

    private var touchedPoints = [CGPoint]() // point history
    var obj: SimpleObject?
    var touchBeganTime: Int64?
    var screenCenter: CGPoint?
    var screenCenter3d: CGPoint?
    var scaleFactor: CGFloat?
    
    var colors: [UIColor]?
    
    var isFirstObj: Bool?
    
//    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if theView.bounds.contains(touch.location(in: theView)) {
//            return false
//        }
//        return true
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>,  with event: UIEvent?){
        super.touchesBegan(touches, with: event!)
        
        //prevent multi touch
        if touches.count != 1 {
            state = .failed
            return
        }
        
        //prevent touche to slider
        let loc =  touches.first?.location(in: touches.first?.view)
        if loc!.x < 210 && loc!.y < 70{
            state = .failed
            return
        }
        
        state = .began
        obj = nil
        
        touchBeganTime = Int64(Date().timeIntervalSince1970 * 1000) //in milliseconds
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event!)
        
        //user has stopped touching, figure out if the obj is ok, then create it
//        createSimpleObject()
        createSimpleObject3d()
        state = .ended
        touchedPoints = []
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if state == .failed {
            return
        }
        
        let window = view?.window
        if let loc = touches.first?.location(in: window) {
            touchedPoints.append(convertToCoordinatePoint(point: loc))
            state = .changed
        }
    }
    
    public func createSimpleObject3d(){
        if let began = touchBeganTime, touchedPoints.count > 0{
            let timeDiff = Double(Int64(Date().timeIntervalSince1970 * 1000) - began) // in milliseconds
            let mass = pow(10.0, (((timeDiff - 30) / 1970) * 6.0) + 9)
            
            let firstPoint = touchedPoints.first
            let lastPoint = touchedPoints.last
            let locationXDiff = (lastPoint?.x)! - (firstPoint?.x)!
            let locationYDiff = (lastPoint?.y)! - (firstPoint?.y)!
            
            var swipeDist: Double = Double(locationXDiff * locationXDiff + locationYDiff * locationYDiff)
            swipeDist = swipeDist.squareRoot() * Double(self.scaleFactor!)
            let velocityMagnitude = (((swipeDist - 30) / 820) * 149) + 1
            
            let lowerValue = -500.0
            let upperValue = 500.0
            let locationZDiff = CGFloat(arc4random_uniform(UInt32(upperValue - lowerValue + 1))) + CGFloat(lowerValue)
            
            let radius = ((timeDiff + 30) / 1970 * 199)//0 - 200
            //            Y = (zCoord-A)/(B-A) * (D-C) + C
            //X = radius
            //A minTimediff
            //B maxTimediff
            //C 1
            //D 200
            //Y Sonuc
            
            var velocityThetaX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(Double(locationYDiff * locationYDiff + locationZDiff * locationZDiff)), Double(locationXDiff)))
            var velocityThetaY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(Double(locationZDiff * locationZDiff + locationXDiff * locationXDiff)), Double(locationYDiff)))
            var velocityThetaZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(Double(locationYDiff * locationYDiff + locationXDiff * locationXDiff)), Double(locationZDiff)))

            if(velocityThetaX < 0){
                velocityThetaX += 360
            }
            if(velocityThetaY < 0){
                velocityThetaY += 360
            }
            if(velocityThetaZ < 0){
                velocityThetaZ += 360
            }
            
            obj = SimpleObject(mass: mass, radius: Double(radius), velocity: Velocity(magnitude: velocityMagnitude, xAngle: velocityThetaX, yAngle: velocityThetaY, zAngle: velocityThetaZ), color: getNewColor(), point: Point(x: Double(touchedPoints[0].x), y: Double(touchedPoints[0].y), z: Double(locationZDiff)))
        }
    }
    
    private func convertToCoordinatePoint(point: CGPoint!)-> CGPoint {
        let diffToCenterX = abs(point.x - screenCenter!.x)
        let diffToCenterY = abs(point.y - screenCenter!.y)
        var coorPnt: CGPoint?
        if (point.x > screenCenter!.x){
            if(point.y > screenCenter!.y){
                coorPnt = CGPoint(x: diffToCenterX, y: diffToCenterY * -1)//(+,-)
            }else{
                coorPnt = CGPoint(x: diffToCenterX, y: diffToCenterY)//(+,+)
            }
        }else{
            if(point.y > screenCenter!.y){
                coorPnt = CGPoint(x: diffToCenterX * -1, y: diffToCenterY * -1)//(-,-)
            }else{
                coorPnt = CGPoint(x: diffToCenterX * -1, y: diffToCenterY)//(-,+)
            }
        }
        
        coorPnt!.x  = coorPnt!.x / scaleFactor!
        coorPnt!.y  = coorPnt!.y / scaleFactor!
        
        return coorPnt!
    }
    
    func getNewColor() -> UIColor{
        if let colors = self.colors{
            if(colors.count == 0){
                self.colors = [UIColor.blue, UIColor.brown, UIColor.cyan, UIColor.gray, UIColor.green, UIColor.magenta,
                          UIColor.orange, UIColor.purple, UIColor.red, UIColor.white, UIColor.yellow]
            }
            
            let index = Int(arc4random_uniform(UInt32(colors.count)))
            let color = self.colors![index]
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue:&b, alpha: &a)
            
            let newColor = UIColor(red: r, green: g, blue: b, alpha: a)
            self.colors!.remove(at: index)
            return newColor
        }
        
        return UIColor.white
    }
}
