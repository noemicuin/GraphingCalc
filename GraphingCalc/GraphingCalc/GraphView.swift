//
//  GraphView.swift
//  GraphingCalc
//
//  Created by Noemi Cuin on 12/26/16.
//  Copyright © 2016 Noemi Cuin. All rights reserved.
//

import Foundation
import UIKit


import UIKit

protocol GraphViewDataSource: class {
    func yForX(x: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {
    
    
    @IBInspectable
    var color: UIColor = UIColor.blueColor() {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable
    var scale: CGFloat = 1.0 {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable
    var origin: CGPoint = CGPointZero {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable
    var lineWidth: CGFloat = 2.0 {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable
    var axesColor: UIColor = UIColor.blackColor() {
        didSet { setNeedsDisplay() }
    }
    
    weak var dataSource: GraphViewDataSource?
    
    override func drawRect(rect: CGRect) {
        let graphCurve = UIBezierPath()
        var graphStart = true
        for rectX in Int(rect.minX)...Int(rect.maxX) {
            let graphX = (Double(rectX)-Double(origin.x))/Double(scale)
            if let graphY = dataSource?.yForX(graphX) {
                let rectY = origin.y-CGFloat(graphY)*scale
                let graphPoint = CGPoint(x: CGFloat(rectX), y: CGFloat(rectY))
                if graphStart == true {
                    graphCurve.moveToPoint(graphPoint)
                    graphStart = false
                } else {
                    graphCurve.addLineToPoint(graphPoint)
                }
            } else {
                graphStart = true
            }
        }
        color.set()
        graphCurve.lineWidth = lineWidth
        graphCurve.stroke()
        
        let axesDrawer = AxesDrawer(color: axesColor, contentScaleFactor: super.contentScaleFactor)
        axesDrawer.drawAxesInRect(self.bounds, origin: origin, pointsPerUnit: scale)
    }
    
    
}