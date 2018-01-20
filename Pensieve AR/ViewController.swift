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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    var SharedPensieveModel : PensieveModel? = nil
    var currentLocation : CLLocation = CLLocation()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        let text = SCNText(string: "Pensieve AR", extrusionDepth: 4)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(x: 0, y: 0.02, z: -1)
        node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        node.geometry = text
        
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.autoenablesDefaultLighting = true
        
        // For use when the app is open
        locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.distanceFilter = 100
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
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
    
    func ScheduleNotification(_ sender: Any) {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests() // deletes pending scheduled notifications, there is a schedule limit qty
        
        let content = UNMutableNotificationContent()
        content.title = "Memory nearby!"
        content.body = "Open Pensieve AR to see memories around you"
        content.categoryIdentifier = "alert"
        content.sound = UNNotificationSound.default()
        
        // Ex. Trigger within a timeInterval
        // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Ex. Trigger within a Location
        let centerLoc = CLLocationCoordinate2D(latitude: 37.32975796, longitude: -122.01989151)
        let region = CLCircularRegion(center: centerLoc, radius: 100.0, identifier: UUID().uuidString) // radius in meters
        region.notifyOnEntry = true
        region.notifyOnExit = true
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        let latitude = String(latestLocation.coordinate.latitude)
        let longitude = String(latestLocation.coordinate.longitude)
        print("\(latitude) \(longitude)")
        
        
        // let distanceTravelled = latestLocation.distance(from: currentLocation)
        // if (distanceTravelled.magnitude > 100 ) {
            currentLocation = latestLocation
            let geoFire = GeoFire(firebaseRef: SharedPensieveModel?.ref.child("memories"))
            // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
            var circleQuery = geoFire?.query(at: latestLocation, withRadius: 0.1)
            var notificationSent = false
            var queryHandle = circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
                print("Key '\(key)' entered the search area and is at location '\(location)'")
                if (!notificationSent) {
                    notificationSent = true
                    print("memoryFound! should notify now")
                    // Send notification that memory was found near you
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                    let content = UNMutableNotificationContent()
                    content.title = "Memories found near you!"
                    content.body = "Open Pensieve AR to see augmented reality memories near you."
                    content.categoryIdentifier = "alert"
                    content.sound = UNNotificationSound.default()
                    let request = UNNotificationRequest(identifier: "memoryFound", content: content, trigger: trigger)
                    self.notificationCenter.add(request, withCompletionHandler: { (error) in
                        print("notification sent")
                    })
                }
                
            })
        }
    //}
}

