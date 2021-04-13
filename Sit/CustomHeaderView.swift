//
//  CustomHeaderView.swift
//  Sit
//
//  Created by Даниил  on 25.02.2021.
//

import UIKit


protocol HeaderViewDelegate: class {
    func expandedSection(button: UIButton)
}

class CustomHeaderView: UITableViewHeaderFooterView {

    weak var delegate: HeaderViewDelegate?
    @IBOutlet var headerTitle: UILabel!
    @IBOutlet var arrorButton: UIButton!
    
    func configure(title:String, section: Int){
        headerTitle.text = title
        arrorButton.tag = section
    }
    
    func rotateImage(_ expanded: Bool){
        if expanded{
            arrorButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        } else {
            arrorButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat.zero)
        }
    }

    @IBAction func showButton(_ sender: UIButton) {
        delegate?.expandedSection(button: sender)
    }
   
    
}
