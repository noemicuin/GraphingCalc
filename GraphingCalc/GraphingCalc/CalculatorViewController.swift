//
//  CalculatorViewController.swift
//  GraphingCalc
//
//  Created by Noemi Cuin on 12/26/16.
//  Copyright © 2016 Noemi Cuin. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    var value: Double? {
        get {
            return NSNumberFormatter().numberFromString(self.text!) as? Double
        }
        set {
            self.text = newValue != nil ? "\(newValue!)" : " "
        }
    }
}

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    var brain = CalculatorBrain()
    var userIsInTheMiddleOfTypingANumber = false
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        display.text = userIsInTheMiddleOfTypingANumber ? display.text! + digit : digit
        userIsInTheMiddleOfTypingANumber = true
    }
    
    @IBAction func appendPeriod(sender: UIButton) {
        if display.text!.rangeOfString(".") == nil {
            appendDigit(sender)
        }
    }
    
    @IBAction func appendSign(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber && display.value != nil {
            display.value = -display.value!
        } else {
            operate(sender)
        }
    }
    
    @IBAction func pushConstant(sender: UIButton) {
        let constant = sender.currentTitle!
        enter()
        display.text = constant
        brain.pushOperation(constant)
        history.text = brain.description
    }
    
    @IBAction func pushMemory(sender: UIButton) {
        let variable = sender.currentTitle!
        enter()
        display.text = variable
        brain.pushVariable(variable)
        history.text = brain.description
    }
    
    @IBAction func setMemory(sender: UIButton) {
        var variable = sender.currentTitle!
        variable.removeAtIndex(variable.startIndex)
        userIsInTheMiddleOfTypingANumber = false
        if let displayValue = display.value {
            brain.variableValues[variable] = displayValue
            display.text = brain.text
            history.text = brain.description+"="
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        let operation = sender.currentTitle!
        enter()
        brain.pushOperation(operation)
        display.text = brain.text
        history.text = brain.description+"="
    }
    
    @IBAction func undo() {
        if userIsInTheMiddleOfTypingANumber {
            if countElements(display.text!) > 1 {
                display.text = dropLast(display.text!)
            } else {
                userIsInTheMiddleOfTypingANumber = false
                display.value = 0
            }
        } else {
            brain.pop()
            display.value = 0
            history.text = brain.description
        }
    }
    
    @IBAction func clear() {
        userIsInTheMiddleOfTypingANumber = false
        brain.clearAll()
        display.value = 0
        history.text = ""
    }
    
    @IBAction func enter() {
        if userIsInTheMiddleOfTypingANumber && display.value != nil {
            brain.pushOperand(display.value!)
            history.text = brain.description
        }
        userIsInTheMiddleOfTypingANumber = false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as? UIViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        if let graphViewController = destination as? GraphViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case "Show Graph":
                    graphViewController.program = brain.program;
                default:
                    break
                }
            }
        }
    }
    
    
}
