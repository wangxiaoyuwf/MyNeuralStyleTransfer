//
//  StyleCollectionViewCell.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 4/2/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import UIKit

class StyleCollectionViewCell: UICollectionViewCell {
 
    @IBOutlet weak var lbl: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth =  1
    }
}
