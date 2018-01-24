//
//  LeftDrawerViewController.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/22/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit

class LeftDrawerViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //let logoButton = UIButton(frame: CGRect(origin: CGPoint(x:self.view.frame.width/2, y: self.view.frame.height-200), size: CGSize(width: 50, height: 50)))
        //logoButton.imageView?.image = UIImage(named: "logo")
        // self.navigationController?.view.addSubview(logoButton)
        
        self.tableView.allowsSelection = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.delaysContentTouches = false
        for i in self.view.gestureRecognizers! {
            print((i as UIGestureRecognizer).cancelsTouchesInView)
            (i as UIGestureRecognizer).cancelsTouchesInView = false
        }
        for i in (self.navigationController?.view.gestureRecognizers!)! {
            print((i as UIGestureRecognizer).cancelsTouchesInView)
            (i as UIGestureRecognizer).cancelsTouchesInView = false
        }
       
    }
    
    // MARK: <TableViewDataSource>
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if indexPath.row == 2 {
            print(2)
            appDelegate.centerViewController = appDelegate.personalGalleryViewController()
        } else if indexPath.row == 3 {
            print(3)
            appDelegate.centerViewController = appDelegate.mainPensieveViewController()
        } else if indexPath.row == 4 {
            print(4)
            appDelegate.centerViewController = appDelegate.instagramViewController()
        }
    }
    
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    
    
}
