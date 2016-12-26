//
//  TextCollectionViewCell.swift
//  CustomPickerView
//
//  Created by Luciano Almeida on 26/12/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

class TextCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier: String = "TextCollectionViewCell"
    
    private(set) weak var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.inititialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.inititialize()
    }
    
    private func inititialize() {
        contentView.subviews.forEach({$0.removeFromSuperview()})
        let label = UILabel()
        label.textAlignment = .center
        contentView.addSubview(label)
        textLabel = label
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = contentView.frame
    }
}
