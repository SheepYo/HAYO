//
//  FriendViewController.swift
//  Sheep
//
//  Created by mono on 8/6/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation
class FriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    var user: User!
    var hayoList: NSFetchedResultsController!
    private var _needReload = false
    
    class func create() -> UINavigationController {
        let sb = UIStoryboard(name: "Friend", bundle: nil)
        let navVC = sb.instantiateInitialViewController() as UINavigationController
        return navVC
    }
    class func createWithoutNavigation() -> FriendViewController {
        let sb = UIStoryboard(name: "Friend", bundle: nil)
        let navVC = sb.instantiateInitialViewController().topViewController as FriendViewController
        return navVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.navigationController.viewControllers[0] as UIViewController != self {
            self.navigationItem.leftBarButtonItem = nil;
        }
        
        hayoList = Hayo.fetchHayoList(user, delegate: self)
        
        self.tableView.backgroundView = nil
        
        self.configureBackgroundTheme()
        profileImageView.configureAsMyCircle()
        
        tableView.registerNib(UINib(nibName: "MyHayoCell", bundle: nil), forCellReuseIdentifier: "MyHayoCell")
        tableView.registerNib(UINib(nibName: "FriendHayoCell", bundle: nil), forCellReuseIdentifier: "FriendHayoCell")
        self.tableView.rowHeight = 60
        
        println(user.username)
        self.title = user.username
        profileImageView.sd_setImageWithURL((NSURL(string: user.imageURL)), completed: {image, error, type, url -> () in
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Hayo.updateHayoList(user)
        
    }
    
    @IBAction func closeDidTap(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return hayoList.fetchedObjects.count
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let hayo = hayoList.fetchedObjects[indexPath.section] as Hayo
        if hayo.from.parseObjectId == Account.instance().parseObjectId {
            let cell = tableView.dequeueReusableCellWithIdentifier("MyHayoCell", forIndexPath: indexPath) as MyHayoCell
            cell.hayo = hayo
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendHayoCell", forIndexPath: indexPath) as FriendHayoCell
        println(hayo.from.parseObjectId)
        cell.setHayo(hayo, imageHidden: true) { user in
        }
        return cell
    }
    
    func tableView(tableView: UITableView!, viewForHeaderInSection section: Int) -> UIView! {
        let v = UIView()
        v.backgroundColor = UIColor.clearColor()
        return v
    }
    
    func tableView(tableView: UITableView!, heightForHeaderInSection section: Int) -> CGFloat {
        return 22
    }
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        if _needReload {
            tableView.reloadData()
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!)  {
        _needReload = false
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        if type != .Update {
            _needReload = true
        }
    }
}