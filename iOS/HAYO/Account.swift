//
//  Account.swift
//  Sheep
//
//  Created by mono on 7/25/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation

class Account: User {

    override class func MR_entityName() -> String {
        return "Account"
    }

    @NSManaged var imageData: NSData
    
    override var image: UIImage? { get { return UIImage(data: imageData) } }
    
    var _barButtonImage: UIImage? = nil
    var barButtonImage: UIImage {
    get {
        if nil == _barButtonImage {
            _barButtonImage = self.image!.circularImage(36).borderedImage()
        }
        return _barButtonImage!
    }
    }
    
    class func instance() -> Account! {
        if Account.MR_countOfEntities() == 0 {
            return nil
        }
        return Account.MR_findFirst() as Account
    }
    
    class func loginToTwitter(completed: (user: TypedTwitterUser?) -> ()) {
        
        PFTwitterUtils.logInWithBlock {
            (user: PFUser!, error: NSError!) in
            if nil == user {
                if nil == error {
                    println("Uh oh. The user cancelled the Twitter login.")
                    completed(user: nil)
                    return;
                }
                println("Uh oh. An error occurred: %@", error)
                completed(user: nil)
                return
            }
            println("User with twitter logged in!, user: %@", user)
            if user.isNew {
                let twitter = PFTwitterUtils.twitter()
                println(twitter.consumerKey)
                let url = NSURL(string: NSString(format: "https://api.twitter.com/1.1/users/show.json?screen_name=%@", twitter.screenName))
                println(url)
                var request = NSMutableURLRequest(URL: url)
                twitter.signRequest(request)
                var response:NSURLResponse?
                // TODO: エラー処理
                var error: NSError?
                let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as NSDictionary
                println(json)
                let twitterUser = TypedTwitterUser(data: json)
                completed(user: twitterUser)
                return
            }
            RestClient.sharedInstance.get(user.imageURL) { image in
                Account.createAccountSync(user.username, image: image!)
                completed(user: nil)
            }
        }
    }
    
    
    class func loginToFacebook(completed: (user: TypedFacebookUser?) -> ()) {
        
        // TODO: permissions
        let permissions = ["user_about_me", "user_relationships", "user_birthday", "user_location", "read_friendlists", "user_status", "user_friends"]
        PFFacebookUtils.logInWithPermissions(permissions, block: {user, error in
            
            if nil == user {
                if nil == error {
                    println("Uh oh. The user cancelled the Facebook login.")
                    completed(user: nil)
                    return;
                }
                println("Uh oh. An error occurred: %@", error)
                completed(user: nil)
                return
            }
            println("User with facebook logged in!, user: %@", user)
            if user.isNew || nil == user.imageURL? {
                FBRequestConnection.startForMeWithCompletionHandler({ connection, result, error in
                    let facebookUser = TypedFacebookUser(data: result as NSDictionary)
                    completed(user: facebookUser)
                    })
                return
            }
            
            RestClient.sharedInstance.get(user.imageURL) { image in
                Account.createAccountSync(user.username, image: image!)
                completed(user: nil)
            }
            })
    }

    
    
    
    class func searchFriendCandidates(completed: (friendCandidates: [PFUser]) -> ()) {
        searchFacebookFriends() { fbCandidates in
            let facebookIds = fbCandidates.map() { c in return c.id } as [String]
            self.searchTwitterFriends() { twCandidates in
                let twitterIds = twCandidates.map() { c in return c.id } as [String]
                ParseClient.sharedInstance.searchFriends(facebookIds, twitterIds: twitterIds) { users, error in
                    completed(friendCandidates: users)
                }
            }
        }
    }
    
