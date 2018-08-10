//
//  NodeVO.swift
//  ShinpuruNodeUI
//
//  Created by Simon Gladman on 01/09/2015.
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
import AudioKit

class NodeVO: SNNode
{
    unowned let model:NodalityModel

    var type: NodeType = NodeType.Numeric
    {
        didSet
        {
            inputs = nil
        
            name = type.rawValue
            
            recalculate()
        }
    }
    
    var value: NodeValue?
    
    override func deletable() -> Bool
    {
        return type != .Output
    }
    
    /// For numeric nodes, the slider maximumValue 
    var maximumValue: Double = 1
    
    /// For AudioPlayer nodes, the index of the loop
    var loopIndex = 0 
    
    required init(type: NodeType, model: NodalityModel)
    {
        self.model = model
        super.init(name: type.rawValue, position: CGPoint.zero)
        
        self.type = type
        self.inputs = []
    }

    required init(name: String, position: CGPoint)
    {
        fatalError("init(name:position:) has not been implemented")
    }
    
    override var numInputSlots: Int
    {
        set
        {
            // ignore - we compute this from the type
        }
        get
        {
            return type.numInputSlots
        }
    }
    
    var outputType: NodeValue
    {
        switch type
        {
        case .Numeric, .NumericDouble, .NumericHalve:
            return SNNodeNumberType

        default:
            return SNNodeNodeType
        }
    }
    
    var outputTypeName: String
    {
        switch type
        {
        case .Numeric, .NumericDouble, .NumericHalve:
            return SNNumberTypeName
            
        default:
            return SNNodeTypeName
        }
    }

    var audioKitNodeInputs = [Int: AKNode]()
    var loopName: String = ""
    
    func stopAudioPlayers()
    {
        for node in model.nodes where node.value?.audioKitNode is AKAudioPlayer
        {
           (node.value?.audioKitNode as! AKAudioPlayer).stop()
        }
    }
    
    // loop over all AKAudioPlayer nodes. If they're part of the network play them...
    func toggleAudioPlayers()
    {
        guard let masterOutput = model.nodes.filter({ $0.type == .Output }).first else
        {
            return
        }
        
        for node in model.nodes where node.value?.audioKitNode is AKAudioPlayer
        {
            if masterOutput.isAscendant(node: node)
            {
                (node.value?.audioKitNode as! AKAudioPlayer).play()
            }
            else
            {
                (node.value?.audioKitNode as! AKAudioPlayer).stop()
            }
        }
    }

    var audioPlayers: [AKAudioPlayer]
    {
        return model.nodes
            .filter{ $0.value?.audioKitNode is AKAudioPlayer }
            .map{  ($0.value?.audioKitNode as? AKAudioPlayer)! }
    }
    
