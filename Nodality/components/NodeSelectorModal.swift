//
//  NodeSelectorModal.swift
//  AudioKitNodality
//
//  Created by Simon Gladman on 11/05/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit

class NodeSelectorModal: UIViewController
{
    weak var delegate: NodeSelectorModalDelegate?
    
    let collectionView: UICollectionView
    let closeButton: UIButton
    
    required init()
    {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 200, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(NodeSelectorItemRenderer.self, forCellWithReuseIdentifier: "Cell")
        
        closeButton = UIButton()
        closeButton.setTitle("Close", for: .normal)
        
        super.init(nibName: nil, bundle: nil)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        closeButton.addTarget(
            self,
            action: #selector(NodeSelectorModal.close),
            for: .touchDown)
        
        modalPresentationStyle = UIModalPresentationStyle.formSheet
        modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        collectionView.backgroundColor = UIColor.darkGray
        
        view.addSubview(collectionView)
        view.addSubview(closeButton)
    }
    
    @objc func close()
    {
        dismiss(animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews()
    {
        collectionView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.frame.width,
            height: view.frame.height - closeButton.intrinsicContentSize.height)
        
        closeButton.frame = CGRect(
            x: view.frame.width - closeButton.intrinsicContentSize.width - 10,
            y: view.frame.height - closeButton.intrinsicContentSize.height,
            width: closeButton.intrinsicContentSize.width,
            height: closeButton.intrinsicContentSize.height)
    }
}

// MARK: UICollectionViewDelegate

extension NodeSelectorModal: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        delegate?.didSelectAudioKitNode(nodeType: NodeType.types[indexPath.item])
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource

extension NodeSelectorModal: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return NodeType.types.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath as IndexPath) as! NodeSelectorItemRenderer
        
        cell.title = NodeType.types[indexPath.item].rawValue
        
        return cell
    }
}

// MARK: Protocol

protocol NodeSelectorModalDelegate: class
{
    func didSelectAudioKitNode(nodeType: NodeType)
}

// MARK: Item Renderer

class NodeSelectorItemRenderer: UICollectionViewCell
{
    var title: String = ""
    {
        didSet
        {
            label.text = title
        }
    }
    
    let label = UILabel()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        label.textColor = UIColor.white
        label.textAlignment = .center
        
        backgroundColor = UIColor.lightGray
        
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        label.frame = bounds
    }
}