    class func searchFacebookFriends(completed: (friendCandidates: [SNSUser]) -> ()) {
        if !PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()) {
            completed(friendCandidates: [])
            return
        }
        FBRequestConnection.startForMyFriendsWithCompletionHandler({ connection, result, error in
            let dict = result as NSDictionary
            let data = dict["data"] as [NSDictionary]
            println("count: \(data.count)")
            
            let results = data.map() { dict in
//                println(dict)
                return TypedFacebookUser(data: dict)
            } as [SNSUser]
            completed(friendCandidates: results)
            })
    }
    
    class func searchTwitterFriends(completed: (friendCandidates: [SNSUser]) -> ()) {
        if !PFTwitterUtils.isLinkedWithUser(PFUser.currentUser()) {
            completed(friendCandidates: [])
            return
        }
        let twitter = PFTwitterUtils.twitter()
        let url = NSURL(string: NSString(format: "https://api.twitter.com/1.1/friends/list.json?screen_name=%@", twitter.screenName))
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        twitter.signRequest(request)
        var response:NSURLResponse?
        // TODO: エラー処理
        var error: NSError?
        let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)!
        let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error) as NSDictionary
//        println(json)
        let friends = json["users"] as [NSDictionary]
        let results = friends.map() { dict in
//            println(dict)
            return TypedTwitterUser(data: dict)
            } as [SNSUser]
        completed(friendCandidates: results)
    }
    
    class func createAsync(username: String, imageURL: String, image: UIImage, snsUser: SNSUser, completed: (error: NSError?) -> ()) {
        dispatchAsync(.High) {
            let user = PFUser.currentUser()
            user.username = username
            user.imageURL = imageURL
            if let fUser = snsUser as? TypedFacebookUser {
                user.email = fUser.email
                user.facebookId = fUser.id
            }
            if let tUser = snsUser as? TypedTwitterUser {
                user.twitterId = tUser.id
            }
            var error: NSError? = nil
            user.save(&error)
            println(error)
            self.createAccountSync(user.username, image: image)
            dispatchOnMainThread() {
                completed(error: nil)
            }
        }
    }
    
    class func associateInstallation() {
        let installation = PFInstallation.currentInstallation()
        let user = PFUser.currentUser()
        installation["user"] = user
        installation.save()
    }
    
    private class func createAccountSync(username: String, image: UIImage) {
        associateInstallation()
        var account = Account.instance()
        if account == nil {
            account = Account.MR_createEntity() as Account
        }
        account.username = username
        let imageData = NSData(data: UIImageJPEGRepresentation(image, 1))
        account.imageData = imageData
        account.parseObjectId = PFUser.currentUser().objectId
        account.imageURL = PFUser.currentUser().getImageURL()
        account.saveSync()
    }
    
    class func deleteInstanceIfExists() {
        let account = Account.instance()
        if account == nil {
            return
        }
        let moc = account.managedObjectContext
        moc.deleteObject(account)
        moc.MR_saveOnlySelfAndWait()
    }

    class func unregister(completed: () -> ()) {
        PFUser.currentUser().deleteInBackgroundWithBlock() {success, error in
            let url1 = NSPersistentStore.MR_urlForStoreName("HAYO.sqlite")
            let url2 = NSPersistentStore.MR_urlForStoreName("HAYO.sqlite-shm")
            let url3 = NSPersistentStore.MR_urlForStoreName("HAYO.sqlite-wal")
            var error: NSError?
            for url in [url1, url2, url3] {
                NSFileManager.defaultManager().removeItemAtURL(url, error: &error)
                println(error)
            }
            MagicalRecord.cleanUp()
            MagicalRecord.setupCoreDataStack()
            completed()
        }
    }
}

extension PFUser {
    var imageURL: String! {
    set {
        self.setObject(newValue, forKey: "imageURL")
    }
    get {
        return self.objectForKey("imageURL") as String?
    }
    }
    func getImageURL() -> String! {
        return self.imageURL
    }
    var twitterId: String? {
        set {
            if newValue == nil  { return }
            self.setObject(newValue, forKey: "twitterId")
        }
        get { return self.objectForKey("twitterId") as String? }
    }
    var facebookId: String? {
        set {
            if newValue == nil  { return }
            self.setObject(newValue, forKey: "facebookId")
        }
        get { return self.objectForKey("facebookId") as String? }
    }
}


extension NSError {
    func isEmailTaken() -> Bool {
        return self.domain == PFParseErrorDomain && self.code == kPFErrorUserEmailTaken
    }
}