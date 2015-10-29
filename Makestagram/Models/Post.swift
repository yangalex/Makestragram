//
//  Post.swift
//  Makestagram
//
//  Created by Alexandre Yang on 6/25/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse
import Bond
import ConvenienceKit

class Post : PFObject, PFSubclassing {
    
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    
    var image: Dynamic<UIImage?> = Dynamic(nil)
    var photoUploadTask: UIBackgroundTaskIdentifier?
    var likes = Dynamic<[PFUser]?>(nil)
    
    static var imageCache: NSCacheSwift<String, UIImage>!
    
    //MARK: PFSubclassing Protocol
    
    static func parseClassName() -> String {
        return "Post"
    }
    
    override init() {
        super.init()
    }
    
    // subclassing stuff
    override class func initialize() {
        var onceToken : dispatch_once_t = 0
        dispatch_once(&onceToken) {
            // inform Parse about this subclass
            self.registerSubclass()
            Post.imageCache = NSCacheSwift<String, UIImage>()
        }
    }
    
    func uploadPost() {
        let imageData = UIImageJPEGRepresentation(image.value, 0.8)
        let imageFile = PFFile(data: imageData)
        
        photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        }

        
        imageFile.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        }
        
        // associtate post with current user
        user = PFUser.currentUser()
        
        self.imageFile = imageFile
        saveInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
    }
    
    func downloadImage() {
        image.value = Post.imageCache[self.imageFile!.name]
        
        // if image not downloaded yet, get it
        if(image.value == nil) {
            imageFile?.getDataInBackgroundWithBlock {
                (data: NSData?, error: NSError?) -> Void in
                
                if let error = error {
                    ErrorHandling.defaultErrorHandler(error)
                }
                
                if let data = data {
                    let image = UIImage(data: data, scale: 1.0)
                    self.image.value = image
                    Post.imageCache[self.imageFile!.name] = image
                }
            }
        }
    }
    
    func fetchLikes() {
        if(likes.value != nil) {
            return
        }
        
        ParseHelper.likesForPost(self) {
            (var likes: [AnyObject]?, error:NSError?) -> Void in
            // removes likes from users that don't exist anymore
            likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            // replaces like objects with their respective users
            self.likes.value = likes?.map { like in
                let like = like as! PFObject
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        }
    }
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return contains(likes, user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if(doesUserLikePost(user)) {
            likes.value = likes.value?.filter { $0 != user} // really smart way of finding and delteing a value from array
            ParseHelper.unlikePost(user, post: self)
        } else {
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
}














