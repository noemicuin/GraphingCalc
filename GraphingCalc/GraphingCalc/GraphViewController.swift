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
            
            
            //used to make sure plots will be fixed to num of pixels for screen
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
    
    
    
    
    
    private func saveScaleAndOrigin() {
        userDefaults.setObject(graphView.scaleAndOrigin, forKey: Constants.ScaleAndOrigin)
        userDefaults.synchronize()
    }
  
    //used so graph matches rotation of phone
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