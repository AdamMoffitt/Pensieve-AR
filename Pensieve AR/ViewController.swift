//
//  ViewController.swift
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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: SceneLocationView!
    @IBOutlet var addMemoryButton: UIButton!
    
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    var SharedPensieveModel : PensieveModel? = nil
    var currentLocation : CLLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        //sceneView = SceneLocationView()
        let text = SCNText(string: "Pensieve AR", extrusionDepth: 5)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(x: 0, y: 0, z: -1)
        node.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.05)
        node.geometry = text
        
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
        self.navigationController?.title = "Pensieve AR"
        
        SharedPensieveModel = PensieveModel.shared
        
        // Get Instagram images
         pullYourCrapDown(latitude: 34.4128233, longitude: -119.8480609)
        
        let currentLocation = locationManager.location
        let geoFire = GeoFire(firebaseRef: SharedPensieveModel?.ref.child("memories"))
        var circleQuery = geoFire?.query(at: currentLocation, withRadius: 0.02)
        var queryHandle = circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            //print("Key '\(key!)' entered the search area and is at location '\(location!)'")
            
            let tempRef = self.SharedPensieveModel?.ref.child("memories").child(key)
            tempRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                let imageTempURL = value?["imageURL"] as? String ?? ""
                print(imageTempURL)
                if let data = try? Data(contentsOf: URL(string: imageTempURL)!) {
                    if (data != nil) {
                        let image = self.resizeImage(image: UIImage(data: data)!, targetSize: CGSize(width: 90.0, height: 90.0))
                        let annotationNode = LocationAnnotationNode(location: location, image: image)
                        self.sceneView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        })
        
        /*
        let northCoordinate = CLLocationCoordinate2D(latitude: 35.6337652, longitude: -119.7095671)
        let northLocation = CLLocation(coordinate: northCoordinate, altitude: 10)
        let northImage = self.resizeImage(image: UIImage(named: "Add")!, targetSize: CGSize(width: 90.0, height: 90.0))
        let northAnnotationNode = LocationAnnotationNode(location: northLocation, image: northImage)
        sceneView.addLocationNodeWithConfirmedLocation(locationNode: northAnnotationNode)
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.alpha = 0.5
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
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        UIApplication.shared.isIdleTimerDisabled = true
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
    
    /* TODO!!!!!!!!!!!!!1
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        let latitude = String(latestLocation.coordinate.latitude)
        let longitude = String(latestLocation.coordinate.longitude)
        //print("\(latitude) \(longitude)")
        notifyUpdateLocation()
        
        // let distanceTravelled = latestLocation.distance(from: currentLocation)
        // if (distanceTravelled.magnitude > 100 ) {
            currentLocation = latestLocation
            let geoFire = GeoFire(firebaseRef: SharedPensieveModel?.ref.child("memories"))
            // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
            var circleQuery = geoFire?.query(at: latestLocation, withRadius: 0.01)
            var queryHandle = circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
                //print("Key '\(key!)' entered the search area and is at location '\(location!)'")
                    let tempRef = self.SharedPensieveModel?.ref.child("memories").child(key)
            })
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
                            if(imageUrl != nil) {
                                if let data = try? Data(contentsOf: URL(string: imageUrl)!) {
                                    if (data != nil) {
                                    let image = UIImage(data: data)
                                        
                                        let node = SCNNode()
                                        node.geometry = SCNBox(width: 0.0000001, height: 1, length: 1, chamferRadius: 0)
                                        let targetNode = SCNNode()
                                        let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                        targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                        let lookat = SCNLookAtConstraint(target: targetNode)
                                        node.constraints = [lookat]
                                        node.geometry?.firstMaterial?.diffuse.contents = image
                                        node.position = SCNVector3(CGFloat( 10.0 - 20.0*(Float(arc4random()) / Float(UINT32_MAX)) ),
                                                                   CGFloat(y_val),
                                                                   CGFloat(10.0 - 20.0*(Float(arc4random()) / Float(UINT32_MAX))))
                                        
                                        self.sceneView.scene.rootNode.addChildNode(node)
                                        
//                                    let instaCoordinate = CLLocationCoordinate2D(latitude: 34.4540648, longitude: -120.4625968)
//                                    let instaLocation = CLLocation(coordinate: instaCoordinate, altitude: 10)
//                                    let instaImage = self.resizeImage(image: image!, targetSize: CGSize(width: 90.0, height: 90.0))
//                                    if (instaImage != nil  && instaLocation != nil){
//                                        let instaAnnotationNode = LocationAnnotationNode(location: instaLocation, image: instaImage)
//                                    self.sceneView.addLocationNodeWithConfirmedLocation(locationNode: instaAnnotationNode)
//                                        }
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

