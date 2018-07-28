//
//  FoodItem.swift
//  Never Expire
//
//  Created by Bair Givan Lau on 20/11/2017.
//  Copyright © 2017年 Group 1. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FoodItem {
    let key: String
    let barcode: String
    let name: String
    let expiryDate: String
    let category: String
    let description: String
    let location: String
    var consumed: Bool
    let imageURL: String
    let ref: DatabaseReference!
    
    init(barcode: String, name: String, expiryDate: String, category: String, description: String, location: String, consumed: Bool, imageURL: String, key: String = "") {
        self.key = key
        self.barcode = barcode
        self.name = name
        self.expiryDate = expiryDate
        self.category = category
        self.description = description
        self.location = location
        self.consumed = consumed
        self.imageURL = imageURL
        self.ref = nil
    }
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        print(key)
        print(snapshotValue)
        barcode = snapshotValue["barcode"] as! String
        name = snapshotValue["name"] as! String
        expiryDate = snapshotValue["expiryDate"] as! String
        category = snapshotValue["category"] as! String
        description = snapshotValue["description"] as! String
        location = snapshotValue["location"] as! String
        consumed = snapshotValue["consumed"] as! Bool
        imageURL = snapshotValue["imageURL"] as! String
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "barcode": barcode,
            "name": name,
            "expiryDate": expiryDate,
            "category": category,
            "description": description,
            "location": location,
            "consumed": consumed,
            "imageURL": imageURL
        ]
    }
}
