//
//  SNNodeWidget.swift
//  ShinpuruNodeUI
//
//  Created by Simon Gladman on 02/09/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import UIKit

class SNNodeWidget: UIView
{
    static let titleBarHeight: CGFloat = 44
    
    unowned let view: SNView
    unowned let node: SNNode
    var inputRowRenderers = [SNInputRowRenderer]()
    var previousPanPoint: CGPoint?
    
    lazy var titleBar: SNWidgetTitleBar =
    {
        return (SNWidgetTitleBar(parentNodeWidget: self))
    }()
    
    required init(view: SNView, node: SNNode)
    {
        self.view = view
        self.node = node
        
        super.init(frame: CGRect(origin: node.position, size: CGSize.zero))
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(SNNodeWidget.panHandler(recognizer:)))
        addGestureRecognizer(pan)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SNNodeWidget.longPressHandler(recognizer:)))
        addGestureRecognizer(longPress)
        
        setNeedsLayout()
        
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        
        alpha = 0
    }
    
    override func didMoveToSuperview()
    {
        if superview != nil
        {
            UIView.animate(withDuration: SNViewAnimationDuration,
                animations: {self.alpha = 1})
        }
    }
    
    override func removeFromSuperview()
    {
        UIView.animate(withDuration: SNViewAnimationDuration,
            animations: {self.alpha = 0},
            completion: {(_) in super.removeFromSuperview()})
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _itemRenderer: SNItemRenderer?
    
    var itemRenderer: SNItemRenderer?
    {
        if _itemRenderer == nil
        {
            _itemRenderer = view.nodeDelegate?.itemRendererForView(view: view, node: node)
        }
        
        return _itemRenderer
    }
    
    private var _outputRenderer: SNOutputRowRenderer?
    
    var outputRenderer: SNOutputRowRenderer?
    {
        if _outputRenderer == nil
        {
            _outputRenderer = view.nodeDelegate?.outputRowRendererForView(view: view, node: node)
        }
        
        return _outputRenderer
    }
    
    func buildUserInterface()
    {
        guard let itemRenderer = itemRenderer,
            let outputRenderer = outputRenderer else
        {
            return
        }
        
        // clear down...
        
        itemRenderer.removeFromSuperview()
        outputRenderer.removeFromSuperview()
        
        for inputRendeer in inputRowRenderers
        {
            inputRendeer.removeFromSuperview()
        }
        
        // set up....
        
        // title bar
        
        addSubview(titleBar)
        
        titleBar.title = node.name
        
        titleBar.frame = CGRect(x: 1,
            y: 0,
            width: itemRenderer.intrinsicContentSize.width,
            height: SNNodeWidget.titleBarHeight)
        
        // main item renderer
        
        addSubview(itemRenderer)
        
        itemRenderer.frame = CGRect(x: 1,
            y: SNNodeWidget.titleBarHeight,
            width: itemRenderer.intrinsicContentSize.width,
            height: itemRenderer.intrinsicContentSize.height)
        
        inputRowRenderers.removeAll()
        var inputOutputRowsHeight: CGFloat = SNNodeWidget.titleBarHeight
        
        for i in 0 ..< node.numInputSlots 
        {
            if let
                inputRowRenderer = view.nodeDelegate?.inputRowRendererForView(view: view, inputNode: nil, parentNode: node, index: i)
            {
                addSubview(inputRowRenderer)
                inputRowRenderers.append(inputRowRenderer)
                
                inputRowRenderer.frame = CGRect(x: 1,
                                                y: itemRenderer.intrinsicContentSize.height + inputOutputRowsHeight,
                                                width: inputRowRenderer.intrinsicContentSize.width,
                                                height: inputRowRenderer.intrinsicContentSize.height)
                
                inputOutputRowsHeight += inputRowRenderer.intrinsicContentSize.height
        
                if i < (node.inputs?.count)!
                {
                    if let input = node.inputs?[i]
                    {
                        inputRowRenderer.inputNode = input
                        
                        inputRowRenderer.reload()
                    }
                }
            }
        }
        
        addSubview(outputRenderer)
        
        outputRenderer.frame = CGRect(x: 1,
                                      y: itemRenderer.intrinsicContentSize.height + inputOutputRowsHeight,
                                      width: outputRenderer.intrinsicContentSize.width,
                                      height: outputRenderer.intrinsicContentSize.height)
        
        inputOutputRowsHeight += outputRenderer.intrinsicContentSize.height
        
        frame = CGRect(x: frame.origin.x,
            y: frame.origin.y,
            width: itemRenderer.intrinsicContentSize.width + 2,
            height: itemRenderer.intrinsicContentSize.height + inputOutputRowsHeight)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        buildUserInterface()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.superview?.bringSubviewToFront(self)
        
        view.nodeTouched = true
        
        if let touchLocation = touches.first?.location(in: self),
            let inputNodeWidget = self.hitTest(touchLocation, with: event) as? SNInputRowRenderer,
            let targetNodeInputIndex = inputRowRenderers.index(of: inputNodeWidget)
        {
            view.toggleRelationship(targetNode: node, targetNodeInputIndex: targetNodeInputIndex)
        }
        else
        {
            view.selectedNode = node
        }
        
        view.selectedNode = node // SIMON - to do line 204 getting reached oddly
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        view.nodeTouched = false
    }
    
    @objc func deleteHandler()
    {
        view.nodeDeleted(node: node)
    }
    
    @objc func longPressHandler(recognizer: UILongPressGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizer.State.began
        {
            view.relationshipCreationMode = true
        }
        else if recognizer.state == UIGestureRecognizer.State.cancelled || recognizer.state == UIGestureRecognizer.State.ended
        {
            view.nodeTouched = false
        }
    }
    
    @objc func panHandler(recognizer: UIPanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizer.State.began
        {
            previousPanPoint = recognizer.location(in: self.superview)
            
            self.superview?.bringSubviewToFront(self)
            
            view.selectedNode = node
        }
        else if let previousPanPoint = previousPanPoint, recognizer.state == UIGestureRecognizer.State.changed
        {
            let gestureLocation = recognizer.location(in: self.superview)
            
            let deltaX = (gestureLocation.x - previousPanPoint.x)
            let deltaY = (gestureLocation.y - previousPanPoint.y) // consider.zoomScale
            
            let newPosition = CGPoint(x: frame.origin.x + deltaX, y: frame.origin.y + deltaY)
            
            frame.origin.x = newPosition.x
            frame.origin.y = newPosition.y
            
            self.previousPanPoint = gestureLocation
            
            node.position = newPosition
            
            view.nodeMoved(node: node)
        }
        else if recognizer.state == UIGestureRecognizer.State.cancelled || recognizer.state == UIGestureRecognizer.State.ended
        {
            view.nodeTouched = false
        }
    }
    override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }
}

class SNWidgetTitleBar: UIToolbar
{
    let label: UIBarButtonItem
    
    unowned let parentNodeWidget: SNNodeWidget
    
    var title: String = ""
    {
        didSet
        {
            label.title = title
        }
    }
    
    required init(parentNodeWidget: SNNodeWidget)
    {
        self.parentNodeWidget = parentNodeWidget
        label = UIBarButtonItem(title: title, style: UIBarButtonItem.Style.plain, target: nil, action: nil)

        super.init(frame: CGRect.zero)

        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let trash = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.trash, target: self, action: #selector(SNWidgetTitleBar.deleteHandler))
        
        items = parentNodeWidget.node.deletable() ? [label, spacer, trash] : [label]
        
        tintColor = UIColor.white
        barTintColor = UIColor.darkGray
    }

    @objc func deleteHandler()
    {
        parentNodeWidget.deleteHandler()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        print("** NodeWidget deinit")
    }
}
