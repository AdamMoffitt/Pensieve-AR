//
//  PersonalGalleryViewController.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/22/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import UserNotifications
import FirebaseDatabase
import ARCL

class PersonalGalleryViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UNUserNotificationCenterDelegate  {

    @IBOutlet weak var sceneView: SceneLocationView!
    
    // Used to start getting the users location
    let notificationCenter = UNUserNotificationCenter.current()
    var SharedPensieveModel : PensieveModel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView = SceneLocationView()
        sceneView.autoenablesDefaultLighting = true
        
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
        getProfileImages()
        view.addSubview(sceneView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.alpha = 0.5
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.title = "Personal Gallery AR"
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
    
    // MARK: - ARSessionObserver
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        resetTracking()
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func LeftDrawerButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.toggleLeftDrawer(sender: sender as AnyObject, animated: true)
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
                            if(url != nil) {
                                if let data = try? Data(contentsOf: URL(string: url)!) {
                                    if (data != nil) {
                                        
                                        let node = SCNNode()
                                        node.geometry = SCNBox(width: 1, height: 1, length: 0.0000001, chamferRadius: 0)
                                        let targetNode = SCNNode()
                                        let y_val = 0.5*Float(arc4random()) / Float(UINT32_MAX)
                                        targetNode.position = SCNVector3(CGFloat(0), CGFloat(y_val), CGFloat(0))
                                        let lookat = SCNLookAtConstraint(target: targetNode)
                                        node.constraints = [lookat]
                                        if (isVideo){
                                            let videoURL = URL(string: url)
                                            let player = AVPlayer(url: videoURL!)
                                            
                                            // To make the video loop
                                            player.actionAtItemEnd = .none
                                            NotificationCenter.default.addObserver(
                                                self,
                                                selector: #selector(MemoryGalleryViewController.playerItemDidReachEnd),
                                                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                object: player.currentItem)
                                            
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
