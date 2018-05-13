//
//  ViewController.swift
//  newtonsgravity
//
//  Created by Kutay Agbal on 09/10/2017.
//  Copyright © 2017 Kutay Agbal. All rights reserved.
//

import UIKit

class DrawerViewController: UIViewController {
    var screenCenter: Point?
    var screenCenter3d: Point?
    var isSimulating: Bool?
    var drawingOk: Bool = true
    var firstLoop: Bool = true
    var followIndex: Int = 0
    var totalScore: Int = 0
    var scoreBoardLabel: UILabel?
    var sleepSlider: UISlider?
    var isFirstObject: Bool = true
    var sleepCounter: Double = 100000.0
    var resetScale: CGFloat? = nil
    var scaleFactor: Double = 0.7{
        didSet{
            simpleObjectRecognizer.scaleFactor = CGFloat(scaleFactor)
        }
    }    
    var pinchChangeCount: Int = 0
    
    var simpleObjectRecognizer: SimpleObjectGestureRecognizer!
    
    let G: Double = 0.00000000006673
    var pageWillBeRemoved: Bool = false
    
    var colors: [UIColor] = [UIColor.blue, UIColor.brown, UIColor.cyan, UIColor.gray, UIColor.green, UIColor.magenta,
                             UIColor.orange, UIColor.purple, UIColor.red, UIColor.white, UIColor.yellow]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetScale = view.contentScaleFactor
        
        screenCenter = Point(x: Double(self.view.frame.width / 2), y: Double(self.view.frame.height / 2))
        screenCenter3d = Point(x: Double(self.view.frame.width / 2), y: Double(self.view.frame.height / 2), z: 0.0)
        
        self.view.backgroundColor = UIColor.black
        
        scoreBoardLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 21))
        scoreBoardLabel!.center = CGPoint(x: 50, y: 30)//(screenCenter?.x)!, y: 10)
        scoreBoardLabel!.textAlignment = .center
        scoreBoardLabel!.text = String(totalScore)
        scoreBoardLabel!.textColor = UIColor.white
        scoreBoardLabel!.tag = 0
        scoreBoardLabel!.font = scoreBoardLabel!.font.withSize(20)
        self.view.addSubview(scoreBoardLabel!)
        
        simpleObjectRecognizer = SimpleObjectGestureRecognizer(target: self, action: #selector(self.simpleObjectGesture(recognizer:)))
        simpleObjectRecognizer.screenCenter = CGPoint(x: (self.screenCenter?.x)!, y: (self.screenCenter?.y)!)
        simpleObjectRecognizer.colors = colors
        simpleObjectRecognizer.isFirstObj = true
        simpleObjectRecognizer.scaleFactor = CGFloat(scaleFactor)
        view.addGestureRecognizer(simpleObjectRecognizer)
        
        sleepSlider = UISlider(frame: CGRect(x: 0, y: 50, width: 200, height: 10))
        sleepSlider!.tag = 0
        sleepSlider!.minimumValue = 1
        sleepSlider!.maximumValue = 1000
        sleepSlider!.isContinuous = true
        sleepSlider!.addTarget(self, action: #selector(self.setSleepInterval(slider:)), for: .valueChanged)
        sleepSlider!.value = 1000
        view.addSubview(sleepSlider!)
        
        calculateNewPointsAndDrawObjects()
    }

    func setSleepInterval(slider: UISlider!) {
        sleepCounter = Double(slider.value)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.screenCenter = Point(x: Double(self.view.frame.width / 2), y: Double(self.view.frame.height / 2))
        self.screenCenter3d = Point(x: Double(self.view.frame.width / 2), y: Double(self.view.frame.height / 2), z: 0.0)
        self.simpleObjectRecognizer.screenCenter = CGPoint(x: (self.screenCenter?.x)!, y: (self.screenCenter?.y)!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    

    func simpleObjectGesture(recognizer: SimpleObjectGestureRecognizer) {
        if recognizer.state == .ended {
            recognizer.createSimpleObject3d()
            if let obj = recognizer.obj{
                ObjectListManager.sharedObjListManager.addObject(obj)
            }
        }
    }
    
    @IBAction func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .changed {
            if recognizer.scale < 1.0{
                if scaleFactor > 0.2{
                    scaleFactor -= 0.02
                }
            }else{
                if scaleFactor < 1.0{
                    scaleFactor += 0.02
                }
            }
        }
    }
    
    private func calculateNewPointsAndDrawObjects(){
        DispatchQueue.global(qos: .userInitiated).async { [weak self]
            () -> Void in
            if let strongSelf = self{ 
                while strongSelf.pageWillBeRemoved != true{ //strongSelf.firstLoop == true || ObjectListManager.sharedObjListManager.objectList.count != 0 {
                    usleep(useconds_t(strongSelf.sleepCounter))
                    
                    if ObjectListManager.sharedObjListManager.followObj.mass != -1{
                        let newPointForFollowObj = strongSelf.calculateNewPointForFollowObj()
                        var centerDeltaDiff: (deltaX: Double, deltaY: Double, deltaZ: Double)
                        centerDeltaDiff.deltaX = newPointForFollowObj.x
                        centerDeltaDiff.deltaY = newPointForFollowObj.y
                        centerDeltaDiff.deltaZ = newPointForFollowObj.z
                        
                        for (i, obj) in ObjectListManager.sharedObjListManager.objectList.enumerated() {
                            //Calculate new point for object
                            let newPoint = strongSelf.calculateNewPoint(obj: obj, objIndex: i, centerDeltaDiff: centerDeltaDiff)
                            obj.oldPoint = Point(x: obj.point.x, y: obj.point.y, z: obj.point.z)
                            obj.point = newPoint
                            
                            //Remove object if necessary
                            //follow object'e uzaklik olmali, burada (0,0,0)'a uzaklik aliniyor oysa follow object de coordinat duzleminde ilerliyor
                            if newPoint.x > 1000 / strongSelf.scaleFactor || newPoint.x < -1000 / strongSelf.scaleFactor
                                || newPoint.y > 1000 / strongSelf.scaleFactor || newPoint.y < -1000 / strongSelf.scaleFactor
                                || newPoint.z < -1000 / strongSelf.scaleFactor || newPoint.z < -1000 / strongSelf.scaleFactor
                            {
                                ObjectListManager.sharedObjListManager.removeObject(i)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            strongSelf.drawAll()
                        }
                    }
                }
            }
        }
    }
    
    private func convertSortToDrawPoint()-> [(radius: Double, color: UIColor, point: Point)] {
        var drawPoint: (radius: Double, color: UIColor, point: Point)
        var drawPointList: [(radius: Double, color: UIColor, point: Point)] = []
        if let center = screenCenter3d{
            for obj in ObjectListManager.sharedObjListManager.objectList{
                drawPoint = (obj.radius, obj.color, Point(x: center.x + (obj.point.x * scaleFactor), y: center.y - (obj.point.y * scaleFactor), z: center.z + (obj.point.z * scaleFactor)))
                drawPointList.append(drawPoint)
            }
            
            //add follow object's draw point
            let obj = ObjectListManager.sharedObjListManager.followObj
            drawPoint = (obj.radius, obj.color, Point(x: center.x, y: center.y, z: center.z))
            drawPointList.append(drawPoint)
        }
        
        return drawPointList.sorted(by: {$0.point.z > $1.point.z})
    }
    
    public func drawAll(){
        //Clear screen
        for layer in self.view.layer.sublayers!{
            if layer.name == "s"{
                layer.removeFromSuperlayer()
            }
        }
        
        let drawPointList = self.convertSortToDrawPoint()
        
        for drawPoint in drawPointList{
            let radius = (drawPoint.radius * 90) / (1000 + drawPoint.point.z) * self.scaleFactor
            
            self.view.layer.addSublayer(self.getShapeLayer(radius: CGFloat(radius), center: CGPoint(x: drawPoint.point.x, y: drawPoint.point.y), color: drawPoint.color.cgColor))
        }
    }

    
    private func getShapeLayer(radius: CGFloat, center: CGPoint, color: CGColor) -> CALayer{
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: center.x, y: center.y), radius: (CGFloat(radius)), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = color
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 1
        shapeLayer.opacity = 1.0//Float(Double((drawPoint.pointIndex)) / Double(self.objList[drawPoint.objIndex].points.count)) / Float(self.scaleFactor * 10)
        shapeLayer.name = "s"
        return shapeLayer
    }
    
    private func sortDrawObjects3d(objList: [SimpleObject])-> [(index: Int,obj: SimpleObject)]{
        var drawObj: (index: Int,obj: SimpleObject)
        var drawObjList: [(index: Int,obj: SimpleObject)] = []
    
        for (i, obj) in objList.enumerated(){
            drawObj = (i, SimpleObject(mass: obj.mass, radius: obj.radius, velocity: obj.velocity, color: obj.color, point: obj.point))
            drawObjList.append(drawObj)
        }
        
        return drawObjList.sorted(by: {$0.obj.point.z < $1.obj.point.z})
    }
    
    private func convertToDrawPoint(point: Point!)-> Point {
        var drawPoint: Point?
        
        if let center = screenCenter{
            drawPoint = Point(x: center.x + point.x * scaleFactor, y: center.y - (point.y * scaleFactor))
        }
        return drawPoint!
    }
    
    
    
    private func calculateNewPoint(obj: SimpleObject, objIndex: Int, centerDeltaDiff :(deltaX: Double, deltaY: Double, deltaZ: Double)) -> Point{
        var xCompOfGraVel: Double = 0;
        var yCompOfGraVel: Double = 0;
        var zCompOfGraVel: Double = 0;
        
        let origin = obj.oldPoint
        
        for (i, otherObj) in ObjectListManager.sharedObjListManager.objectList.enumerated(){
            if (i != objIndex){
                let otherOrigin = otherObj.oldPoint
                
                var distance: Double = (origin.x - otherOrigin.x) * (origin.x - otherOrigin.x) + (origin.y - otherOrigin.y) * (origin.y - otherOrigin.y) + (origin.z - otherOrigin.z) * (origin.z - otherOrigin.z)
                distance = distance.squareRoot()
                
                let magOfGraVel: Double = G * otherObj.mass /*(time * time)*/ / (distance * distance) // add (time * time) later
                
                var thetaOfGraVelX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.x - origin.x)))
                var thetaOfGraVelY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.x - origin.x) * (otherOrigin.x - origin.x) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.y - origin.y)))
                var thetaOfGraVelZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.x - origin.x) * (otherOrigin.x - origin.x)), Double(otherOrigin.z - origin.z)))
                
                if(thetaOfGraVelX < 0){
                    thetaOfGraVelX += 360
                }
                if(thetaOfGraVelY < 0){
                    thetaOfGraVelY += 360
                }
                if(thetaOfGraVelZ < 0){
                    thetaOfGraVelZ += 360
                }
                
                xCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelX))
                
                yCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelY))
                
                zCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelZ))
            }
        }
        
        //Follow Object Gravitation Effect
        let otherOrigin = Point(x: 0.0, y: 0.0, z: 0.0)
        
        var distance: Double = (origin.x - otherOrigin.x) * (origin.x - otherOrigin.x) + (origin.y - otherOrigin.y) * (origin.y - otherOrigin.y) + (origin.z - otherOrigin.z) * (origin.z - otherOrigin.z)
        distance = distance.squareRoot()
        
        let magOfGraVel: Double = G * ObjectListManager.sharedObjListManager.followObj.mass /*(time * time)*/ / (distance * distance) // add (time * time) later
        
        var thetaOfGraVelX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.x - origin.x)))
        var thetaOfGraVelY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.x - origin.x) * (otherOrigin.x - origin.x) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.y - origin.y)))
        var thetaOfGraVelZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.x - origin.x) * (otherOrigin.x - origin.x)), Double(otherOrigin.z - origin.z)))
        
        if(thetaOfGraVelX < 0){
            thetaOfGraVelX += 360
        }
        if(thetaOfGraVelY < 0){
            thetaOfGraVelY += 360
        }
        if(thetaOfGraVelZ < 0){
            thetaOfGraVelZ += 360
        }
        
        xCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelX))
        
        yCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelY))
        
        zCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelZ))
        //Follow Object Gravitation Effect
        
        let xCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.xAngle!))
        let yCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.yAngle!))
        let zCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.zAngle))
        
        let totalXVelocity: Double =  xCompOfObjVel + xCompOfGraVel
        let totalYVelocity: Double =  yCompOfObjVel + yCompOfGraVel
        let totalZVelocity: Double =  zCompOfObjVel + zCompOfGraVel
        
        var newVelMag: Double = ((xCompOfObjVel + xCompOfGraVel) * (xCompOfObjVel + xCompOfGraVel)) +
            ((yCompOfObjVel + yCompOfGraVel) * (yCompOfObjVel + yCompOfGraVel)) +
            ((zCompOfObjVel + zCompOfGraVel) * (zCompOfObjVel + zCompOfGraVel))
        newVelMag = newVelMag.squareRoot()
        
        var newVelThetaX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalYVelocity * totalYVelocity + totalZVelocity * totalZVelocity), totalXVelocity))
        var newVelThetaY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalXVelocity * totalXVelocity + totalZVelocity * totalZVelocity), totalYVelocity))
        var newVelThetaZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalYVelocity * totalYVelocity + totalXVelocity * totalXVelocity), totalZVelocity))
        
        if(newVelThetaX < 0){
            newVelThetaX += 360
        }
        if(newVelThetaY < 0){
            newVelThetaY += 360
        }
        if(newVelThetaZ < 0){
            newVelThetaZ += 360
        }
        
        let newVelosity = Velocity(magnitude: newVelMag, xAngle: newVelThetaX, yAngle: newVelThetaY, zAngle: newVelThetaZ)
        
        obj.velocity = newVelosity
        
        let totalXMove: Double = totalXVelocity //* time
        let totalYMove: Double = totalYVelocity //* time;
        let totalZMove: Double = totalZVelocity //* time
        
        //Center Delta Diff effect
        let newPoint = Point(x: totalXMove + origin.x, y: totalYMove + origin.y, z: totalZMove + origin.z)
        newPoint.x = newPoint.x - centerDeltaDiff.deltaX
        newPoint.y = newPoint.y - centerDeltaDiff.deltaY
        newPoint.z = newPoint.z - centerDeltaDiff.deltaZ
        
        return newPoint;
        
    }
    
    private func calculateNewPointForFollowObj() -> Point{
        var xCompOfGraVel: Double = 0;
        var yCompOfGraVel: Double = 0;
        var zCompOfGraVel: Double = 0;
        
        let obj = ObjectListManager.sharedObjListManager.followObj
        let origin = ObjectListManager.sharedObjListManager.followObj.point
        
        for otherObj in ObjectListManager.sharedObjListManager.objectList{
            let otherOrigin = otherObj.oldPoint
            
            var distance: Double = (origin.x - otherOrigin.x) * (origin.x - otherOrigin.x) + (origin.y - otherOrigin.y) * (origin.y - otherOrigin.y) + (origin.z - otherOrigin.z) * (origin.z - otherOrigin.z)
            distance = distance.squareRoot()
            
            let magOfGraVel: Double = G * otherObj.mass /*(time * time)*/ / (distance * distance) // add (time * time) later
            
            var thetaOfGraVelX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.x - origin.x)))
            var thetaOfGraVelY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.x - origin.x) * (otherOrigin.x - origin.x) + (otherOrigin.z - origin.z) * (otherOrigin.z - origin.z)), Double(otherOrigin.y - origin.y)))
            var thetaOfGraVelZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt((otherOrigin.y - origin.y) * (otherOrigin.y - origin.y) + (otherOrigin.x - origin.x) * (otherOrigin.x - origin.x)), Double(otherOrigin.z - origin.z)))
            
            if(thetaOfGraVelX < 0){
                thetaOfGraVelX += 360
            }
            if(thetaOfGraVelY < 0){
                thetaOfGraVelY += 360
            }
            if(thetaOfGraVelZ < 0){
                thetaOfGraVelZ += 360
            }
            
            xCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelX))
            
            yCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelY))
            
            zCompOfGraVel += magOfGraVel * cos(DegreeRadians.degreesToRadians(deg: thetaOfGraVelZ))
        }
        
        let xCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.xAngle!))
        let yCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.yAngle!))
        let zCompOfObjVel: Double = obj.velocity.magnitude * cos(DegreeRadians.degreesToRadians(deg: obj.velocity.zAngle))
        
        let totalXVelocity: Double =  xCompOfObjVel + xCompOfGraVel
        let totalYVelocity: Double =  yCompOfObjVel + yCompOfGraVel
        let totalZVelocity: Double =  zCompOfObjVel + zCompOfGraVel
        
        var newVelMag: Double = ((xCompOfObjVel + xCompOfGraVel) * (xCompOfObjVel + xCompOfGraVel)) +
            ((yCompOfObjVel + yCompOfGraVel) * (yCompOfObjVel + yCompOfGraVel)) +
            ((zCompOfObjVel + zCompOfGraVel) * (zCompOfObjVel + zCompOfGraVel))
        newVelMag = newVelMag.squareRoot()
        
        var newVelThetaX: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalYVelocity * totalYVelocity + totalZVelocity * totalZVelocity), totalXVelocity))
        var newVelThetaY: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalXVelocity * totalXVelocity + totalZVelocity * totalZVelocity), totalYVelocity))
        var newVelThetaZ: Double = DegreeRadians.radiansToDegrees(rad: atan2(sqrt(totalYVelocity * totalYVelocity + totalXVelocity * totalXVelocity), totalZVelocity))
        
        if(newVelThetaX < 0){
            newVelThetaX += 360
        }
        if(newVelThetaY < 0){
            newVelThetaY += 360
        }
        if(newVelThetaZ < 0){
            newVelThetaZ += 360
        }
        
        let newVelosity = Velocity(magnitude: newVelMag, xAngle: newVelThetaX, yAngle: newVelThetaY, zAngle: newVelThetaZ)
        
        obj.velocity = newVelosity
        
        let totalXMove: Double = totalXVelocity //* time
        let totalYMove: Double = totalYVelocity //* time;
        let totalZMove: Double = totalZVelocity //* time
        
        return Point(x: totalXMove + origin.x, y: totalYMove + origin.y, z: totalZMove + origin.z);
        
    }
}

public class DegreeRadians{
    static func degreesToRadians(deg: Double) -> Double {
        return deg * .pi / 180
    }
    
    static func radiansToDegrees(rad: Double) -> Double {
        return rad * 180 / .pi
    }
}

