//
//  PensieveModel.swift
//  Pensieve AR
//
//  Created by Adam Moffitt on 1/20/18.
//  Copyright © 2018 Adam's Apps. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase

class PensieveModel {
    
    var storage : Storage
    var storageRef : StorageReference
    var ref: DatabaseReference!
    var instagramUsername: String?
    
    //singleton
    static var shared = PensieveModel()
    
    init() {
        ref = Database.database().reference()
        // Get a reference to the storage service using the default Firebase App
        storage = Storage.storage()
        // Create a storage reference from our storage service
        storageRef = storage.reference()
        self.initializeFirebaseStorage()
    }
    
    func initializeFirebaseStorage() {
        // Get a reference to the storage service using the default Firebase App
        storage = Storage.storage()
        // Create a storage reference from our storage service
        storageRef = storage.reference()
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
    
    func decodeFromFireBaseKey (string: String) -> (String) {
        var string1 = string.replacingOccurrences(of: "__" , with: "_")
        string1 = string1.replacingOccurrences(of: "_P", with: ".")
        string1 = string1.replacingOccurrences(of: "_D", with: "$")
        string1 = string1.replacingOccurrences(of: "_H", with: "#")
        string1 = string1.replacingOccurrences(of: "_O", with: "[")
        string1 = string1.replacingOccurrences(of: "_C", with: "]")
        string1 = string1.replacingOccurrences(of: "_S", with: "/")
        return string1
    }
    
    // TODO MOVE INSTAGRAM CALLS INTO THE MODEL SO AS NOT TO REPLICATE CALLS
}