    func recalculate()
    {
        switch type
        {
        case .Numeric:
            value = NodeValue.Number(value?.numberValue)
            
        case .NumericDouble:
            value = NodeValue.Number(getInputValueAt(index: 0).numberValue * 2)
            
        case .NumericHalve:
            value = NodeValue.Number(getInputValueAt(index: 0).numberValue / 2)
        
        case .Output:
            if let input = getInputValueAt(index: 0).audioKitNode, audioKitNodeInputs[0] != input
            {
                stopAudioPlayers()
                try! AudioKit.stop()
                
                AudioKit.output = input; print("AudioKit.output =", input)

                audioKitNodeInputs[0] = input
                
                try! AudioKit.start()
                
                toggleAudioPlayers()
            }
            else if getInputValueAt(index: 0).audioKitNode == nil
            {
                stopAudioPlayers()
                try! AudioKit.stop()
            }
           
        // Generators
            
        case .AudioPlayer:
            let loopName = NodalityModel.loops[loopIndex]
            
            if loopName != self.loopName
            {
                let bundle = Bundle.main
                let file = try! AKAudioFile(forReading: bundle.url(forResource: loopName, withExtension: "wav")!)
                let player = try! AKAudioPlayer(file: file)
                player.looping = true
                
                self.loopName = loopName
                value = NodeValue.Node(player)
            }

            (value?.audioKitNode as? AKAudioPlayer)?.volume = getInputValueAt(index: 0).numberValue

            
        case .WhiteNoise:
            let whiteNoise = value?.audioKitNode as? AKWhiteNoise ?? AKWhiteNoise()
            
            whiteNoise.amplitude = getInputValueAt(index: 0).numberValue
            
            if whiteNoise.isStopped
            {
                whiteNoise.start()
            }
            
            value = NodeValue.Node(whiteNoise)
            
        case .PinkNoise:
            let pinkNoise = value?.audioKitNode as? AKPinkNoise ?? AKPinkNoise()
            
            pinkNoise.amplitude = getInputValueAt(index: 0).numberValue
            
            if pinkNoise.isStopped
            {
                pinkNoise.start()
            }
            
            value = NodeValue.Node(pinkNoise)
            
        case .Oscillator:
            let oscillator = value?.audioKitNode as? AKOscillator ?? AKOscillator()
            
            oscillator.amplitude = getInputValueAt(index: 0).numberValue
            oscillator.frequency = getInputValueAt(index: 1).numberValue
    
            if oscillator.isStopped
            {
                oscillator.start()
            }
            
            value = NodeValue.Node(oscillator)
            
        case .FMOscillator:
            let fmoscillator = value?.audioKitNode as? AKFMOscillator ?? AKFMOscillator()
            
            fmoscillator.baseFrequency = getInputValueAt(index: 0).numberValue
            fmoscillator.carrierMultiplier = getInputValueAt(index: 1).numberValue
            fmoscillator.modulatingMultiplier = getInputValueAt(index: 2).numberValue
            fmoscillator.modulationIndex = getInputValueAt(index: 3).numberValue
            fmoscillator.amplitude = getInputValueAt(index: 4).numberValue
            
            if fmoscillator.isStopped
            {
                fmoscillator.start()
            }
            
            value = NodeValue.Node(fmoscillator)
            
        case .SawtoothOscillator:
            let sawtoothoscillator = value?.audioKitNode as? AKOscillator ?? AKOscillator(waveform: AKTable(.sawtooth))
            
            sawtoothoscillator.frequency = getInputValueAt(index: 0).numberValue
            sawtoothoscillator.amplitude = getInputValueAt(index: 1).numberValue
            sawtoothoscillator.detuningOffset = getInputValueAt(index: 2).numberValue
            sawtoothoscillator.detuningMultiplier = getInputValueAt(index: 3).numberValue
            
            if sawtoothoscillator.isStopped
            {
                sawtoothoscillator.start()
            }
            
            value = NodeValue.Node(sawtoothoscillator)
            
        case .TriangleOscillator:
            let triangleoscillator = value?.audioKitNode as? AKOscillator ?? AKOscillator(waveform: AKTable(.triangle))
            
            triangleoscillator.frequency = getInputValueAt(index: 0).numberValue
            triangleoscillator.amplitude = getInputValueAt(index: 1).numberValue
            triangleoscillator.detuningOffset = getInputValueAt(index: 2).numberValue
            triangleoscillator.detuningMultiplier = getInputValueAt(index: 3).numberValue
            
            if triangleoscillator.isStopped
            {
                triangleoscillator.start()
            }
            
            value = NodeValue.Node(triangleoscillator)
            
        case .SquareWaveOscillator:
            let squareoscillator = value?.audioKitNode as? AKOscillator ?? AKOscillator(waveform: AKTable(.square))
            
            squareoscillator.frequency = getInputValueAt(index: 0).numberValue
            squareoscillator.amplitude = getInputValueAt(index: 1).numberValue
            squareoscillator.detuningOffset = getInputValueAt(index: 2).numberValue
            squareoscillator.detuningMultiplier = getInputValueAt(index: 3).numberValue

            if squareoscillator.isStopped
            {
                squareoscillator.start()
            }
            
            value = NodeValue.Node(squareoscillator)
            
        // Filters
            
        case .DryWetMixer:
            if let input0 = getInputValueAt(index: 0).audioKitNode,
                let input1 = getInputValueAt(index: 1).audioKitNode
            {
                let balance = getInputValueAt(index: 2).numberValue
                
                if audioKitNodeInputs[0] != input0 || audioKitNodeInputs[1] != input1
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKDryWetMixer(input0, input1, balance: balance))
                    
                    audioKitNodeInputs[0] = input0
                    audioKitNodeInputs[1] = input1
                }
                
                (value?.audioKitNode as? AKDryWetMixer)?.balance = balance
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .StringResonator:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKStringResonator(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKStringResonator
                {
                    audioKitNode.fundamentalFrequency = getInputValueAt(index: 1).numberValue
                    audioKitNode.feedback = min(getInputValueAt(index: 2).numberValue, 1.0)
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }

        case .MoogLadder:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKMoogLadder(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKMoogLadder
                {
                    audioKitNode.cutoffFrequency = getInputValueAt(index: 1).numberValue
                    audioKitNode.resonance = getInputValueAt(index: 2).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .BitCrusher:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKBitCrusher(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKBitCrusher
                {
                    audioKitNode.bitDepth = getInputValueAt(index: 1).numberValue
                    audioKitNode.sampleRate = getInputValueAt(index: 2).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .Reverb:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKReverb(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKReverb
                {
                    audioKitNode.dryWetMix = getInputValueAt(index: 1).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .CostelloReverb:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKCostelloReverb(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKCostelloReverb
                {
                    audioKitNode.feedback = getInputValueAt(index: 1).numberValue
                    audioKitNode.cutoffFrequency = getInputValueAt(index: 2).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .Decimator:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKDecimator(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKDecimator
                {
                    audioKitNode.decimation = getInputValueAt(index: 1).numberValue
                    audioKitNode.rounding = getInputValueAt(index: 2).numberValue
                    audioKitNode.mix = getInputValueAt(index: 3).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .Equalizer:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKEqualizerFilter(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKEqualizerFilter
                {
                    audioKitNode.centerFrequency = getInputValueAt(index: 1).numberValue
                    audioKitNode.bandwidth = getInputValueAt(index: 2).numberValue
                    audioKitNode.gain = getInputValueAt(index: 3).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .AutoWah:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKAutoWah(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKAutoWah
                {
                    audioKitNode.wah = getInputValueAt(index: 1).numberValue
                    audioKitNode.mix = getInputValueAt(index: 2).numberValue
                    audioKitNode.amplitude = getInputValueAt(index: 3).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .RingModulator:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKRingModulator(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKRingModulator
                {
                    audioKitNode.frequency1 = getInputValueAt(index: 1).numberValue
                    audioKitNode.frequency2 = getInputValueAt(index: 2).numberValue
                    audioKitNode.balance = getInputValueAt(index: 3).numberValue
                    audioKitNode.mix = getInputValueAt(index: 4).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .VariableDelay:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKVariableDelay(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKVariableDelay
                {
                    audioKitNode.time = getInputValueAt(index: 1).numberValue
                    audioKitNode.feedback = getInputValueAt(index: 2).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .LowPassFilter:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKLowPassFilter(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKLowPassFilter
                {
                    audioKitNode.cutoffFrequency = getInputValueAt(index: 1).numberValue
                    audioKitNode.resonance = getInputValueAt(index: 2).numberValue
                    audioKitNode.dryWetMix = getInputValueAt(index: 3).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
            
        case .HighPassFilter:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKHighPassFilter(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKHighPassFilter
                {
                    audioKitNode.cutoffFrequency = getInputValueAt(index: 1).numberValue
                    audioKitNode.resonance = getInputValueAt(index: 2).numberValue
                    audioKitNode.dryWetMix = getInputValueAt(index: 3).numberValue
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
        
        case .TB303:
            if let input = getInputValueAt(index: 0).audioKitNode
            {
                if audioKitNodeInputs[0] != input
                {
                    try! AudioKit.stop()
                    
                    value = NodeValue.Node(AKRolandTB303Filter(input))
                    
                    audioKitNodeInputs[0] = input
                }
                
                if let audioKitNode = value?.audioKitNode as? AKRolandTB303Filter
                {
                    audioKitNode.cutoffFrequency = max(getInputValueAt(index: 1).numberValue, 440)
                    audioKitNode.resonance = min(getInputValueAt(index: 2).numberValue, 1)
                    audioKitNode.resonanceAsymmetry = min(getInputValueAt(index: 3).numberValue, 1)
                }
            }
            else
            {
                value = NodeValue.Node(nil)
            }
        
        }
        
        // ----
        
        if let inputs = inputs
        {
            if inputs.count >= type.numInputSlots && type.numInputSlots > 0
            {
                self.inputs = Array(inputs[0 ... type.numInputSlots - 1])
            }
            
            for (idx, input) in self.inputs!.enumerated() where input?.nodalityNode != nil
            {
                if !NodalityModel.nodesAreRelationshipCandidates(sourceNode: input!.nodalityNode!, targetNode: self, targetIndex: idx)
                {
                    self.inputs?[idx] = nil
                }
            }
        }
        
        _ = self.model.updateDescendantNodes(sourceNode: self)
    }
    
    func getInputValueAt(index: Int) -> NodeValue
    {
        let returnValue: NodeValue
 
        if inputs == nil || index >= (inputs?.count)! || inputs?[index] == nil || inputs?[index]?.nodalityNode == nil
        {
            returnValue = NodeValue.Number(type.inputSlots[index].defaultValue)
        }
        else if let value = inputs?[index]?.nodalityNode?.value
        {
            returnValue = value
        }
        else
        {
            returnValue = NodeValue.Number(0)
        }
        
        return returnValue
    }
    
    deinit
    {
        print("** NodeVO deinit")
    }
}

extension SNNode
{
    var nodalityNode: NodeVO?
    {
        return self as? NodeVO
    }
}



struct NodeInputSlot
{
    let label: String
    let type: NodeValue
    let defaultValue: Double
    
    init (label: String, type: NodeValue, defaultValue: Double)
    {
        self.label = label
        self.type = type
        self.defaultValue = defaultValue
    }
    
    init (label: String, type: NodeValue)
    {
        self.label = label
        self.type = type
        self.defaultValue = 0
    }
}


let SNWidgetWidth: CGFloat = 250




