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
}
