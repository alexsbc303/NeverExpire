//
//  AddInfoController.swift
//  NeverExpire
//
//  Created by Alex Sin on 2017/10/24.
//  Copyright © 2017年 AppCoda. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import Firebase
import UserNotifications

class AddInfoController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let CategoryItems: [String] = ["Food", "Drink", "Task", "Others"]
    var category = ""
    var barcodeText: String!
    var accessCode: String!
    var descriptionString: String! = ""
    var storage: Storage!
    var imageURL: String!
    var image: Data!
    
    let picker = UIImagePickerController()
    
    //Category
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CategoryItems.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return CategoryItems[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        category = CategoryItems[row].lowercased()
    }
    
    //var mainVC:QRCodeViewController!
    var date:String!
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var Barcode: UILabel!
    @IBOutlet var Name: UITextField!
    @IBOutlet var ExpiryDate: UIDatePicker!
    @IBOutlet var Description: UITextField!
    @IBOutlet var Location: UITextField!
    @IBOutlet var imageButton: UIButton!
    @IBOutlet var descriptionLabel: UILabel!
    
    var ref: DatabaseReference!
    
    @IBAction func DataEntry(_ sender: Any) {
        
        let date:Date = ExpiryDate.date
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let stringDate = formatter.string(from: date)
   
        guard let name = Name.text else {return}
        
        if name.characters.count > 0 {
//            let storageRef = Storage.storage().reference().child(imageURL)
//            if let uploadData = UIImagePNGRepresentation(self.image!) {
//                print(uploadData)
//                let uploadTask = storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
//                    guard let metadata = metadata else {
//                        // Uh-oh, an error occurred!
//                        return
//                    }
//                    // Metadata contains file metadata such as size, content-type, and download URL.
//                    let downloadURL = metadata.downloadURL
//                }
//            }
            
            storage = Storage.storage()
            let foodItemRef = self.ref.child(self.accessCode).childByAutoId()
            imageURL = foodItemRef.key + ".jpeg"
            let storageRef = storage.reference().child(imageURL)
            storageRef.putData(image as Data).observe(.success) { (snapshot) in
                // When the image has successfully uploaded, we get it's download URL
                let downloadURL = snapshot.metadata?.downloadURL()?.absoluteString
                // Write the download URL to the Realtime Database
                let foodItem = FoodItem(barcode: self.barcodeText,
                                        name: name,
                                        expiryDate: stringDate,
                                        category: self.category,
                                        description: self.Description.text!,
                                        location: self.Location.text!,
                                        consumed: false,
                                        imageURL: downloadURL!)
//                print(downloadURL)
//                print(self.accessCode)
                let foodItemRef = self.ref.child(self.accessCode).childByAutoId()
                foodItemRef.setValue(foodItem.toAnyObject())
            }
            createNotification(date: date, day: 3)
            createNotification(date: date, day: 2)
            createNotification(date: date, day: 1)
            //createNotification(date: date, day: -1)
            dismiss(animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Information Required", message: "Please enter the food name.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction!) in }))
            present(alert, animated: true, completion: nil)
        }
        //        //Product Name
        //        let NameObject = UserDefaults.standard.object(forKey: "name")
        //        var name:[String]
        //        if let tempName = NameObject as? [String] {
        //            name = tempName
        //            name.append(Name.text!)
        //            print(name)
        //        }
        //        else {
        //            name = [Name.text!]
        //        }
        //        UserDefaults.standard.set(name, forKey: "name")
        //
        //        //Expiry Date
        //        let date:Date = ExpiryDate.date
        //        let formatter:DateFormatter = DateFormatter()
        //        formatter.dateFormat = "dd-MM-yyyy"
        //        let stringDate = formatter.string(from: date)
        //        self.date = stringDate
        //
        //        let DateObject = UserDefaults.standard.object(forKey: "date")
        //        var Entrydate:[String]
        //        if let tempDate = DateObject as? [String] {
        //            Entrydate = tempDate
        //            Entrydate.append(stringDate)
        //            print(Entrydate)
        //
        //        }
        //        else {
        //            Entrydate = [stringDate]
        //        }
        //        UserDefaults.standard.set(Entrydate, forKey: "date")
        //        performSegue(withIdentifier: "toMainEnteredData", sender: self)
        //        //self.dismiss(animated: true, completion: nil)
        
        
    }
    
    func createNotification(date: Date, day: Int) {
        
        let content = UNMutableNotificationContent()
        if day == -1 {
            content.title = "Don't waste food"
            content.body = Name.text! + " expired."
        } else {
            content.title = "Don't forget"
            content.body = Name.text! + " will expire in \(day) days."
        }
        content.sound = UNNotificationSound.default()
        var dayComp = DateComponents()
        dayComp.day = -day
        let newDate = Calendar.current.date(byAdding: dayComp, to: date)
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: newDate!)
//        triggerDate.day = -day
        print(triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                    repeats: false)
        let identifier = "UYLLocalNotification"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)// Something went wrong
            }
        })
        let snoozeAction = UNNotificationAction(identifier: "Snooze",
                                                title: "Snooze", options: [])
        let deleteAction = UNNotificationAction(identifier: "UYLDeleteAction",
                                                title: "Delete", options: [.destructive])
        let category = UNNotificationCategory(identifier: "UYLReminderCategory",
                                              actions: [snoozeAction,deleteAction],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        content.categoryIdentifier = "UYLReminderCategory"

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.accessCode)
        ref = Database.database().reference()
        //accessCode = "public"
        if accessCode == "public" {
            descriptionLabel.text = "Description/Contact:"
        }
        
        let text = self.barcodeText!
