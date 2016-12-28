//
//  GraphViewController.swift
//  GraphingCalc
//
//  Created by Noemi Cuin on 12/27/16.
//  Copyright © 2016 Noemi Cuin. All rights reserved.
//

import Foundation
import UIKit

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIPopoverPresentationControllerDelegate {
    private struct Constants {
        static let ScaleAndOrigin = "scaleAndOrigin"
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            if let scaleAndOrigin = userDefaults.objectForKey(Constants.ScaleAndOrigin) as? [String: String] {
                graphView.scaleAndOrigin = scaleAndOrigin
            }
        }
    }
    
    var program: AnyObject?
    var graphLabel: String? {
        didSet {
            title = graphLabel
        }
    }
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    func graphPlot(sender: GraphView) -> [(x: Double, y: Double)]? {
        let minXDegree = Double(sender.minX) * (180 / M_PI)
        let maxXDegree = Double(sender.maxX) * (180 / M_PI)
        
        var plots = [(x: Double, y: Double)]()
        let brain = CalculatorBrain()
        
        if let program = program {
            brain.program = program
            
            // Performance fix to remove sluggish behavior (specially when screen is zoomed out):
            // a. the difference between minXDegree and maxXDegree will be high when zoomed out
            // b. the screen width has a fixed number of pixels, so we need to iterate only
            //    for the number of available pixels
            // c. loopIncrementSize ensures that the count of var plots will always be fixed to
            //    the number of available pixels for screen width
            let loopIncrementSize = (maxXDegree - minXDegree) / sender.availablePixelsInXAxis
            
            for (var i = minXDegree; i <= maxXDegree; i = i + loopIncrementSize) {
                let radian = Double(i) * (M_PI / 180)
                brain.variableValues["M"] = radian
                let evaluationResult = brain.evaluateAndReportErrors()
                switch evaluationResult {
                case let .Success(y):
                    if y.isNormal || y.isZero {
                        plots.append((x: radian, y: y))
                    }
                default: break
                }
            }
        }
        
        return plots
    }
    
    @IBAction func zoomGraph(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            graphView.scale *= gesture.scale
            
            // save the scale
            saveScaleAndOrigin()
            gesture.scale = 1
        }
    }
    
    @IBAction func moveGraph(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(graphView)
            
            if graphView.graphOrigin == nil {
                graphView.graphOrigin = CGPoint(
                    x: graphView.center.x + translation.x,
                    y: graphView.center.y + translation.y)
            } else {
                graphView.graphOrigin = CGPoint(
                    x: graphView.graphOrigin!.x + translation.x,
                    y: graphView.graphOrigin!.y + translation.y)
            }
            
            // save the graphOrigin
            saveScaleAndOrigin()
            
            // set back to zero, otherwise will be cumulative
            gesture.setTranslation(CGPointZero, inView: graphView)
        default: break
        }
    }
    
    @IBAction func moveOrigin(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            graphView.graphOrigin = gesture.locationInView(view)
            
            // save the graphOrigin
            saveScaleAndOrigin()
        default: break
        }
    }
    
    private func saveScaleAndOrigin() {
        userDefaults.setObject(graphView.scaleAndOrigin, forKey: Constants.ScaleAndOrigin)
        userDefaults.synchronize()
    }
    
    // Detect device rotation and adjust origin to center instead of upper-left:
    // if graph origin is far off center, then rotation change might move it off-screen so
    // calcualtion also makes a subtle adjustment based on the ratio of the height and with change
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        var xDistanceFromCenter: CGFloat = 0
        var yDistanceFromCenter: CGFloat = 0
        if let graphOrigin = graphView.graphOrigin {
            xDistanceFromCenter = graphView.center.x - graphOrigin.x
            yDistanceFromCenter = graphView.center.y - graphOrigin.y
        }
        
        let widthBeforeRotation = graphView.bounds.width
        let heightBeforeRotation = graphView.bounds.height
        
        coordinator.animateAlongsideTransition(nil) { context in
            
            let widthAfterRotation = self.graphView.bounds.width
            let heightAfterRotation = self.graphView.bounds.height
            
            let widthChangeRatio = widthAfterRotation / widthBeforeRotation
            let heightChangeRatio = heightAfterRotation / heightBeforeRotation
            
            self.graphView.graphOrigin = CGPoint(
                x: self.graphView.center.x - (xDistanceFromCenter * widthChangeRatio),
                y: self.graphView.center.y - (yDistanceFromCenter * heightChangeRatio)
            )
        }
    }
    
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}