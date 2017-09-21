//
//  FlatPickerView.swift
//  CustomPickerView
//
//  Created by Luciano Almeida on 25/12/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

public protocol FlatPickerViewDataSource: class {
    func flatPickerNumberOfRows(pickerView: FlatPickerView) -> Int
}

public protocol FlatPickerViewDelegate: class {
    func flatPicker(pickerView: FlatPickerView, titleForRow row: Int) -> String?
    func flatPicker(pickerView: FlatPickerView, attributedTitleForRow row: Int) -> NSAttributedString?
    func flatPicker(pickerView: FlatPickerView, viewForRow row: Int) -> UIView?
    func flatPickerViewForSelectedItem(pickerView: FlatPickerView) -> UIView?
    func flatPickerShouldShowSelectionView(pickerView: FlatPickerView) -> Bool
    func flatPicker(pickerView: FlatPickerView, didSelectRow row: Int)
    func flatPicker(pickerView: FlatPickerView, didPassOnSelection row: Int)
    func flatPickerSpacingBetweenItems(pickerView: FlatPickerView)-> CGFloat?
}

open class FlatPickerView: UIView {
    
    //MARK: Definitions
    public enum Direction {
        case horizontal
        case vertical
    }
    
    //MARK: Properties
    
    open var itemSize: CGFloat = 50 {
        didSet{
            highlitedViewFrameForDirection()
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
    
    open var isScroolEnabled: Bool = true {
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
            highlitedViewFrameForDirection()
            
        }
    }
    
    open fileprivate(set) var currentSelectedRow: Int!
    
    
    
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
        collectionView?.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        collectionView?.performBatchUpdates(nil, completion: nil)
        highlitedViewFrameForDirection()
        
        let indexPath : IndexPath =  currentSelectedRow == nil ? IndexPath(item: (self.dataSource?.flatPickerNumberOfRows(pickerView: self) ?? 0)/2, section: 0) : IndexPath(item: currentSelectedRow, section: 0)
        selectItemAtIntexPath(indexPath: indexPath, animated: false, triggerDelegate: false)
    }

    
    private func initialize() {
        setupCollectionView()
        //Setting default direction
        direction = .vertical
        setupPickerSelectionView()
    }
    
    
    open func reload() {
        self.collectionView?.reloadData()
    }
    
    private func highlitedViewFrameForDirection() {
        if direction != nil {
            if direction == .horizontal {
                highlightedView?.frame = CGRect(x: frame.size.width/2 - (itemSize/2),
                                                y: 0,
                                                width: itemSize, height: frame.size.height)
            }else{
                highlightedView?.frame = CGRect(x: 0,
                                                y: frame.size.height/2 - (itemSize/2),
                                                width: frame.size.width, height: itemSize)
            }
        }
    }
    
    private func setupCollectionView() {
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero,
                                                                collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DefaultCell")
        collectionView.register(TextCollectionViewCell.self, forCellWithReuseIdentifier: TextCollectionViewCell.reuseIdentifier)
        addSubview(collectionView)
        collectionView.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        self.collectionView = collectionView
    }
    
    private func setupPickerSelectionView() {
        highlightedView?.removeFromSuperview()
        let pickerSelectionView : UIView = self.delegate?.flatPickerViewForSelectedItem(pickerView: self) ?? PickerDefaultSelectedItemView(frame: CGRect.zero, direction : direction)
        if pickerSelectionView is PickerDefaultSelectedItemView {
            pickerSelectionView.isUserInteractionEnabled = false
        }
        addSubview(pickerSelectionView)
        bringSubview(toFront: pickerSelectionView)
        self.highlightedView = pickerSelectionView
        highlitedViewFrameForDirection()
        highlightedView.isHidden = !(self.delegate?.flatPickerShouldShowSelectionView(pickerView: self) ?? true)
    }
    
