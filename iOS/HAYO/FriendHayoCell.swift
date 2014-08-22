//
//  FriendHayoCell.swift
//  Sheep
//
//  Created by mono on 8/8/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation
class FriendHayoCell: SWTableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var _hayo: Hayo! = nil
    var hayo: Hayo! {
        set {
            if nil == newValue {
                return
            }
            _hayo = newValue
            self.profileImageView.sd_setImageWithURL((NSURL(string: _hayo.from.imageURL)), completed: {image, error, type, url -> () in
            })
            messageLabel.text = NSString(format: localize("HayoFriendMessageFormat"), _hayo.message)
        }
        get {
            return _hayo
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImageView.configureAsCircle()
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = themeColor.CGColor
        
        self.rightUtilityButtons = rightButtons()
    }
    
    func rightButtons() -> NSArray {
        var buttons = NSMutableArray()
        buttons.sw_addUtilityButtonWithColor(UIColor.redColor(), title: localize("Dame"))
        buttons.sw_addUtilityButtonWithColor(UIColor.blueColor(), title: localize("OK"))
        return buttons
    }
}