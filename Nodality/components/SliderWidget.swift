//
//  SliderWidget.swift
//  SceneKitExperiment
//
//  Created by Simon Gladman on 04/11/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

protocol NodalitySlider
{
    var value: NodeValue? { get }
    var maximumValue: Double {get set }
    func updateValue(value: NodeValue)
}

class SliderWidget: UIControl, NodalitySlider
{
    let slider = UISlider(frame: CGRect.zero)
    let label = UILabel(frame: CGRect.zero)
    
    let minButton = UIButton()
    let maxButton = UIButton()
    
    let maximumValueSegmentedControl = UISegmentedControl(items: ["1", "10", "100", "1000", "10000"])

    func updateValue(value: NodeValue)
    {
        self.value = value
    }
    
    var value: NodeValue?
    {
        didSet
        {
            slider.value = Float(value?.numberValue ?? 0)
            updateLabel()
            
            sendActions(for: .valueChanged)
        }
    }
    
    var maximumValue: Double = 1
    {
        didSet
        {
            maximumValueSegmentedControl.selectedSegmentIndex = Int(ceil(log10(maximumValue)))
            
            slider.maximumValue = Float(maximumValue)
            maxButton.setTitle(" \(maximumValue) ", for: UIControlState.normal)
  
            if let numberValue = value?.numberValue, numberValue > maximumValue
            {
                value = NodeValue.Number(maximumValue)
            }
            else
            {
                sendActions(for: .valueChanged)
            }
            
            setNeedsLayout()
        }
    }
    
    override func didMoveToSuperview()
    {
        slider.addTarget(self, action: #selector(SliderWidget.sliderChangeHandler), for: .valueChanged)
        minButton.addTarget(self, action: #selector(SliderWidget.minHandler), for: .touchDown)
        maxButton.addTarget(self, action: #selector(SliderWidget.maxHandler), for: .touchDown)
        
        slider.minimumValue = 0
        slider.maximumValue = 1
        
        layer.backgroundColor = UIColor.darkGray.cgColor
        
        label.textColor = UIColor.white
        
        minButton.setTitle("0", for: UIControlState.normal)
        minButton.layer.borderColor = UIColor.lightGray.cgColor
        minButton.layer.borderWidth = 1

        maxButton.setTitle(" \(maximumValue) ", for: UIControlState.normal)
        maxButton.layer.borderColor = UIColor.lightGray.cgColor
        maxButton.layer.borderWidth = 1
        
        addSubview(slider)
        addSubview(label)
        
        addSubview(minButton)
        addSubview(maxButton)
        
        maximumValueSegmentedControl.tintColor = UIColor.lightGray
        maximumValueSegmentedControl.selectedSegmentIndex = 0
        maximumValueSegmentedControl.addTarget(
            self,
            action: #selector(SliderWidget.maximumValueSegmentedControlChangeHandler),
            for: .valueChanged)
        addSubview(maximumValueSegmentedControl)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 2
        layer.shadowOpacity = 1
    }
    
    @objc func maximumValueSegmentedControlChangeHandler()
    {
        maximumValue = pow(10, Double(maximumValueSegmentedControl.selectedSegmentIndex))
    }
    
    @objc func minHandler()
    {
        slider.value = 0
        
        sliderChangeHandler()
    }
    
    @objc func maxHandler()
    {
        slider.value = Float(maximumValue)
        
        sliderChangeHandler()
    }
    
    @objc func sliderChangeHandler()
    {
        value = NodeValue.Number(Double(slider.value))
    }
    
    func updateLabel()
    {
        label.text = (NSString(format: "%.3f", value?.numberValue ?? 0) as String)
    }
    
    override var intrinsicContentSize: CGSize
    {
        return CGSize(width: 250, height: 20 + slider.intrinsicContentSize.height * 2)
    }
    
    override func layoutSubviews()
    {
        label.frame = CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: frame.height / 2).insetBy(dx: 5, dy: 5)
        
        minButton.frame = CGRect(
            x: 4,
            y: frame.height - slider.intrinsicContentSize.height * 1.5 + 5,
            width: minButton.intrinsicContentSize.width,
            height: slider.intrinsicContentSize.height)

        maxButton.frame = CGRect(
            x: frame.width - 4 - maxButton.intrinsicContentSize.width,
            y: frame.height - slider.intrinsicContentSize.height * 1.5 + 5,
            width: maxButton.intrinsicContentSize.width,
            height: slider.intrinsicContentSize.height)
        
        slider.frame = CGRect(
            x: minButton.intrinsicContentSize.width + 4,
            y: (frame.height / 2),
            width: frame.width - minButton.intrinsicContentSize.width - maxButton.intrinsicContentSize.width - 6,
            height: slider.intrinsicContentSize.height).insetBy(dx: 10, dy: 0)
        
        maximumValueSegmentedControl.frame = CGRect(
            x: frame.width - maximumValueSegmentedControl.intrinsicContentSize.width - 4,
            y: 4,
            width: maximumValueSegmentedControl.intrinsicContentSize.width,
            height: maximumValueSegmentedControl.intrinsicContentSize.height)
    }
}