    private func setupInsetForCollection(){
        if direction == .vertical {
            collectionView.contentInset = UIEdgeInsets(top: (frame.size.height/2) - (itemSize/2),
                                                       left: 0,
                                                       bottom: (frame.size.height/2) - (itemSize/2) ,
                                                       right: 0)
        }else{
            collectionView.contentInset = UIEdgeInsets(top: 0,
                                                       left: (frame.size.width/2) - (itemSize/2),
                                                       bottom: 0,
                                                       right: (frame.size.width/2) - (itemSize/2))
        }
    }
    
    //MARK: Public functions
    open func selectRow(at row: Int, animated: Bool) {
        selectItemAtIntexPath(indexPath: IndexPath(item: row, section: 0), animated: animated, triggerDelegate: true)
    }
    
    open func viewForRow(at row: Int) -> UIView?{
        return collectionView.cellForItem(at: IndexPath(item: row, section: 0))?.contentView
    }
    
}

extension FlatPickerView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource?.flatPickerNumberOfRows(pickerView: self) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let text = self.delegate?.flatPicker(pickerView: self, titleForRow: indexPath.item) {
            return generateCellForText(collectionView, indexPath: indexPath, text: text)
        }else if let attrText = self.delegate?.flatPicker(pickerView: self, attributedTitleForRow: indexPath.row){
            return generateCellForAttibutedText(collectionView, indexPath: indexPath, attributedText: attrText)
        }else if let view = self.delegate?.flatPicker(pickerView: self, viewForRow: indexPath.item){
            return generateCustomViewCell(collectionView, indexPath: indexPath, view: view)
        }
        return UICollectionViewCell()
    }
    
    //MARK: Generate cells
    private func generateCustomViewCell(_ collectionView: UICollectionView, indexPath: IndexPath, view : UIView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DefaultCell", for: indexPath)
        view.frame =  cell.contentView.frame
        cell.contentView.subviews.forEach({$0.removeFromSuperview()})
        cell.contentView.addSubview(view)
        return cell
    }
    
    private func generateCellForAttibutedText(_ collectionView: UICollectionView, indexPath: IndexPath, attributedText : NSAttributedString) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCollectionViewCell.reuseIdentifier, for: indexPath) as! TextCollectionViewCell
        cell.textLabel.attributedText = attributedText
        return cell
    }
    
    private func generateCellForText(_ collectionView: UICollectionView, indexPath: IndexPath, text : String) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCollectionViewCell.reuseIdentifier, for: indexPath) as! TextCollectionViewCell
        cell.textLabel.text = text
        return cell
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
        var incrementalSpacing: CGFloat = 0
        var point : CGPoint = CGPoint(x: highlightedView.center.x + collectionView.contentOffset.x, y: highlightedView.center.y + collectionView.contentOffset.y)
        //Searching for the nearst cell
        repeat {
            if let indexPath = collectionView.indexPathForItem(at: point) {
                selectItemAtIntexPath(indexPath: indexPath, animated: true, triggerDelegate: true)
                break
            }else {
                incrementalSpacing += 1.0
                if direction == .vertical {
                    point = CGPoint(x: highlightedView.center.x + collectionView.contentOffset.x,
                                    y: highlightedView.center.y + collectionView.contentOffset.y + incrementalSpacing)
                }else {
                    point = CGPoint(x: highlightedView.center.x + collectionView.contentOffset.x + incrementalSpacing,
                                    y: highlightedView.center.y + collectionView.contentOffset.y)
                }
            }
        } while point.x < frame.size.width || point.y < frame.size.height

    }
    
    fileprivate func selectItemAtIntexPath(indexPath: IndexPath, animated: Bool, triggerDelegate: Bool){
        if indexPath.item >= 0 && indexPath.row < collectionView.numberOfItems(inSection: 0){
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
}

extension FlatPickerView : UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if direction == .horizontal {
            return CGSize(width: itemSize , height: self.frame.size.height )
        }
        return CGSize(width: self.frame.size.width , height: itemSize )
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.delegate?.flatPickerSpacingBetweenItems(pickerView: self) ?? 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.delegate?.flatPickerSpacingBetweenItems(pickerView: self) ?? 1
    }
}

