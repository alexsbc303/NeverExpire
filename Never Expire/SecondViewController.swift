//
//  SecondViewController.swift
//  Never Expire
//
//  Created by Bair Givan Lau on 24/10/2017.
//  Copyright © 2017年 Group 1. All rights reserved.
//

import UIKit
import SwipeCellKit
import FirebaseDatabase
import UserNotifications

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let defaults:UserDefaults = UserDefaults.standard
    var accessCode = ""
    var ref: DatabaseReference!
    var childref: DatabaseReference!
    var items: [FoodItem] = []
    
    @IBOutlet var foodTableView: UITableView!
    
    var defaultOptions = SwipeTableOptions()
    var isSwipeRightEnabled = true
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurVisualEffectView = UIVisualEffectView(effect: blurEffect)
        blurVisualEffectView.frame = view.bounds
        blurVisualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let code = defaults.string(forKey: "AccessCode") {
            accessCode = code
            childref = ref.child(accessCode)
            
            childref.observe(.value, with: { snapshot in
                var newItems: [FoodItem] = []
                for item in snapshot.children {
                    let foodItem = FoodItem(snapshot: item as! DataSnapshot)
                    newItems.append(foodItem)
                }
                self.items = newItems
               
                self.foodTableView.reloadData()
               
            })
            
            childref.queryOrdered(byChild: "consumed").observe(.value, with: { snapshot in
                var newItems: [FoodItem] = []
                
                for item in snapshot.children {
                    let foodItem = FoodItem(snapshot: item as! DataSnapshot)
                    newItems.append(foodItem)
                }
                
                self.items = newItems
               
                self.foodTableView.reloadData()
               
            })
            print(accessCode)
        } else {
            let alert = UIAlertController(title: "Fridge Access Code", message: "Enter an access code of existing fridge or Create one.", preferredStyle: UIAlertControllerStyle.alert)
            
            let createAction = UIAlertAction(title: "Create", style: .default, handler: {(action: UIAlertAction!) in
                guard let textField = alert.textFields?.first, let text = textField.text else { return }
                if text.characters.count <= 0 {
                    textField.text = self.randomString(length: 10)
                    self.accessCode = textField.text!
                    self.defaults.set(self.accessCode, forKey: "AccessCode")
                    print(self.accessCode)
                }
                blurVisualEffectView.removeFromSuperview()
            })
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: {(action: UIAlertAction!) in
                guard let textField = alert.textFields?.first, let text = textField.text else { return }
                self.accessCode = text
                self.defaults.set(self.accessCode, forKey: "AccessCode")
                self.childref = self.ref.child(self.accessCode)
                self.childref.observe(.value, with: { snapshot in
                    var newItems: [FoodItem] = []
                    for item in snapshot.children {
                        let foodItem = FoodItem(snapshot: item as! DataSnapshot)
                        newItems.append(foodItem)
                    }
                    //newItems.sort(by: {$0.expiryDate < $1.expiryDate})
                    newItems.sort(by: {$0.consumed && !$1.consumed})
                    self.items = newItems
                    self.foodTableView.reloadData()
                })
                blurVisualEffectView.removeFromSuperview()
            })
            
            alert.addTextField(configurationHandler: { textField in
                textField.keyboardType = .default
                textField.placeholder = "Enter barcode (optional)"
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                    
                    if textField.text!.characters.count > 0 {
                        
                        self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            if snapshot.hasChild(textField.text!) {
                                createAction.isEnabled = false
                                confirmAction.isEnabled = true
                                print("true rooms exist")
                            } else {
                                createAction.isEnabled = true
                                confirmAction.isEnabled = false
                                //self.defaults.set(text, forKey: "AccessCode")
                                print("false room doesn't exist")
                            }
                        })
                    } else {
                        createAction.isEnabled = true
                    }
                }
            })
            
            confirmAction.isEnabled = false
            alert.addAction(createAction)
            alert.addAction(confirmAction)
            view.addSubview(blurVisualEffectView)
            present(alert, animated: true, completion: nil)
        }
        //view.backgroundColor = UIColor.clear
        
        title = "Home"
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 91/255, green: 179/255, blue: 70/255, alpha: 1.0)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(SSASideMenu.presentLeftMenuViewController))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(SSASideMenu.presentRightMenuViewController))
        
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 2
        
        view.layoutMargins.left = 32
        
        let button = UIButton()
        button.frame = CGRect(x: 0, y: self.view.frame.size.height - 50, width: self.view.frame.size.width, height: 50)
        button.backgroundColor = UIColor(red: 91/255, green: 179/255, blue: 70/255, alpha: 1.0)
        button.tintColor = UIColor.white
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        button.setTitle("Scan", for: UIControlState.normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func buttonAction(sender: UIButton) {
        let qrScannerController = self.storyboard?.instantiateViewController(withIdentifier: "QRScannerController") as! QRScannerController
        qrScannerController.accessCode = self.accessCode
        self.present(qrScannerController, animated:true, completion:nil)
        print("Button tapped")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCellSecond") as! FoodCellSecond
        cell.delegate = self
        
        cell.selectedBackgroundView = createSelectedBackgroundView()
        
        let food = items[indexPath.row]
        
        cell.fromLabel.text = food.name
        cell.dateLabel.text = food.expiryDate
        cell.subjectLabel.text = food.category
        cell.bodyLabel.text = food.barcode
        
        let date = Date()
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let stringDate = formatter.string(from: date)
        if cell.dateLabel.text! < stringDate {
            cell.statusLabel.text = "Expired"
            cell.statusLabel.textColor = UIColor.red
            cell.fromLabel.textColor = UIColor.red
            cell.dateLabel.textColor = UIColor.red
            cell.subjectLabel.textColor = UIColor.red
            cell.bodyLabel.textColor = UIColor.red
        }
        
        toggleCell(cell, isCompleted: food.consumed)
        
        if food.consumed {
            cell.statusLabel.text = "Consumed"
            cell.fromLabel.textColor = UIColor.gray
            cell.dateLabel.textColor = UIColor.gray
            cell.subjectLabel.textColor = UIColor.gray
            cell.bodyLabel.textColor = UIColor.gray
        } else {
            cell.statusLabel.text = ""
            cell.fromLabel.textColor = UIColor.black
            cell.dateLabel.textColor = UIColor.black
            cell.subjectLabel.textColor = UIColor.black
            cell.bodyLabel.textColor = UIColor.black
        }
        
        cell.imageView?.image = UIImage(named: "imageNotFound")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Background thread stuff.
            let url = URL(string: food.imageURL)
            let data = NSData(contentsOf: url!)
    
            // Bounce back to the main thread to update the UI
            DispatchQueue.main.async {
                // Main thread stuff.
                let image = UIImage(data: data! as Data)
                cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)!/2
                cell.imageView?.layer.masksToBounds = true
                cell.imageView?.image = image
//                cell.stackView.leadingAnchor.constraint(equalTo: (cell.imageView?.trailingAnchor)!, constant: 20).isActive = true
            }
        }

        return cell
    }
    
    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        return view
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension SecondViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let food = items[indexPath.row]
        
        if orientation == .left {
            guard isSwipeRightEnabled else { return nil }
            
            let read = SwipeAction(style: .default, title: nil) { action, indexPath in
                //                let updatedStatus = !email.unread
                //                email.unread = updatedStatus
                //
                //                let cell = tableView.cellForRow(at: indexPath) as! FoodCell
                //                cell.setUnread(updatedStatus, animated: true)
            }
            
            read.hidesWhenSelected = true
            //            read.accessibilityLabel = email.unread ? "Mark as Read" : "Mark as Unread"
            
            //            let descriptor: ActionDescriptor = email.unread ? .read : .unread
            //            configure(action: read, with: descriptor)
            
            return [read]
        } else {
            let flag = SwipeAction(style: .default, title: nil) { action , indexPath in
                let cell = tableView.cellForRow(at: indexPath) as! FoodCellSecond
                let foodItem = self.items[indexPath.row]
                self.toggleCell(cell, isCompleted: !foodItem.consumed)
                foodItem.ref?.updateChildValues(["consumed": !foodItem.consumed])
                if foodItem.consumed {
                    cell.statusLabel.text = "Consumed"
                    cell.fromLabel.textColor = UIColor.gray
                    cell.dateLabel.textColor = UIColor.gray
                    cell.subjectLabel.textColor = UIColor.gray
                    cell.bodyLabel.textColor = UIColor.gray
                } else {
                    cell.statusLabel.text = ""
                    cell.fromLabel.textColor = UIColor.black
                    cell.dateLabel.textColor = UIColor.black
                    cell.subjectLabel.textColor = UIColor.black
                    cell.bodyLabel.textColor = UIColor.black
                }
                self.foodTableView.reloadData()
            }
            flag.hidesWhenSelected = true
            
            configure(action: flag, with: .flag)
            
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                let foodItem = self.items[indexPath.row]
                self.items.remove(at: indexPath.row)
                foodItem.ref?.removeValue()
            }
            configure(action: delete, with: .trash)
            
            let cell = tableView.cellForRow(at: indexPath) as! FoodCellSecond
            //            let closure: (UIAlertAction) -> Void = { _ in cell.hideSwipe(animated: true) }
            let more = SwipeAction(style: .default, title: nil) { action, indexPath in
                /*let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                 controller.addAction(UIAlertAction(title: "Reply", style: .default, handler: closure))
                 controller.addAction(UIAlertAction(title: "Forward", style: .default, handler: closure))
                 controller.addAction(UIAlertAction(title: "Mark...", style: .default, handler: closure))
                 controller.addAction(UIAlertAction(title: "Notify Me...", style: .default, handler: closure))
                 controller.addAction(UIAlertAction(title: "Move Message...", style: .default, handler: closure))
                 controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: closure))
                 self.present(controller, animated: true, completion: nil)*/
                cell.setStatus()
            }
            
            more.hidesWhenSelected = true
            configure(action: more, with: .more)
            
            return [delete, flag, more]
        }
    }
    
    func toggleCell(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive
        options.transitionStyle = defaultOptions.transitionStyle
        
        return options
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailTableViewController") as! DetailTableViewController
        let food = self.items[indexPath.row]
        detailTableViewController.barcode = food.barcode
        detailTableViewController.category = food.category
        detailTableViewController.expiryDate = food.expiryDate
        detailTableViewController.foodDescription = food.description
        detailTableViewController.location = food.location
        detailTableViewController.name = food.name
        detailTableViewController.title = "Details"
        navigationController?.pushViewController(detailTableViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}

class FoodCellSecond: SwipeTableViewCell {
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var stackView: UIStackView!
    
    var animator: Any?
    
    //    var indicatorView = IndicatorView(frame: .zero)
    //
    //    var unread = true {
    //        didSet {
    //            indicatorView.transform = unread ? CGAffineTransform.identity : CGAffineTransform.init(scaleX: 0.001, y: 0.001)
    //        }
    //    }
    //
    //    override func awakeFromNib() {
    //        setupIndicatorView()
    //    }
    
    //    func setupIndicatorView() {
    //        indicatorView.translatesAutoresizingMaskIntoConstraints = false
    //        indicatorView.color = tintColor
    //        indicatorView.backgroundColor = .clear
    ////        contentView.addSubview(indicatorView)
    //
    //        let size: CGFloat = 12
    //        indicatorView.widthAnchor.constraint(equalToConstant: size).isActive = true
    //        indicatorView.heightAnchor.constraint(equalTo: indicatorView.widthAnchor).isActive = true
    //        indicatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12).isActive = true
    //        indicatorView.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor).isActive = true
    //    }
    
    //    func setUnread(_ unread: Bool, animated: Bool) {
    //        let closure = {
    //            self.unread = unread
    //        }
    //
    //        if #available(iOS 10, *), animated {
    //            var localAnimator = self.animator as? UIViewPropertyAnimator
    //            localAnimator?.stopAnimation(true)
    //
    //            localAnimator = unread ? UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.4) : UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0)
    //            localAnimator?.addAnimations(closure)
    //            localAnimator?.startAnimation()
    //
    //            self.animator = localAnimator
    //        } else {
    //            closure()
    //        }
    //    }
    
    func setStatus() {
        statusLabel.text = "Opened"
    }
    
    func setStatus2() {
        statusLabel.text = "Consumed"
    }
}
