//
//  NodalityModel.swift
//  ShinpuruNodeUI
//
//  Created by Simon Gladman on 07/09/2015.
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

class NodalityModel
{
    static let loops = ["bassloop", "drumloop", "guitarloop", "mixloop"]
    
    var nodes = [NodeVO]()
    
    weak var view: SNView!
    
    init() 
    {
        let amplitude = NodeType.createNodeOfType(nodeType: .Numeric, model: self)
        let frequency = NodeType.createNodeOfType(nodeType: .Numeric, model: self)
        
        let oscillator = NodeType.createNodeOfType(nodeType: .Oscillator, model: self)
        let output = NodeType.createNodeOfType(nodeType: .Output, model: self)

        frequency.position = CGPoint(x: 30, y: 200)
        amplitude.position = CGPoint(x: 50, y: 400)
        oscillator.position = CGPoint(x: 500, y: 100)
        output.position = CGPoint(x: 900, y: 300)
      
        frequency.value = NodeValue.Number(440)
        frequency.maximumValue = 1000
        amplitude.value = NodeValue.Number(0.01)
        
        _ = toggleRelationship(sourceNode: frequency, targetNode: oscillator, targetIndex: 1)
        _ = toggleRelationship(sourceNode: amplitude, targetNode: oscillator, targetIndex: 0)
        _ = toggleRelationship(sourceNode: oscillator, targetNode: output, targetIndex: 0)
        
        nodes = [frequency, amplitude, oscillator, output]

        oscillator.recalculate()
    }
    
    func toggleRelationship(sourceNode: NodeVO, targetNode: NodeVO, targetIndex: Int) -> [NodeVO]
    {
        if targetNode.inputs == nil
        {
            targetNode.inputs = [NodeVO]()
        }
        
        if targetIndex >= (targetNode.inputs?.count)!
        {
            for _ in 0 ... targetIndex - targetNode.inputs!.count
            {
                targetNode.inputs?.append(nil)
            }
        }
        
        if targetNode.inputs![targetIndex] == sourceNode
        {
            targetNode.inputs![targetIndex] = nil
            
            return updateDescendantNodes(sourceNode: sourceNode.nodalityNode!, forceNode: targetNode.nodalityNode!)
        }
        else
        {
            targetNode.inputs![targetIndex] = sourceNode
            
            return updateDescendantNodes(sourceNode: sourceNode.nodalityNode!)
        }
    }
    
    func deleteNode(deletedNode: NodeVO) -> [NodeVO]
    {
        var updatedNodes = [NodeVO]()
        
        //for node in nodes where node.inputs != nil && node.inputs!.contains({$0 == deletedNode})
        for node in nodes where node.inputs != nil && node.inputs!.contains(deletedNode)
        {
            for (idx, inputNode) in node.inputs!.enumerated() where inputNode == deletedNode
            {
                node.inputs?[idx] = nil
                
                node.recalculate()
                
                updatedNodes += updateDescendantNodes(sourceNode: node)
            }
        }
        
        if let deletedNodeIndex = nodes.index(of: deletedNode)
        {
            nodes.remove(at: deletedNodeIndex)
        }
        
        return updatedNodes
    }
    
    func addNodeOfType(nodeType: NodeType, position: CGPoint) -> NodeVO
    {
        let newNode = NodeType.createNodeOfType(nodeType: nodeType, model: self)
        newNode.position = position
        nodes.append(newNode)
        
        newNode.recalculate()
        
        return newNode
    }
    
    func updateDescendantNodes(sourceNode: NodeVO, forceNode: NodeVO? = nil) -> [NodeVO]
    {
        var updatedDatedNodes = [[sourceNode]]
        
        for targetNode in nodes where targetNode != sourceNode
        {
            if let inputs = targetNode.inputs,
                //let targetNode = targetNode.nodalityNode, inputs.contains({$0 == sourceNode}) || targetNode == forceNode
                let targetNode = targetNode.nodalityNode, inputs.contains(sourceNode) || targetNode == forceNode
            {
                targetNode.recalculate()
                
                updatedDatedNodes.append(updateDescendantNodes(sourceNode: targetNode))
            }
        }

        let updatedNodes = Array(Set<NodeVO>(updatedDatedNodes.flatMap{ $0 }))
        
        updatedNodes.forEach
        {
            view?.reloadNode(node: $0)
        }
        
        return Array(Set<NodeVO>(updatedDatedNodes.flatMap{ $0 })) 
    }
    
    static func nodesAreRelationshipCandidates(sourceNode: NodeVO, targetNode: NodeVO, targetIndex: Int) -> Bool
    {
        // TODO - prevent circular! recursive function 
        
        if sourceNode.isAscendant(node: targetNode) || sourceNode == targetNode
        {
            return false
        }
        
        return sourceNode.outputTypeName == targetNode.type.inputSlots[targetIndex].type.typeName
    }
}
