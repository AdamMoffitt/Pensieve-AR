//
//  AddMemoryViewController.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/20/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import UIKit
import CoreLocation
import GeoFire
import Firebase

class AddMemoryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, UITextViewDelegate, UITextFieldDelegate {
    
     let SharedPensieveModel = PensieveModel.shared
    
    let locationManager = CLLocationManager()
    
    let imagePicker = UIImagePickerController()
    
    @IBOutlet var memoryCaptionTextView: UITextView!
    @IBOutlet var memoryImageView: UIImageView!
    @IBOutlet var addmemoryImageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addmemoryImageButton.titleLabel?.text = "Click to Add Memory Image"
        imagePicker.delegate = self
        locationManager.requestWhenInUseAuthorization()
        SharedPensieveModel.initializeFirebaseStorage()
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.startUpdatingLocation()
        }
        
        memoryCaptionTextView.delegate = self
        memoryCaptionTextView.text = "Enter caption here..."
        memoryCaptionTextView.textColor = UIColor.lightGray
        
        self.hideKeyboard()
    }
    
    @IBAction func takePhotoTapped(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            
            let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { _ in
                self.takePicture()
            }))
            
            alert.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
                self.takeVideo()
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //https://makeapppie.com/2016/06/28/how-to-use-uiimagepickercontroller-for-a-camera-and-photo-library-in-swift-3-0/
    func takePicture(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.modalPresentationStyle = .fullScreen
            present(imagePicker,animated: true,completion: nil)
        }else {
            noCamera()
        }
    }
    
    func takeVideo() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.cameraCaptureMode = .video
            imagePicker.modalPresentationStyle = .fullScreen
            present(imagePicker,animated: true,completion: nil)
        }else {
            noCamera()
        }
    }
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }

    //https://makeapppie.com/2016/06/28/how-to-use-uiimagepickercontroller-for-a-camera-and-photo-library-in-swift-3-0/
    func noCamera(){
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "Sorry, this device has no camera",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        present(
            alertVC,
            animated: true,
            completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        memoryImageView.contentMode = .scaleAspectFit
        memoryImageView
            .image = pickedImage
        addmemoryImageButton.backgroundColor = .clear
        addmemoryImageButton.titleLabel?.text = ""
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addMemoryButtonPressed(_ sender: Any) {
        let memoryID = NSUUID().uuidString
        let caption = memoryCaptionTextView.text
        let image = memoryImageView.image
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // TODO: make POST call to post memory to Firebase
        if (image != nil) {
            // post image
            if let uploadData = UIImageJPEGRepresentation(image!, 0.1) {
                let tempImageName = NSUUID().uuidString
                SharedPensieveModel.storageRef.child("images").child("\(tempImageName).png").putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print (error ?? "Error")
                        return
                    }
                    //save the firebase image url in order to download the image later
                    let tempSavedImageURL = (metadata?.downloadURL()?.absoluteString)!
                    print(tempSavedImageURL)
                    self.SharedPensieveModel.ref.child("memories").child(memoryID).child("imageURL").setValue(tempSavedImageURL)
                    
                    /*
                     // Success alert
                     let alert = SCLAlertView()
                     alert.addButton("Okay") {
                     self.navigationController?.popViewController(animated: true)
                     }
                     alert.showSuccess("Memory added!")
                    */
                })
            } else {
                print("post image didnt work")
            }
        } else {
            /*
             let alert = SCLAlertView()
             alert.addButton("Add Memory Without Caption") {
             print("Add Memory Without Caption")
             }
             alert.addButton("Add image to my post!") {
             takePicture()
             }
             alert.showInfo("Did you mean to post a caption without an image?")
             */
        }
        //SharedPensieveModel.ref.child("memories").child(memoryID).child("caption").setValue(caption)
        
        if let location = locationManager.location {
            print(location.coordinate)
            let geoFire = GeoFire(firebaseRef: SharedPensieveModel.ref.child("memories"))
            geoFire?.setLocation(CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), forKey: memoryID)
        } else {
            print("whoops")
        }
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
    
    // TextView delegate method to simulate placeholder text
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter caption here..."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    func encodeForFirebaseKey(string: String) -> (String){
        var string1 = string.replacingOccurrences(of: "_", with: "__")
        string1 = string1.replacingOccurrences(of: ".", with: "_P")
        string1 = string1.replacingOccurrences(of: "$", with: "_D")
        string1 = string1.replacingOccurrences(of: "#", with: "_H")
        string1 = string1.replacingOccurrences(of: "[", with: "_O")
        string1 = string1.replacingOccurrences(of: "]", with: "_C")
        string1 = string1.replacingOccurrences(of: "/", with: "_S")
        return string1
    }
}


extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
