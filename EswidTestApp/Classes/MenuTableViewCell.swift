//
//  MenuTableViewCell.swift
//  EswidTestApp
//
//  Created by Раис Аглиуллов on 06/06/2019.
//  Copyright © 2019 Раис Аглиуллов. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {


    @IBOutlet weak var customImageView: UIImageView!{
        didSet {
            customImageView.layer.cornerRadius = 25
            customImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
}