//        let defaults:UserDefaults = UserDefaults.standard
//        self.accessCode = defaults.string(forKey: "AccessCode")
        
        if text.characters.count > 0 {
            var link: String = "https://api.upcitemdb.com/prod/trial/lookup?upc="
            link = link + text
            guard let url = URL(string: link) else {
                return
            }
            
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, error) in
                
                if let response = response {
                    //print(response)
                }
                
                if let data = data {
                    //print(data)
                    
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                            print("Could not convert JSON to dictionary")
                            return
                        }
                        //print(json)
                        
                        if (json["total"] as? Int)! > 0 {
                            
                            if let items = json["items"] as? NSArray{
                                
                                let attributes = ["ean", "title", "description"]
                                
                                if items.count == 0 {
                                    return
                                }
                                
                                guard let item = items[0] as? [String: AnyObject] else {
                                    return
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    for attribute in attributes {
                                        if let name = item[attribute] as? String{
                                            print(attribute, name)
                                            switch attribute {
                                            case "ean":
                                                self.Barcode.text = name
                                            case "title":
                                                self.Name.text = name
                                            case "description":
                                                self.Description.text = name
                                            default:
                                                break
                                            }
                                        }
                                    }
                                    
                                    if let array = item["images"] as? NSArray{
                                        
                                        if array.count != 0 {
                                            guard let url = URL(string: (array[0] as? String)!) else {
                                                return
                                            }
                                            self.imageURL = array[0] as! String
                                            print(url)
                                            
                                            if let data = NSData(contentsOf: url) {
                                                self.image = data as Data!
                                                self.imageButton.setImage(UIImage(data: data as Data), for: UIControlState.normal)
                                                self.imageButton.imageView?.contentMode = .scaleAspectFit
                                                self.imageButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
                                            }
                                        } else {
                                            self.imageButton.setImage(UIImage(named: "addCamera"), for: UIControlState.normal)
                                            
                                        }
                                    }
                                }
                            }
                        } else {
                            print(error)
                        }
                    } catch {
                        print(error)
                    }
                }
                }.resume()
        } else {
            self.Barcode.text = ""
        }
        
        category = CategoryItems[0]
        
        picker.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
        image = UIImageJPEGRepresentation(chosenImage, 0.9)
        imageButton.imageView?.contentMode = .scaleAspectFit
        imageButton.setImage(chosenImage, for: UIControlState.normal)
        self.imageButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shootPhoto(_ sender: Any) {
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    
    func setupUI() -> Void {
        if let text = self.barcodeText{
            self.Barcode.text = text
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        super.prepare(for: segue, sender: sender)
    //        if let mainVC = segue.destination as? QRCodeViewController {
    //            let product = Product(name: self.Name.text!, date: self.date)
    //            AppData.instance.productList.append(product)
    //            mainVC.productList.append(product)
    //
    //        }
    //    }
}
