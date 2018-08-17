//
//  AppDelegate.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/19/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let kKGDrawersStoryboardName = "Main"
    
    let kMainPensieveViewControllerStoryboardId = "MainPensieveViewControllerStoryboardId"
    let kPersonalGalleryViewViewControllerStoryboardId = "PersonalGalleryiewControllerStoryboardId"
    let kKGLeftDrawerStoryboardId = "KGLeftDrawerViewControllerStoryboardId"
    let kInstagramViewControllerStoryboardId = "InstagramViewControllerStoryboardId"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
         IQKeyboardManager.shared.enable = true
        
        window?.rootViewController = drawerViewController
        
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    private var _drawerViewController: KGDrawerViewController?
    var drawerViewController: KGDrawerViewController {
        get {
            print(1)
            if let viewController = _drawerViewController {
                print(2)
                return viewController
            }
            return prepareDrawerViewController()
        }
    }
    
    func prepareDrawerViewController() -> KGDrawerViewController {
        let drawerViewController = KGDrawerViewController()
        drawerViewController.centerViewController = mainPensieveViewController()
        drawerViewController.leftViewController = leftViewController()
        //drawerViewController.rightViewController = rightViewController()
        drawerViewController.backgroundImage = UIImage(named: "sky3")
        
        _drawerViewController = drawerViewController
        
        return drawerViewController
    }
    
    private func drawerStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: kKGDrawersStoryboardName, bundle: nil)
        return storyboard
    }
    
    private func viewControllerForStoryboardId(storyboardId: String) -> UIViewController {
        print(500)
        let viewController: UIViewController = drawerStoryboard().instantiateViewController(withIdentifier: storyboardId)
        print(501)
        return viewController
    }
    
    func mainPensieveViewController() -> UIViewController {
        print(10)
        let viewController = viewControllerForStoryboardId(storyboardId: kMainPensieveViewControllerStoryboardId)
        print(11)
        return viewController
    }
    
    func instagramViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(storyboardId: kInstagramViewControllerStoryboardId)
        return viewController
    }
    
    func personalGalleryViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(storyboardId:  kPersonalGalleryViewViewControllerStoryboardId)
        return viewController
    }
    
    private func leftViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(storyboardId: kKGLeftDrawerStoryboardId)
        return viewController
    }
    
    /*
     private func rightViewController() -> UIViewController {
        let viewController = viewControllerForStoryboardId(storyboardId: kKGRightDrawerStoryboardId)
        return viewController
    }
     */
    
    func toggleLeftDrawer(sender:AnyObject, animated:Bool) {
        print("toggle left app delegate")
        _drawerViewController?.toggleDrawer(.left, animated: true, complete: { (finished) -> Void in
            // do nothing
            print("toggle left app delegate done")
        })
    }
    
    func toggleRightDrawer(sender:AnyObject, animated:Bool) {
        _drawerViewController?.toggleDrawer(.right, animated: true, complete: { (finished) -> Void in
            // do nothing
        })
    }
    
    private var _centerViewController: UIViewController?
    var centerViewController: UIViewController {
        get {
            if let viewController = _centerViewController {
                return viewController
            }
            return mainPensieveViewController()
        }
        set {
            if let drawerViewController = _drawerViewController {
                drawerViewController.closeDrawer(drawerViewController.currentlyOpenedSide, animated: true) { finished in }
                if drawerViewController.centerViewController != newValue {
                    drawerViewController.centerViewController = newValue
                }
            }
            _centerViewController = newValue
        }
    }

}

