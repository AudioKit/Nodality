//
//  ViewController.swift
//  AudioKitNodality
//
//  Created by Simon Gladman on 09/05/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController
{
    let loopsSegmentedControl = UISegmentedControl(items: NodalityModel.loops)
    let slider = SliderWidget()
    let shinpuruNodeUI = SNView()

    var model = NodalityModel()

    var ignoreSliderChange = false

    var createNewNodeLocation: CGPoint?

    lazy var nodeSelectorModal: NodeSelectorModal =
        {
            let modal = NodeSelectorModal()
            modal.delegate = self

            return modal
    }()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        shinpuruNodeUI.nodeDelegate = self
        model.view = shinpuruNodeUI

        view.addSubview(shinpuruNodeUI)

        slider.alpha = 0
        slider.addTarget(
            self,
            action: #selector(ViewController.sliderChangeHandler),
            for: .valueChanged)
        view.addSubview(slider)

        loopsSegmentedControl.backgroundColor = UIColor.darkGray
        loopsSegmentedControl.tintColor = UIColor.lightGray
        loopsSegmentedControl.alpha = 0
        loopsSegmentedControl.selectedSegmentIndex = 0
        loopsSegmentedControl.addTarget(
            self,
            action: #selector(ViewController.loopsSegmentedControlChangeHandler),
            for: .valueChanged)
        view.addSubview(loopsSegmentedControl)
    }

    @objc func loopsSegmentedControlChangeHandler()
    {
        if let selectedNode = shinpuruNodeUI.selectedNode?.nodalityNode, selectedNode.type == .AudioPlayer
        {
            selectedNode.loopIndex = loopsSegmentedControl.selectedSegmentIndex

            selectedNode.recalculate()
        }
    }

    @objc func sliderChangeHandler()
    {
        if let selectedNode = shinpuruNodeUI.selectedNode?.nodalityNode, selectedNode.type == .Numeric && !ignoreSliderChange
        {
            selectedNode.value = NodeValue.Number(Double(slider.slider.value))
            selectedNode.maximumValue = slider.maximumValue

            model.updateDescendantNodes(sourceNode: selectedNode).forEach{ shinpuruNodeUI.reloadNode(node: $0) }
        }
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()

        var topSpace: CGFloat
        if #available(iOS 11.0, *) {
            topSpace = view.safeAreaInsets.top
        } else {
            topSpace = self.topLayoutGuide.length
        }
        
        shinpuruNodeUI.frame = CGRect(
            x: 0,
            y: topSpace,
            width: view.frame.width,
            height: view.frame.height - topSpace)

        slider.frame = CGRect(
            x: 0,
            y: view.frame.height - slider.intrinsicContentSize.height - 20,
            width: view.frame.width,
            height: slider.intrinsicContentSize.height).insetBy(dx: 20, dy: 0)

        loopsSegmentedControl.frame = CGRect(
            x: 0,
            y: view.frame.height - slider.intrinsicContentSize.height - 20,
            width: view.frame.width,
            height: slider.intrinsicContentSize.height).insetBy(dx: 20, dy: 0)

    }
}

// MARK NodeSelectorModalDelegate

extension ViewController: NodeSelectorModalDelegate
{
    func didSelectAudioKitNode(nodeType: NodeType)
    {
        let newNode = model.addNodeOfType(nodeType: nodeType, position: createNewNodeLocation ?? CGPoint.zero)

        shinpuruNodeUI.reloadNode(node: newNode)
        shinpuruNodeUI.selectedNode = newNode
    }
}

// MARK: SNDelegate

extension ViewController: SNDelegate
{
    func dataProviderForView(view: SNView) -> [SNNode]?
    {
        return model.nodes
    }

    func itemRendererForView(view: SNView, node: SNNode) -> SNItemRenderer
    {
        return ItemRenderer(node: node)
    }

    func inputRowRendererForView(view: SNView, inputNode: SNNode?, parentNode: SNNode, index: Int) -> SNInputRowRenderer
    {
        return DemoInputRowRenderer(index: index, inputNode: inputNode, parentNode: parentNode)
    }

    func outputRowRendererForView(view: SNView, node: SNNode) -> SNOutputRowRenderer
    {
        return DemoOutputRowRenderer(node: node)
    }

    func nodeSelectedInView(view: SNView, node: SNNode?)
    {
        UIView.animate(withDuration: 0.25)
        {
            self.slider.alpha = node?.nodalityNode?.type == .Numeric ? 1.0 : 0.0

            self.loopsSegmentedControl.alpha = node?.nodalityNode?.type == .AudioPlayer ? 1.0 : 0.0
        }

        ignoreSliderChange = true
        slider.maximumValue = node?.nodalityNode?.maximumValue ?? 1
        slider.value = node?.nodalityNode?.value
        ignoreSliderChange = false

        loopsSegmentedControl.selectedSegmentIndex = node?.nodalityNode?.loopIndex ?? 0

    }

    func nodeMovedInView(view: SNView, node: SNNode)
    {
        // handle a node move - save to CoreData?
    }

    func nodeCreatedInView(view: SNView, position: CGPoint)
    {
        createNewNodeLocation = position

        nodeSelectorModal.popoverPresentationController?.sourceView = self.view

        present(
            nodeSelectorModal,
            animated: true,
            completion: nil)
    }

    func nodeDeletedInView(view: SNView, node: SNNode)
    {
        if let node = node.nodalityNode
        {
            model.deleteNode(deletedNode: node).forEach{ view.reloadNode(node: $0) }

            view.renderRelationships(deletedNode: node)
        }
    }

    func relationshipToggledInView(view: SNView, sourceNode: SNNode, targetNode: SNNode, targetNodeInputIndex: Int)
    {
        if let targetNode = targetNode.nodalityNode,
            let sourceNode = sourceNode.nodalityNode
        {
            model.toggleRelationship(sourceNode: sourceNode, targetNode: targetNode, targetIndex: targetNodeInputIndex).forEach{ view.reloadNode(node: $0) }
        }
    }

    func defaultNodeSize(view: SNView) -> CGSize
    {
        return CGSize(width: SNWidgetWidth, height: SNWidgetWidth + SNNodeWidget.titleBarHeight * 2)
    }

    func nodesAreRelationshipCandidates(sourceNode: SNNode, targetNode: SNNode, targetIndex: Int) -> Bool
    {
        guard let sourceNode = sourceNode.nodalityNode,
            let targetNode = targetNode.nodalityNode else
        {
            return false
        }

        return NodalityModel.nodesAreRelationshipCandidates(sourceNode: sourceNode, targetNode: targetNode, targetIndex: targetIndex)
    }
}
