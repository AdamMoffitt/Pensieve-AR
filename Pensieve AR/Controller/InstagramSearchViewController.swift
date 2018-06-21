//
//  InstagramSearchViewController.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/24/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import YNSearch

class InstagramSearchViewController: YNSearchViewController, YNSearchDelegate {

    var username : String = ""
    var ynSearch = YNSearch()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let demoSearchHistories = ["admoffitt15"]
        
        let ynSearch = YNSearch()
        ynSearch.setSearchHistories(value: demoSearchHistories)
        
        self.ynSearchinit()
        
        self.delegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let database1 = "testuser"
        let database2 = "danthemanlinderman"
        let database3 = "admoffitt15"
        let demoDatabase = [database1, database2, database3]
        
        self.initData(database: demoDatabase)
        self.setYNCategoryButtonType(type: .colorful)
    }

    func ynSearchListViewDidScroll() {
        self.ynSearchTextfieldView.ynSearchTextField.endEditing(true)
    }
    
    
    func ynSearchHistoryButtonClicked(text: String) {
        print("pull profile down")
        let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instagramProfileScraper?profile=\(text)&n=15")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            if let data = data {
                do {
                        // Convert the data to JSON
                        let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                        if let json = jsonSerialized {
                            self.username = text
                            self.performSegue(withIdentifier: "usernameChosenSegue", sender: self)
                        }
                    }
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func ynCategoryButtonClicked(text: String) {
        self.pushViewController(text: text)
        print(text)
    }
    
    func ynSearchListViewClicked(key: String) {
        self.pushViewController(text: key)
        print(key)
    }
    
    func ynSearchListViewClicked(object: Any) {
        print(object)
    }
    
    func ynSearchListView(_ ynSearchListView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.ynSearchView.ynSearchListView.dequeueReusableCell(withIdentifier: YNSearchListViewCell.ID) as! YNSearchListViewCell
        if let ynmodel = self.ynSearchView.ynSearchListView.searchResultDatabase[indexPath.row] as? String {
            cell.searchLabel.text = ynmodel
        }
        
        return cell
    }
    
    func ynSearchListView(_ ynSearchListView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedUsername = self.ynSearchView.ynSearchListView.searchResultDatabase[indexPath.row] as? String {
            self.ynSearchView.ynSearchListView.ynSearchListViewDelegate?.ynSearchListViewClicked(key: selectedUsername)
            self.ynSearchView.ynSearchListView.ynSearchListViewDelegate?.ynSearchListViewClicked(object: self.ynSearchView.ynSearchListView.database[indexPath.row])
            self.ynSearchView.ynSearchListView.ynSearch.appendSearchHistories(value: selectedUsername)
            self.username = selectedUsername
            self.performSegue(withIdentifier: "usernameChosenSegue", sender: self)
        }
    }
    
    func pushViewController(text:String) {
        print("hi")
        /* let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "detail") as! DetailViewController
        vc.clickedText = text
        
        self.present(vc, animated: true, completion: nil) */
    }

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("prepare for segue")
        if(segue.identifier == "usernameChosenSegue") {
            print("usernameChosenSegue")
            if let nextViewController = segue.destination as? InstagramGalleryViewController {
                print("is igvc")
                // nextViewController.username = self.username
                if (self.username != "") {
                    print("send username")
                    nextViewController.getInstagramMemoriesFromUsername(username: self.username)
                }
            }
        }
    }
    
    func getAutocompleteSuggestions(username: String) {
        let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instagramHandleScraper?handle=\(username)&n=5")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                    var usernames : [String] = []
                    if let json = jsonSerialized {
                        for item in json {
                            print(item)
                            let user = item["user"] as! NSDictionary
                            let url = user["profile_pic_url"] as! String
                            let isPrivate = user["is_private"] as! Bool
                            let handle = user["username"] as! String
                            usernames.append(handle)
                            print(handle)
                            if(url != nil) {
                                if let data = try? Data(contentsOf: URL(string: url)!) {
                                    if (data != nil) {
                                        print("data blah")
                                    }
                                }
                            }
                        }
                        //self.ynSearch.setSearchHistories(value: usernames)
                        self.initData(database: usernames)
                        print(usernames)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
        task.resume()
    }
    
    override func ynSearchTextfieldTextChanged(_ textField: UITextField) {
        print("changed textfield")
        getAutocompleteSuggestions(username: textField.text!)
    }
}
