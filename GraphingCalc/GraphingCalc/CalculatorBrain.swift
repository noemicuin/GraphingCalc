//
//  CalculatorBrain.swift
//  GraphingCalc
//
//  Created by Noemi Cuin on 12/26/16.
//  Copyright © 2016 Noemi Cuin. All rights reserved.
//

import Foundation
import UIKit

enum CalculatorBrainEvaluationResult {
    case success(Double)
    case failure(String)
}



class CalculatorBrain: CustomStringConvertible
{
    
    //will contain functions for enumerating the different possibilities within the Calculator
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case Variable(String)
        case Constant(String,
            value: Double)
        case UnaryOperation(String,
            evaluate: Double -> Double,
            reportError: (Double -> String?)?)
        case BinaryOperation(String,
            precedence: Int,
            evaluate: (Double, Double) -> Double,
            reportError: ((Double, Double) -> String?)?)
        
        var description: String{
            get
            {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .Variable(let variable):
                    return variable
                case .Constant(let constant, _):
                    return constant
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _, _):
                    return symbol
            
            }//end of self
        }//end of get
    }//end of description
 }//end of private enum Op
    
    enum ValueOrError: CustomStringConvertible {
        case value(Double)
        case error(String)
        
        var description: String {
            get {
                switch self {
                case .Value(let value):
                    return "\(value)"
                case .Error(let error):
                    return error
                }
            }
        }
    }
    
    //Creating an array for operation or operand
    private var opStack = [Op]();
    
    //Creating a Dictionary to hold operations/operands
    private var knownOps = [String:Op]()
    
    var variableValues = [String:Double]()
    
    var text: String {
        return self.evaluateAndReportErrors().description
    }
    
    
    internal var description: String{
        get {
            var returnDesc = ""
            var returnOps = opStack
            repeat {
                let (additionalDesc, additionalOps) = describe(returnOps)
                returnDesc = returnDesc.isEmpty ? additionalDesc : additionalDesc+", "+returnDesc
                returnOps = additionalOps
            } while !returnOps.isEmpty
            return returnDesc
        }//end of get
    }//end of String
    
    
    
    var descriptionOfLastTerm: String {
        get {
            let (description, _) = describe(opStack)
            return description
        }
    }
    
    private func learnOp(op: Op)
    {
        knownOps[op.description] = op
        
    }
    
    
    var program: AnyObject {
        get {

            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        
                        newOpStack.append(.Operand(operand))
                    } else {
                       
                        newOpStack.append(.Variable(opSymbol))
                    }
                    opStack = newOpStack
                }
            }
        }
    }
    
    
    //initialize Op
    init(){
       
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        learnOp(Op.Constant("π",
            value: M_PI))
        learnOp(Op.UnaryOperation("±",
            evaluate: { -$0 },
            reportError: nil))
        learnOp(Op.UnaryOperation("sin",
            evaluate: { sin($0) },
            reportError: nil))
        learnOp(Op.UnaryOperation("cos",
            evaluate: { cos($0) },
            reportError: nil))
        learnOp(Op.UnaryOperation("√",
            evaluate: { sqrt($0) },
            reportError: { op1 in op1 < 0.0 ? "Square root of negative value!" : nil }))
        learnOp(Op.BinaryOperation("×",
            precedence: 150,
            evaluate: { $1*$0 },
            reportError: nil))
        learnOp(Op.BinaryOperation("÷",
            precedence: 150,
            evaluate: { $1/$0 },
            reportError: { op1, op2 in op1 == 0.0 ? "Division by zero!" : nil }))
        learnOp(Op.BinaryOperation("+",
            precedence: 140,
            evaluate: { $1+$0 },
            reportError: nil))
        learnOp(Op.BinaryOperation("−",
            precedence: 140,
            evaluate: { $1-$0 },
            reportError: nil))
        
       
        //let brain = CalculatorBrain();
        
    }
    
    
    private func describe(var currentOps: [Op], currentOpPrecedence: Int = 0) -> (description: String, remainingOps: [Op]) {
        if !currentOps.isEmpty {
            let op = currentOps.removeLast()
            switch op  {
            case .Operand:
                return (op.description, currentOps)
            case .Variable:
                return (op.description, currentOps)
            case .Constant:
                return (op.description, currentOps)
            case .UnaryOperation:
                let (operandDesc, remainingOps) = describe(currentOps)
                return ( op.description+"("+operandDesc+")", remainingOps)
            case .BinaryOperation(_, let precedence, _, _):
                let (operandDesc1, remainingOps1) = describe(currentOps, currentOpPrecedence: precedence)
                let (operandDesc2, remainingOps2) = describe(remainingOps1, currentOpPrecedence: precedence)
                if precedence < currentOpPrecedence {
                    return ("("+operandDesc2+op.description+operandDesc1+")", remainingOps2)
                } else {
                    return (operandDesc2+op.description+operandDesc1, remainingOps2)
                }
            }
        }
        return ("?", currentOps)
    }
    
    
    //used to return what's left after poping from the stack
    private func evaluate(var currentOps: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !currentOps.isEmpty {
            let op = currentOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, currentOps)
            case .Variable(let variable):
                return (variableValues[variable], currentOps)
            case .Constant(_, let value):
                return (value, currentOps)
            case .UnaryOperation(_, let operation, _):
                let (result, remainingOps) = evaluate(currentOps)
                if let operand = result {
                    return (operation(operand), remainingOps)
                }
            case .BinaryOperation(_, _, let operation, _):
                let (result1, remainingOps1) = evaluate(currentOps)
                if let operand1 = result1 {
                    let (result2, remainingOps2) = evaluate(remainingOps1)
                    if let operand2 = result2 {
                        return (operation(operand1, operand2), remainingOps2)
                    }
                }
            }
        }
        return (nil, currentOps)
    }
    
    private func evaluateAndReportErrors(var currentOps: [Op]) -> (result: ValueOrError, remainingOps: [Op]) {
        if !currentOps.isEmpty {
            let op = currentOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (ValueOrError.Value(operand), currentOps)
            case .Variable(let variable):
                if let value = variableValues[variable] {
                    return (ValueOrError.Value(value), currentOps)
                } else {
                    return (ValueOrError.Error("Variable not defined!"), currentOps)
                }
            case .Constant(_, let value):
                return (ValueOrError.Value(value), currentOps)
            case .UnaryOperation(_, let operation, let reportError):
                var value: Double
                let (result, remainingOps) = evaluateAndReportErrors(currentOps)
                switch (result) {
                case .Error:
                    return (result, remainingOps)
                case .Value(let tmp):
                    value = tmp
                }
                if let error = reportError?(value) {
                    return (ValueOrError.Error(error), currentOps)
                } else {
                    return (ValueOrError.Value(operation(value)), remainingOps)
                }
            case .BinaryOperation(_, _, let operation, let reportError):
                var value1: Double, value2 :Double
                let (result1, remainingOps1) = evaluateAndReportErrors(currentOps)
                switch result1 {
                case .Error:
                    return (result1, remainingOps1)
                case .Value(let tmp):
                    value1 = tmp
                }
                let (result2, remainingOps2) = evaluateAndReportErrors(remainingOps1)
                switch result2 {
                case .Error:
                    return (result2, remainingOps2)
                case .Value(let tmp):
                    value2 = tmp
                }
                if let error = reportError?(value1, value2) {
                    return (ValueOrError.Error(error), currentOps)
                } else {
                    return (ValueOrError.Value(operation(value1, value2)), remainingOps2)
                }
            }
        }
        return (ValueOrError.Error("Not enough operands!"), currentOps)
    }
    
    func evaluate()->Double?
    {
        let (result, remainingOps) = evaluate(opStack)
        print("\(opStack) = \(result ?? 0) with \(remainingOps) left over")
        if result != nil {
            if result!.isNaN || result!.isInfinite {
                return nil
            }
        }
        return result

    }
    
    
    func evaluateAndReportErrors() -> ValueOrError {
        let (result, remainingOps) = evaluateAndReportErrors(opStack)
        print("\(opStack) = \(result) with \(remainingOps) unevaluated")
        return result
    }
    
    func evaluateOperand(operand: Double) -> Double? {
    pushOperand(operand)
    return evaluate()
    }
    
    func evaluateOperandAndReportErrors(operand: Double) -> ValueOrError {
        pushOperand(operand)
        return evaluateAndReportErrors()
    }
    
    func evaluateVariable(variable: String) -> Double? {
        pushVariable(variable)
        return evaluate()
    }
    
    func evaluateVariable(variable: String) -> ValueOrError {
        pushVariable(variable)
        return evaluateAndReportErrors()
    }
    
    func evaluateOperation(symbol: String) -> Double? {
        pushOperation(symbol)
        return evaluate()
    }
    
    func evaluateOperationAndReportErrors(symbol: String) -> ValueOrError {
        pushOperation(symbol)
        return evaluateAndReportErrors()
    }
    
    
    
    //take double & push to stack
    func pushOperand(operand: Double) {
        opStack.append(Op.Operand(operand))
    }
    
    func pushVariable(variable: String) {
        opStack.append(Op.Variable(variable))
    }
    
    func pushOperation(symbol: String) {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
    }
    
    //take operations
    func pop() {
        opStack.removeLast()
    }
    
    func clearOpStack() {
        opStack.removeAll(keepCapacity: true)
    }
    
    func clearAll() {
        clearOpStack()
        variableValues.removeAll(keepCapacity: true)
    }
    
}