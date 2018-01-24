//
//  memoryGalleryViewController.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/19/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import UserNotifications
import GeoFire
import FirebaseDatabase
import ARCL
import MapKit

class MemoryGalleryViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: SceneLocationView!
    @IBOutlet var addMemoryButton: UIButton!
    
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    var SharedPensieveModel : PensieveModel? = nil
    var currentLocation : CLLocation = CLLocation()
    
    var listOftempURLs: Set = [""]
    var listOfNodes: Array = [SCNNode()]
    var instagramOn = false
    override func viewDidLoad() {
        super.viewDidLoad()
        print(100)
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView = SceneLocationView()
        let addMemoryButton1 = UIButton(frame: CGRect(x: 146, y: 300, width: 76, height: 71))
        addMemoryButton1.imageView?.image = UIImage(named: "Add")
        let text = SCNText(string: "Pensieve AR", extrusionDepth: 5)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(x: 0, y: 0, z: -5)
        node.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.02)
        node.geometry = text
        
        DispatchQueue.main.async {
            sleep(5)
            var i = 1.0
            while (i > 0) {
                i = i-0.01
                node.opacity = 0
                sleep(UInt32(0.1))
            }
        }
        
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.autoenablesDefaultLighting = true
        
        // For use when the app is open
        locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.distanceFilter = 15
            locationManager.startUpdatingLocation()
        }
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("NotificationCenter Authorization Granted!")
            }
        }
        
        self.navigationController?.navigationBar.alpha = 0.5
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.title = "Pensieve AR"
        
        SharedPensieveModel = PensieveModel.shared
        
        // Get Instagram images
        //pullYourCrapDown(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        getProfileImages()
        getInstagramMemories(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        
        
        /*
         setImage(image: UIImage(named: "Add")!, latitude: 35.6337652, longitude: -119.7095671)
         
         let southCoordinate = CLLocationCoordinate2D(latitude: 33.5232333, longitude: -121.1803068)
         let southLocation = CLLocation(coordinate: southCoordinate, altitude: 10)
         let southImage = self.resizeImage(image: UIImage(named: "Add")!, targetSize: CGSize(width: 90.0, height: 90.0))
         let southAnnotationNode = LocationAnnotationNode(location: southLocation, image: southImage)
         sceneView.addLocationNodeWithConfirmedLocation(locationNode: southAnnotationNode)
         
         let eastCoordinate = CLLocationCoordinate2D(latitude: 34.3183504, longitude: -118.1399376)
         let eastLocation = CLLocation(coordinate: eastCoordinate, altitude: 10)
         let eastImage = self.resizeImage(image: UIImage(named: "Add")!, targetSize: CGSize(width: 90.0, height: 90.0))
         let eastAnnotationNode = LocationAnnotationNode(location: eastLocation, image: eastImage)
         sceneView.addLocationNodeWithConfirmedLocation(locationNode: eastAnnotationNode)
         
         let westCoordinate = CLLocationCoordinate2D(latitude: 34.4540648, longitude: -120.4625968)
         let westLocation = CLLocation(coordinate: westCoordinate, altitude: 10)
         let westImage = self.resizeImage(image: UIImage(named: "Add")!, targetSize: CGSize(width: 90.0, height: 90.0))
         let westAnnotationNode = LocationAnnotationNode(location: westLocation, image: westImage)
         sceneView.addLocationNodeWithConfirmedLocation(locationNode: westAnnotationNode)
         */
        
        view.addSubview(sceneView)
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        print("toggle left 2")
        appDelegate.toggleLeftDrawer(sender: sender as AnyObject, animated: true)
    }
    
    @IBAction func instagramButtonPressed(_ sender: Any) {
        
        if (self.instagramOn) {
            let alertController = UIAlertController(title: "Instagram Memories Disabled!", message: "",
                                                    preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            for node in self.listOfNodes {
                node.opacity = 0
            }
        } else {
            let alertController = UIAlertController(title: "Instagram Memories Enabled!",message:"",
                                                    preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            for node in self.listOfNodes {
                node.opacity = 1
            }
        }
        self.instagramOn = !self.instagramOn
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        let currentLocation = locationManager.location
        let geoFire = GeoFire(firebaseRef: SharedPensieveModel?.ref.child("memories"))
        var circleQuery = geoFire?.query(at: currentLocation, withRadius: 0.02)
        var queryHandle = circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            print("Key '\(key!)' entered the search area and is at location '\(location!)'")
            
            let tempRef = self.SharedPensieveModel?.ref.child("memories").child(key)
            tempRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                print("snapshot: \(String(describing: value))")
                let imageTempURL = value?["imageURL"] as? String ?? ""
                if ( imageTempURL != nil && imageTempURL != "") {
                    print("received url: \(imageTempURL)")
                    if (!self.listOftempURLs.contains(imageTempURL)) {
                        if let data = try? Data(contentsOf: URL(string: imageTempURL)!) {
                            if (data != nil) {
                                var image = UIImage(data: data)
                                image?.resize(toTargetSize: CGSize(width: 640, height: 640))
                                //self.setImage(image: image!, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                                image = self.orientImage(image: image!)
                                //print("IMAGE ORIENTATION: \((image?.imageOrientation)!.rawValue)")
                                let node = SCNNode()
                                node.geometry = SCNBox(width: 1, height: 1, length: 0.0000001, chamferRadius: 0)
                                let targetNode = SCNNode()
                                let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                let lookat = SCNLookAtConstraint(target: targetNode)
                                node.constraints = [lookat]
                                node.geometry?.firstMaterial?.diffuse.contents = image
                                node.position = SCNVector3(CGFloat( 2.0 - 6.0*(Float(arc4random()) / Float(UINT32_MAX)) ),
                                                           CGFloat(y_val),
                                                           CGFloat(2.0 - 6.0*(Float(arc4random()) / Float(UINT32_MAX))))
                                self.sceneView.scene.rootNode.addChildNode(node)
                                self.listOftempURLs.insert(imageTempURL)
                                
                            }
                        }
                    }
                }
            }) { (error) in
                print("ERROR: \(error.localizedDescription)")
            }
        })
        
    }
    
    func setImage(image: UIImage, latitude: Double, longitude: Double) {
        let imageCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let imageLocation = CLLocation(coordinate: imageCoordinate, altitude: 10)
        self.resizeImage(image: image, targetSize: CGSize(width: 90.0, height: 90.0))
        let annotationNode = LocationAnnotationNode(location: imageLocation, image: image)
        listOfNodes.append(annotationNode)
        annotationNode.scaleRelativeToDistance = true
        self.sceneView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        print("****ADDED PHOTO NODE****** at \(latitude), \(longitude)")
        //sceneView.run()
    }
    
    
    func orientImage(image: UIImage) -> UIImage {
        if (image.imageOrientation.rawValue == 3) { //rotate right
            return image.rotated(by: Measurement(value: 90, unit: .degrees))!
        } else if (image.imageOrientation.rawValue == 4){ // rotate left
            return image.rotated(by: Measurement(value: -90, unit: .degrees))!
        } else if (image.imageOrientation.rawValue == 2) { // upside down
            return image.rotated(by: Measurement(value: 180, unit: .degrees))!
        }
        return image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.alpha = 0.5
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.title = "Pensieve AR"
        //self.navigationController?.isNavigationBarHidden = true
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
         */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.session.run(configuration)
        sceneView.run()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneView.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoView.alpha = 0.5
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoView.alpha = 0.5
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoView.alpha = 0.5
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // If we have been deined access give the user the option to change it
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Show the popup to the user if we have been deined access
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Background Location Access Disabled",
                                                message: "In order to experience Pensieve AR we need your location",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
    
    /*
     func locationManager(_ manager: CLLocationManager,
     didUpdateLocations locations: [CLLocation]) {
     let latestLocation: CLLocation = locations[locations.count - 1]
     let latitude = String(latestLocation.coordinate.latitude)
     let longitude = String(latestLocation.coordinate.longitude)
     print("NOTIFY LOCATION CHANGED \(latitude) \(longitude)")
     //notifyUpdateLocation()
     
     //getInstagramMemories(latitude: latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude)
     }
     //}
     */
    
    func notifyMemoryFound(caption: String) {
        //print("memoryFound! should notify now")
        // Send notification that memory was found near you
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Memories found near you!"
        content.body = "Caption: \(caption)"//"Open Pensieve AR to see augmented reality memories near you."
        content.categoryIdentifier = "alert"
        content.sound = UNNotificationSound.default()
        let request = UNNotificationRequest(identifier: "memoryFound", content: content, trigger: trigger)
        self.notificationCenter.add(request, withCompletionHandler: { (error) in
            //print("notification sent")
        })
    }
    
    func notifyUpdateLocation() {
        // Send notification that memory was found near you
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "New Update Location"
        content.categoryIdentifier = "alert"
        content.sound = UNNotificationSound.default()
        let request = UNNotificationRequest(identifier: "newLocation", content: content, trigger: trigger)
        self.notificationCenter.add(request, withCompletionHandler: { (error) in
            //print("notification sent")
        })
    }
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func getInstagramMemories(latitude: Double, longitude: Double) {
        print("pull instagram down")
        let lat = String(latitude)
        let long = String(longitude)
        // let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instaImages?latitude=\(lat)&longitude=\(long)")
        let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instagramLocationScraper?latitude=\(lat)&longitude=\(long)")
        print(url ?? " ")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                    print("json serialized: \(jsonSerialized)")
                    if let json = jsonSerialized {
                        for item in json {
                            let url = item["src"] as! String
                            let isVideo = item["is_video"] as! Bool
                            let caption = item["caption"] as! String
                            print(url)
                            print(isVideo)
                            print(caption)
                            if(url != nil) {
                                if let data = try? Data(contentsOf: URL(string: url)!) {
                                    if (data != nil) {
                                        
                                        let node = SCNNode()
                                        self.listOfNodes.append(node)
                                        node.geometry = SCNBox(width: 1, height: 1, length: 0.0000001, chamferRadius: 0)
                                        let targetNode = SCNNode()
                                        let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                        targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                        let lookat = SCNLookAtConstraint(target: targetNode)
                                        node.constraints = [lookat]
                                        if (isVideo){
                                            let videoURL = URL(string: url)
                                            let player = AVPlayer(url: videoURL!)
                                            
                                            print(700)
                                            // To make the video loop
                                            player.actionAtItemEnd = .none
                                            NotificationCenter.default.addObserver(
                                                self,
                                                selector: #selector(MemoryGalleryViewController.playerItemDidReachEnd),
                                                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                object: player.currentItem)
                                            
                                            print(800)
                                            let videoNode = SKVideoNode(avPlayer: player)
                                            let size = CGSize(width: 1024, height: 512)
                                            videoNode.size = size
                                            videoNode.position = CGPoint(x: 512, y: 256)
                                            videoNode.yScale = -1.0
                                            let spriteScene = SKScene(size: size)
                                            videoNode.play()
                                            
                                            spriteScene.addChild(videoNode)
                                            node.geometry?.firstMaterial?.diffuse.contents = spriteScene
                                        } else {
                                            let image = UIImage(data: data)
                                            node.geometry?.firstMaterial?.diffuse.contents = image
                                        }
                                        node.position = SCNVector3(CGFloat( 2.0 - 9.0*(Float(arc4random()) / Float(UINT32_MAX)) ),
                                                                   CGFloat(y_val),
                                                                   CGFloat(2.0 - 9.0*(Float(arc4random()) / Float(UINT32_MAX))))
                                        if (self.instagramOn) {
                                            node.opacity = 1
                                        } else {
                                            node.opacity = 0
                                        }
                                        self.sceneView.scene.rootNode.addChildNode(node)
                                    }
                                }
                            }
                        }
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
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
        }
    }
    
    func getProfileImages() {
        print("pull profile down")
        let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instagramProfileScraper?profile=admoffitt15&n=15")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                    print("json serialized: \(jsonSerialized)")
                    if let json = jsonSerialized {
                        for item in json {
                            let url = item["src"] as! String
                            let isVideo = item["is_video"] as! Bool
                            let caption = item["caption"] as! String
                            print(url)
                            print(isVideo)
                            print(caption)
                            if(url != nil) {
                                if let data = try? Data(contentsOf: URL(string: url)!) {
                                    if (data != nil) {
                                        
                                        let node = SCNNode()
                                        self.listOfNodes.append(node)
                                        node.geometry = SCNBox(width: 1, height: 1, length: 0.0000001, chamferRadius: 0)
                                        let targetNode = SCNNode()
                                        let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                        targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                        let lookat = SCNLookAtConstraint(target: targetNode)
                                        node.constraints = [lookat]
                                        if (isVideo){
                                            let videoURL = URL(string: url)
                                            let player = AVPlayer(url: videoURL!)
                                            
                                            print(700)
                                            // To make the video loop
                                            player.actionAtItemEnd = .none
                                            NotificationCenter.default.addObserver(
                                                self,
                                                selector: #selector(MemoryGalleryViewController.playerItemDidReachEnd),
                                                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                object: player.currentItem)
                                            
                                            print(800)
                                            let videoNode = SKVideoNode(avPlayer: player)
                                            let size = CGSize(width: 1024, height: 512)
                                            videoNode.size = size
                                            videoNode.position = CGPoint(x: 512, y: 256)
                                            videoNode.yScale = -1.0
                                            let spriteScene = SKScene(size: size)
                                            videoNode.play()
                                            
                                            spriteScene.addChild(videoNode)
                                            node.geometry?.firstMaterial?.diffuse.contents = spriteScene
                                        } else {
                                            let image = UIImage(data: data)
                                            node.geometry?.firstMaterial?.diffuse.contents = image
                                        }
                                        node.position = SCNVector3(CGFloat( 2.0 - 9.0*(Float(arc4random()) / Float(UINT32_MAX)) ),
                                                                   CGFloat(y_val),
                                                                   CGFloat(2.0 - 9.0*(Float(arc4random()) / Float(UINT32_MAX))))
                                        if (self.instagramOn) {
                                            node.opacity = 1
                                        } else {
                                            node.opacity = 0
                                        }
                                        self.sceneView.scene.rootNode.addChildNode(node)
                                    }
                                }
                            }
                        }
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
    
    func pullYourCrapDown(latitude: Double, longitude: Double) {
        print("pull christie's crap down")
        let lat = String(latitude)
        let long = String(longitude)
        let url = URL(string: "https://us-central1-pensieve-ar.cloudfunctions.net/instaImages?latitude=\(lat)&longitude=\(long)")
        print(url)
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String]
                    
                    if let json = jsonSerialized {
                        for imageUrl in json {
                            print(imageUrl)
                            if(imageUrl != nil) {
                                if let data = try? Data(contentsOf: URL(string: imageUrl)!) {
                                    if (data != nil) {
                                        let image = UIImage(data: data)
                                        image?.resize(toTargetSize: CGSize(width: 640, height: 640))
                                        let node = SCNNode()
                                        node.geometry = SCNBox(width: 1, height: 1, length: 0.0000001, chamferRadius: 0)
                                        let targetNode = SCNNode()
                                        let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                        targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                        let lookat = SCNLookAtConstraint(target: targetNode)
                                        node.constraints = [lookat]
                                        node.geometry?.firstMaterial?.diffuse.contents = image
                                        node.position = SCNVector3(CGFloat( 5.0 - 10.0*(Float(arc4random()) / Float(UINT32_MAX)) ),
                                                                   CGFloat(y_val),
                                                                   CGFloat(5.0 - 10.0*(Float(arc4random()) / Float(UINT32_MAX))))
                                        self.sceneView.scene.rootNode.addChildNode(node)
                                    }
                                }
                            }
                        }
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
}

extension UIImage {
    
    func resize(toTargetSize targetSize: CGSize) -> UIImage {
        // inspired by Hamptin Catlin
        // https://gist.github.com/licvido/55d12a8eb76a8103c753
        
        let newScale = self.scale // change this if you want the output image to have a different scale
        let originalSize = self.size
        
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(originalSize.width * heightRatio), height: floor(originalSize.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(originalSize.width * widthRatio), height: floor(originalSize.height * widthRatio))
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        let format = UIGraphicsImageRendererFormat()
        format.scale = newScale
        format.opaque = true
        let newImage = UIGraphicsImageRenderer(bounds: rect, format: format).image() { _ in
            self.draw(in: rect)
        }
        
        return newImage
    }
}

extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int
        
        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }
    
    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)
            
            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))
            
            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}


