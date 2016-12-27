//
//  FlatPickerView.swift
//  CustomPickerView
//
//  Created by Luciano Almeida on 25/12/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

public protocol FlatPickerViewDataSource: class {
    func flatPickerNumberOfRows(pickerView: FlatPickerView)-> Int
}

public protocol FlatPickerViewDelegate: class {
    func flatPicker(pickerView: FlatPickerView, titleForRow row: Int) -> String?
    func flatPicker(pickerView: FlatPickerView, attributedTitleForRow row: Int) -> NSAttributedString?
    func flatPicker(pickerView: FlatPickerView, viewForRow row: Int) -> UIView?
    func flatPickerViewForSelectedItem(pickerView: FlatPickerView) -> UIView?
    func flatPickerShouldShowSelectionView(pickerView: FlatPickerView) -> Bool
    func flatPicker(pickerView: FlatPickerView, didSelectRow row: Int)
    func flatPicker(pickerView: FlatPickerView, didPassOnSelection row: Int)

}

open class FlatPickerView: UIView {
    
    //MARK: Definitions
    public enum Direction {
        case horizontal
        case vertical
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    override open func layoutSubviews() {
        super.layoutSubviews()
        setupInsetForCollection()
        if !initialized {
            initialized = true
            selectItemAtIntexPath(indexPath: IndexPath(item: (self.dataSource?.flatPickerNumberOfRows(pickerView: self) ?? 0)/2, section: 0), animated: false, triggerDelegate: false)
        }else{
            if currentSelectedRow != nil {
                selectItemAtIntexPath(indexPath: IndexPath(item: currentSelectedRow, section: 0), animated: true, triggerDelegate: false)
            }

        }
    }
    
    //MARK: Properties
    private var initialized: Bool = false
    
    open var itemSize: CGFloat = 50 {
        didSet{
            highlightedView?.constraints.forEach({$0.constant = itemSize})
            highlightedView?.layoutIfNeeded()
            collectionView?.reloadData()
        }
    }
    
    open weak var delegate: FlatPickerViewDelegate? {
        didSet{
            setupPickerSelectionView()
            collectionView?.reloadData()
        }
    }
    
    open weak var dataSource: FlatPickerViewDataSource? {
        didSet{
            collectionView?.reloadData()
        }
    }
    
    fileprivate weak var collectionView: UICollectionView!
    open fileprivate(set) weak var highlightedView: UIView!
    
    var isScroolEnabled: Bool = true {
        didSet{
            collectionView?.isScrollEnabled = isScroolEnabled
        }
    }
    
    fileprivate var lastIdxPassedOnSelection: Int!
    
    open var direction: Direction! {
        didSet{
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = direction == Direction.horizontal ? UICollectionViewScrollDirection.horizontal : UICollectionViewScrollDirection.vertical
            }
            enableConstrainsForDirection()
        }
    }
    
    fileprivate(set) var currentSelectedRow: Int!
    
    
    
    private func initialize(){
        setupCollectionView()
        //Setting default direction
        direction = .vertical
        setupPickerSelectionView()

    }
    
    
    private func setupCollectionView(){
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DefaultCell")
        collectionView.register(TextCollectionViewCell.self, forCellWithReuseIdentifier: TextCollectionViewCell.reuseIdentifier)
        addSubview(collectionView)
        self.collectionView = collectionView
        constrainsForCollection()
    }
    
    private func setupPickerSelectionView() {
        highlightedView?.removeFromSuperview()
        let pickerSelectionView : UIView = self.delegate?.flatPickerViewForSelectedItem(pickerView: self) ?? PickerDefaultSelectedItemView(frame: CGRect.zero, direction : direction)
        if pickerSelectionView is PickerDefaultSelectedItemView {
            pickerSelectionView.isUserInteractionEnabled = false
        }
        pickerSelectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pickerSelectionView)
        bringSubview(toFront: pickerSelectionView)
        self.highlightedView = pickerSelectionView
        contraintsForSelectedView()
        highlightedView.isHidden = !(self.delegate?.flatPickerShouldShowSelectionView(pickerView: self) ?? true)
    }
    
    private func setupInsetForCollection(){
        if direction == .vertical {
            collectionView.contentInset = UIEdgeInsets(top: (frame.size.height/2) - (itemSize/2), left: 0, bottom: (frame.size.height/2) - (itemSize/2), right: 0)
        }else{
            collectionView.contentInset = UIEdgeInsets(top: 0, left: (frame.size.width/2) - (itemSize/2), bottom: 0, right: (frame.size.width/2) - (itemSize/2))
        }
    }
    
    private func contraintsForSelectedView(){
        contraintsForVerticalSelectedView()
        contraintsForHorizontalSelectedView()
        enableConstrainsForDirection()
    }
    
    private func enableConstrainsForDirection(){
        if direction != nil{
            self.constraints.forEach({
                if $0.identifier == "vertical" {
                    $0.isActive = direction == .vertical
                }else if $0.identifier == "horizontal" {
                    $0.isActive = direction == .horizontal
                }
            })
        }
    }
    
    
    private func contraintsForVerticalSelectedView(){
        let leading: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.leading, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0)
        let trailling: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.trailing, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        let centerVertical: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        let height: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: itemSize)
        highlightedView.addConstraint(height)
        let contraints = [leading, trailling, centerVertical]
        contraints.forEach({
            $0.identifier = "vertical"
            $0.isActive = false
        })
        addConstraints(contraints)
    }
    
    private func contraintsForHorizontalSelectedView(){
        let top: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.top, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.bottom, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        let centerHorizontal: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let width: NSLayoutConstraint = NSLayoutConstraint(item: highlightedView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: itemSize)
        highlightedView.addConstraint(width)
        let contraints = [top, bottom, centerHorizontal]
        contraints.forEach({
            $0.identifier = "horizontal"
            $0.isActive = false
        })
        addConstraints(contraints)
    }
    
    
    private func constrainsForCollection() {
        let leading: NSLayoutConstraint = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.leading, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0)
        let trailling: NSLayoutConstraint = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.trailing, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        let top: NSLayoutConstraint = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.top, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom: NSLayoutConstraint = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.bottom, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        addConstraints([leading, trailling, top, bottom])
    }
    
    
    //MARK: Public functions
    open func selectRow(at row: Int, animated: Bool) {
        //collectionView?.selectItem(at: IndexPath(item: row, section: 0), animated: animated, scrollPosition: .)
        selectItemAtIntexPath(indexPath: IndexPath(item: row, section: 0), animated: animated, triggerDelegate: true)
    }
    
    func viewForRow(at row: Int) -> UIView?{
        return collectionView.cellForItem(at: IndexPath(item: row, section: 0))?.contentView
    }
    
}

