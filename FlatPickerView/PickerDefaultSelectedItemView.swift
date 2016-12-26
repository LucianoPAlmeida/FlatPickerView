//
//  PickerDefaultSelectedItemView.swift
//  CustomPickerView
//
//  Created by Luciano Almeida on 26/12/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

open class PickerDefaultSelectedItemView: UIView {
    
    open var direction: FlatPickerView.Direction = .vertical {
        didSet{
            setNeedsDisplay()
        }
    }
    
    open var separatorEdge: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    convenience init(frame: CGRect, direction: FlatPickerView.Direction) {
        self.init(frame: frame)
        self.direction = direction
        tintColor = UIColor.black
        backgroundColor = UIColor.clear
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        let path: UIBezierPath = UIBezierPath()
        let edgedRect = UIEdgeInsetsInsetRect(rect, separatorEdge)
        
        path.move(to: edgedRect.origin)
        if direction == .horizontal {
            path.addLine(to: CGPoint(x: edgedRect.origin.x , y: edgedRect.origin.y + edgedRect.size.height) )
        }else {
            path.addLine(to: CGPoint(x: edgedRect.origin.x + edgedRect.size.width, y: edgedRect.origin.y))
        }
        
        path.move(to:  CGPoint(x: edgedRect.origin.x + edgedRect.size.width, y: edgedRect.origin.y + edgedRect.size.height))
        if direction == .horizontal {
            path.addLine(to: CGPoint(x: edgedRect.origin.x + edgedRect.size.width, y: edgedRect.origin.y ))
        }else {
            path.addLine(to: CGPoint(x: edgedRect.origin.x , y: edgedRect.origin.y + edgedRect.size.height))
        }
        tintColor.set()
        path.lineWidth = 0.5
        path.stroke()
    }
 

}
