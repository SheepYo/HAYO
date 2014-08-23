//
//  FriendView.swift
//  Sheep
//
//  Created by mono on 8/3/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation
class FriendView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    class func create() -> FriendView {
        return NSBundle.mainBundle().loadNibNamed("FriendView", owner: self, options: nil)[0] as FriendView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.configureAsMyCircle()
        
        self.layer.borderColor = UIColor.whiteColor().CGColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 4
        
    }
    
    var _user: User!
    var user: User! {
    get {
        return _user
    }
    set {
        _user = newValue
        nicknameLabel.text = _user.username
        if let image = _user.image {
            imageView.image = image
            return
        }
        imageView.sd_setImageWithURL(NSURL(string: _user.imageURL), completed: {image, error, type, url -> () in
            })
    }
    }
}