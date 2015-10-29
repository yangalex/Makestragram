//
//  PostTableViewCell.swift
//  Makestagram
//
//  Created by Alexandre Yang on 6/26/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Bond
import Parse

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likesIconImageView: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
    }
    
    @IBAction func likeButtonTapped(sender: AnyObject) {
        post?.toggleLikePost(PFUser.currentUser()!)
    }
    
    var likeBond: Bond<[PFUser]?>!
    
    var post: Post? {
        didSet {
            // free memory of image stored with post that is no longer displayed
            if let oldValue = oldValue where oldValue != post {
                likeBond.unbindAll()
                postImageView.designatedBond.unbindAll()
                if (oldValue.image.bonds.count == 0) {
                    oldValue.image.value = nil
                }
            }
            if let post = post {
                // bind image of the post to the 'postImage' view
                post.image ->> postImageView
                
                // bind the likeBond that we defined earlier, to update like lable and button when likes change
                post.likes ->> likeBond
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        likeBond = Bond<[PFUser]?>() { [unowned self] likeList in
            if let likeList = likeList {
                self.likesLabel.text = self.stringFromUserList(likeList)
                
                self.likeButton.selected = contains(likeList, PFUser.currentUser()!)
                
                self.likesIconImageView.hidden = (likeList.count == 0)
            } else {
                // if there is no list of users that like this post, reset everything
                self.likesLabel.text = ""
                self.likeButton.selected = false
                self.likesIconImageView.hidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // Generates a comma separated list of usernames from an array
    func stringFromUserList(userList: [PFUser]) -> String {
        let usernameList = userList.map { user in user.username!}
        
        let commaSeparatedUserList = ", ".join(usernameList)
        
        return commaSeparatedUserList
    }

}
