//
//  GraphViewController.swift
//  GraphingCalc
//
//  Created by Noemi Cuin on 12/27/16.
//  Copyright © 2016 Noemi Cuin. All rights reserved.
//

import Foundation
import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }
    
    @IBAction func tapGraph(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            let translation = gesture.locationInView(graphView)
            graphView.origin.x = translation.x
            graphView.origin.y = translation.y
        default: break
        }
    }
    @IBOutlet weak var navigationHeader: UINavigationItem!
    
    private var brain = CalculatorBrain()
    
    @IBAction func panGraph(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(graphView)
            graphView.origin.x += translation.x
            graphView.origin.y += translation.y
            gesture.setTranslation(CGPointZero, inView: graphView)
        default: break
        }
        var program: AnyObject {
            get { return brain.program }
            set { brain.program = newValue }
        }
        
        func pinchGraph(gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .Changed:
                graphView.scale *= gesture.scale
                gesture.scale = 1
            default: break
            }
        }
        
        func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            graphView.origin = view.center
        }
        
        func yForX(x: Double) -> Double? {
            brain.variableValues["M"] = x
            if let y = brain.evaluate() {
                return y
            }
            return nil
        }

    }
}