//
//  NodalityInputOutputRenderers.swift
//  NodalityThree
//
//  Created by Simon Gladman on 13/10/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit

class DemoInputRowRenderer: SNInputRowRenderer
{
    let label = UILabel()
    let line = CAShapeLayer()
    
    override func didMoveToSuperview()
    {
        backgroundColor = UIColor.lightGray
        
        addSubview(label)
        layer.addSublayer(line)
        
        line.strokeColor = UIColor.white.cgColor
        line.lineWidth = 1
        
        if superview != nil
        {
            reload()
        }
    }
    
    override var inputNode: SNNode?
    {
        didSet
        {
            super.inputNode = inputNode
            
            updateLabel()
        }
    }
    
    override func reload()
    {
        updateLabel()
    }
    
    func updateLabel()
    {
        guard let node = parentNode.nodalityNode, index < (parentNode.nodalityNode?.type.inputSlots.count)! else
        {
            label.text = ""
            return
        }
        
        label.text = node.type.inputSlots[index].label
        
        let value = node.getInputValueAt(index: index)
        
        switch value
        {
        case NodeValue.Number(let floatValue):
            let valueAsString = String(format: "%.2f", floatValue ?? 0)
            label.text = label.text! + (node.type.inputSlots[index].type.typeName == SNNumberTypeName ? ": \(valueAsString)" : "")
            
        default:
            label.text = inputNode?.nodalityNode?.type.rawValue ?? ""
        }
        
    }
    
    override var intrinsicContentSize: CGSize
    {
        return CGSize(width: SNWidgetWidth, height: SNNodeWidget.titleBarHeight)
    }
    
    override func layoutSubviews()
    {
        label.frame = bounds.insetBy(dx: 5, dy: 0)
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: bounds.height))
        linePath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        
        if index == 0
        {
            linePath.move(to: CGPoint(x: 0, y: 1))
            linePath.addLine(to: CGPoint(x: bounds.width, y: 1))
        }
        
        line.path = linePath.cgPath
    }
}

// ----

class DemoOutputRowRenderer: SNOutputRowRenderer
{
    let label = UILabel()
    let line = CAShapeLayer()
    
    override func didMoveToSuperview()
    {
        backgroundColor = UIColor.darkGray
        
        addSubview(label)
        layer.addSublayer(line)
        
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.right
        
        line.strokeColor = UIColor.white.cgColor
        line.lineWidth = 1
        
        if superview != nil
        {
            reload()
        }
    }
    
    override var intrinsicContentSize: CGSize
    {
        return CGSize(width: SNWidgetWidth, height: SNNodeWidget.titleBarHeight)
    }
    
    override func reload()
    {
        updateLabel()
    }
    
    func updateLabel()
    {
        let value = String(format: "%.2f", node?.nodalityNode?.value?.numberValue ?? 0)
        
        let outputTypeName = node?.nodalityNode?.outputTypeName ?? ""
        
        label.text = (outputTypeName == SNNumberTypeName) ? value : node?.nodalityNode?.outputType.typeName
    }
    
    override func layoutSubviews()
    {
        label.frame = bounds.insetBy(dx: 5, dy: 0)
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: 0))
        linePath.addLine(to: CGPoint(x: bounds.width, y: 0))
        
        line.path = linePath.cgPath
    }
}
