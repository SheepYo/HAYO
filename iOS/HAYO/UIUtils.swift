//
//  ViewUtils.swift
//  Sheep
//
//  Created by mono on 7/29/14.
//  Copyright (c) 2014 Sheep. All rights reserved.
//

import Foundation
import QuartzCore

func localize(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

let cancelString = localize("Cancel")
let okString = localize("Ok")
let confirmString = localize("ConfirmString")

let themeColor = UIColor(red: 62/255.0, green: 182/255.0, blue: 208/255.0, alpha: 1)

func isIOS8OrLater() -> Bool {
    return (UIDevice.currentDevice().systemVersion as NSString).floatValue >= 8.0;
}

extension UIViewController {
    
    func showAlertView(title: String, message: String, okBlock: () -> (), cancelBlock: (() -> ())?) {
        let alert = Alert.sharedInstance
        alert.showAlertView(self, title: title, message: message, okBlock: okBlock, cancelBlock: cancelBlock)
    }
    func showActionSheet(title: String, normalButtonActions: [TitleAction] = [], destructiveTitleAction: TitleAction? = nil, cancelBlock: () -> () = {}) {
        let alert = Alert.sharedInstance
        alert.showActionSheet(self, title: title, normalButtonActions: normalButtonActions, destructiveTitleAction: destructiveTitleAction, cancelBlock: cancelBlock);
    }

    func shareMyId() {
        let message = NSString(format: localize("ShareMyIDFormat"), Account.instance().username)
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        self.presentViewController(activityVC, animated: true) {}
    }
    
    func configureBackgroundTheme() {       
        self.view.configureBackgroundTheme()
    }
    
    func designButton(button: UIButton) {        
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
    }
    func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    func showError(message: String) {
        SVProgressHUD.showErrorWithStatus(message)
    }
    func showError() {
        showError(localize("ErrorOccured"))
    }
    func showSuccess() {
        showSuccess(localize("Succeeded"))
    }
    func showSuccess(message: String) {
        executeOnMainThread { SVProgressHUD.showSuccessWithStatus(message) }
        
    }
    func showProgress() {
        SVProgressHUD.showWithMaskType(UInt(SVProgressHUDMaskTypeGradient))
    }
    func showProgress(message: String) {
        SVProgressHUD.showWithStatus(message, maskType: UInt(SVProgressHUDMaskTypeGradient))
    }
    func dismissProgress() {
        executeOnMainThread { SVProgressHUD.dismiss() }
    }
    func executeOnMainThread(action: () -> ()) {
        if NSThread.isMainThread() {
            action()
            return
        }
        dispatchOnMainThread() {
            action()
        }
    }
    func notImplemented() {
        showError("未実装です")
    }
}

extension UIView {
    func configureBackgroundTheme() {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        let startColor = UIColor(hue: 162/360.0, saturation: 0.67, brightness: 0.82, alpha: 1).CGColor
        let endColor = UIColor(hue: 205/360.0, saturation: 0.76, brightness: 0.93, alpha: 1).CGColor
        gradient.colors = NSArray(objects: startColor, endColor)
        layer.insertSublayer(gradient, atIndex: 0)
    }
    func configureAsCircle() {
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
    }
    func configureAsMyCircle() {
        self.configureAsCircle()
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    }
    func enableBlurEffect() -> Bool {
        if NSClassFromString("UIBlurEffect") != nil {
            let effect = UIBlurEffect(style: .Dark)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = self.frame
            self.insertSubview(effectView, atIndex: 0)
            return true
        }
        return false
    }
}
extension UIScrollView {
    func changeBottomInset(inset: CGFloat) {
        changeTopInset(nil, bottomInset: inset)
    }
    func changeTopInset(inset: CGFloat) {
        changeTopInset(inset, bottomInset: nil)
    }
    func changeTopInset(topInset: CGFloat?, bottomInset: CGFloat?) {
        var insets = self.contentInset
        if let top = topInset {
            insets.top = top
        }
        if let bottom = bottomInset {
            insets.bottom = bottom
        }
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
}