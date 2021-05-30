//
//  Interpreter.swift
//  Lox
//
//  Created by Алексей Якименко on 29.05.2021.
//

import Foundation

struct RuntimeError: Error {
    let `operator`: Token
    let message: String
}

final class Interpreter {
    
    private let printer: Printer
    
    init(_ printer: Printer = StandardPrinter()) {
        self.printer = printer
    }

    func interpret(_ expr: Expr) {
        do {
            let value = try evaluate(expr)
            printer.print(stringify(value))
        } catch {
            let error = error as! RuntimeError
            Lox.error(error)
        }
    }
}

extension Interpreter: Visitor {
    
    func visitBinaryExpr(_ expr: Binary) throws -> Any? {
        let left = try evaluate(expr.left)
        let right = try evaluate(expr.right)
        
        switch expr.operator.type {
        case .minus:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) - (right as! Double)
        case .slash:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) / (right as! Double)
        case .star:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) * (right as! Double)
        case .plus:
            switch (left, right) {
            case (let left as String, let right as String): return left + right
            case (let left as Double, let right as Double): return left + right
            default: throw RuntimeError(operator: expr.operator,
                                        message: "Operands must be two numbers or two strings.")
            }
        case .greater:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) > (right as! Double)
        case .greaterEqual:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) >= (right as! Double)
        case .less:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) < (right as! Double)
        case .lessEqual:
            try checkNumberOperands(expr.operator, left, right)
            return (left as! Double) <= (right as! Double)
        case .bangEqual:
            return !isEqual(left, right)
        case .equalEqual:
            return isEqual(left, right)
        default: return nil
        }
    }
    
    func visitGroupingExpr(_ expr: Grouping) throws -> Any? {
        try expr.expressions.map { try evaluate($0) as Any }.last
    }
    
    func visitLiteralExpr(_ expr: Literal) throws -> Any? {
        switch expr.value {
        case .boolean(let boolean): return boolean
        case .number(let number): return number
        case .string(let string): return string
        case .none: return nil
        }
    }
    
    func visitUnaryExpr(_ expr: Unary) throws -> Any? {
        let right = try evaluate(expr.right)
        switch expr.operator.type {
        case .minus:
            try checkNumberOperand(expr.operator, right)
            return  -(right as! Double)
        case .bang: return !isTruthy(right)
        default: return nil
        }
    }
}

private extension Interpreter {
    
    func evaluate(_ expr: Expr) throws -> Any? {
        try expr.accept(visitor: self)
    }
    
    func isTruthy(_ object: Any?) -> Bool {
        if object == nil { return false }
        if let boolean = object as? Bool { return boolean }
        return true
    }
    
    func stringify(_ object: Any?) -> String {
        switch object {
        case .none: return "nil"
        case .some(let some):
            switch some {
            case let object as Bool:
                return String(object)
            case let object as String:
                return object
            case let object as Double:
                let formatter = NumberFormatter()
                formatter.minimumFractionDigits = 0
                formatter.numberStyle = .decimal
                return formatter.string(from: NSNumber(value: object))!
            default: fatalError()
            }
        }
    }
    
    func isEqual(_ left: Any?, _ right: Any?) -> Bool {
        switch (left, right) {
        case (nil, nil): return true
        case (nil, _): return false
        case (let left as String, let right as String): return left == right
        case (let left as Bool, let right as Bool): return left == right
        case (let left as Double, let right as Double): return left == right
        default: return false
        }
    }
    
    func checkNumberOperand(_ token: Token, _ object: Any?) throws {
        if object is Double { return }
        throw RuntimeError(operator: token, message: "Operand must be a number.")
    }
    
    func checkNumberOperands(_ token: Token, _ left: Any?, _ right: Any?) throws {
        if left is Double, right is Double  { return }
        throw RuntimeError(operator: token, message: "Operands must be a number.")
    }
}