extension FlatPickerView: UICollectionViewDelegate, UICollectionViewDataSource{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource?.flatPickerNumberOfRows(pickerView: self) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let text = self.delegate?.flatPicker(pickerView: self, titleForRow: indexPath.item) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCollectionViewCell.reuseIdentifier, for: indexPath) as! TextCollectionViewCell
            cell.textLabel.text = text
            return cell
        }else if let attrText = self.delegate?.flatPicker(pickerView: self, attributedTitleForRow: indexPath.row){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCollectionViewCell.reuseIdentifier, for: indexPath) as! TextCollectionViewCell
            cell.textLabel.attributedText = attrText
            return cell
        }else if let view = self.delegate?.flatPicker(pickerView: self, viewForRow: indexPath.item){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DefaultCell", for: indexPath)
            cell.contentView.subviews.forEach({$0.removeFromSuperview()})
            cell.contentView.addSubview(view)
            constraintsForCustomViewCell(cell: cell, view: view)
            return cell
        }
        return UICollectionViewCell()
    }
    
    private func constraintsForCustomViewCell(cell: UICollectionViewCell, view: UIView){
        let leading: NSLayoutConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.leading, relatedBy: .equal, toItem: cell.contentView, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0)
        let trailling: NSLayoutConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.trailing, relatedBy: .equal, toItem: cell.contentView, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        let top: NSLayoutConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: .equal, toItem: cell.contentView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottom: NSLayoutConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: .equal, toItem: cell.contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraints([leading, trailling, top, bottom])
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: highlightedView.center.x + collectionView.contentOffset.x, y: highlightedView.center.y + collectionView.contentOffset.y)){
            if lastIdxPassedOnSelection == nil || indexPath.row != lastIdxPassedOnSelection{
                lastIdxPassedOnSelection = indexPath.row
                self.delegate?.flatPicker(pickerView: self, didPassOnSelection: indexPath.row)
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            adjustSelectedItem()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        adjustSelectedItem()
    }
    
    private func adjustSelectedItem(){
        
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: highlightedView.center.x + collectionView.contentOffset.x, y: highlightedView.center.y + collectionView.contentOffset.y)){
            selectItemAtIntexPath(indexPath: indexPath, animated: true, triggerDelegate: true)
        }

    }
    
    fileprivate func selectItemAtIntexPath(indexPath: IndexPath, animated: Bool, triggerDelegate: Bool){
        if let layout = collectionView.layoutAttributesForItem(at: indexPath){
            var point: CGPoint = CGPoint.zero
            if direction == .vertical {
                point = CGPoint(x: collectionView.contentOffset.x, y: layout.frame.origin.y - collectionView.contentInset.top)
            }else{
                point = CGPoint(x: layout.frame.origin.x - collectionView.contentInset.left, y: collectionView.contentOffset.y)
            }
            collectionView.setContentOffset( point, animated: animated)
            CATransaction.setCompletionBlock({
                if self.currentSelectedRow == nil || self.currentSelectedRow != indexPath.item {
                    self.currentSelectedRow = indexPath.item
                    if triggerDelegate {
                        self.delegate?.flatPicker(pickerView: self, didSelectRow: indexPath.item)
                    }
                }
            })
        }
    }
}

extension FlatPickerView : UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if direction == .horizontal {
            return CGSize(width: itemSize, height: self.frame.size.height)
        }
        return CGSize(width: self.frame.size.width, height: itemSize)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}

