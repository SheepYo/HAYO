//
//  Account.swift
//  Sheep
//
//  Created by mono on 7/25/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation

class Account: NSManagedObject {
    class func MR_entityName() -> String {
        return "Account"
    }
    
    @NSManaged
    var username: String
    @NSManaged
    var nickname: String
    @NSManaged
    var imageData: NSData
    
    var image: UIImage {
    get {
        return UIImage(data: imageData)
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
            if !user {
                if !error {
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
                request.HTTPMethod = "GET"
                twitter.signRequest(request)
                var response:NSURLResponse?
                // TODO: エラー処理
                var error: NSError?
                let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as NSDictionary
                println(json)
                let twitterUser = TypedTwitterUser(data: json)
                completed(user: twitterUser)
                return
            }
            RestClient.sharedInstance.get(user.imageURL) { image in
                Account.createAccountSync(user.username, nickname: user.nickname, image: image!)
                completed(user: nil)
            }
        }
    }
    
    
    class func loginToFacebook(completed: (user: TypedFacebookUser?) -> ()) {
        
        // TODO: permissions
        let permissions = ["user_about_me", "user_relationships", "user_birthday", "user_location"]
        PFFacebookUtils.logInWithPermissions(permissions, block: {user, error in
            if !user {
                if !error {
                    println("Uh oh. The user cancelled the Facebook login.")
                    completed(user: nil)
                    return;
                }
                println("Uh oh. An error occurred: %@", error)
                completed(user: nil)
                return
            }
            println("User with facebook logged in!, user: %@", user)
            if user.isNew {
                FBRequestConnection.startForMeWithCompletionHandler({ connection, result, error in
                    let facebookUser = TypedFacebookUser(data: result as NSDictionary)
                    completed(user: facebookUser)
                    })
                return
            }
            
            RestClient.sharedInstance.get(user.imageURL) { image in
                Account.createAccountSync(user.username, nickname: user.nickname, image: image!)
                completed(user: nil)
            }
            })
    }
    
    class func createAsync(nickname: String, imageURL: String, image: UIImage, email: String?, completed: (error: NSError?) -> ()) {
        dispatchAsync(.High) {
            let installation = PFInstallation.currentInstallation()
            let user = PFUser.currentUser()
            println(user.username)
            installation["user"] = user
            installation.save()
            user.nickname = nickname
            user.imageURL = imageURL
            user.email = email
            var error: NSError? = nil
            user.save(&error)
            println(error)
            self.createAccountSync(user.username, nickname: nickname, image: image)
            dispatchOnMainThread() {
                completed(error: nil)
            }
        }
    }
    
    private class func createAccountSync(username: String, nickname: String, image: UIImage) {
        let account = Account.MR_createEntity() as Account
        account.username = username
        account.nickname = nickname
        let imageData = NSData(data: UIImageJPEGRepresentation(image, 1))
        account.imageData = imageData
        account.saveSync()
    }
    
    class func deleteInstance() {
        let account = Account.instance()
        let moc = account.managedObjectContext
        moc.deleteObject(account)
        moc.MR_saveOnlySelfAndWait()
    }
}

extension PFUser {
    var nickname: String! {
    set {
        self.setObject(newValue, forKey: "nickname")
    }
    get {
        return self.objectForKey("nickname") as String
    }
    }
    var imageURL: String! {
    set {
        self.setObject(newValue, forKey: "imageURL")
    }
    get {
        return self.objectForKey("imageURL") as String
    }
    }
    func getImageURL() -> String! {
        return self.imageURL
    }
}


extension NSError {
    func isEmailTaken() -> Bool {
        return self.domain == PFParseErrorDomain && self.code == kPFErrorUserEmailTaken
    }
}