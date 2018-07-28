//
//  FirstViewController.swift
//  Never Expire
//
//  Created by Bair Givan Lau on 24/10/2017.
//  Copyright © 2017年 Group 1. All rights reserved.
//

import UIKit
import SwipeCellKit
import FirebaseDatabase

class FirstViewController: UITableViewController {

    @IBOutlet var foodTableView: UITableView!
    
    var items: [FoodItem] = []
    
    var defaultOptions = SwipeTableOptions()
    var isSwipeRightEnabled = true
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        let childref = ref.child("public")

        childref.observe(.value, with: { snapshot in
            var newItems: [FoodItem] = []
            for item in snapshot.children {
                print(childref.child("-KzXqGxggVOnpXpqcVLn"))
                let foodItem = FoodItem(snapshot: item as! DataSnapshot)
                newItems.append(foodItem)
            }
            newItems.sort(by: {$0.expiryDate < $1.expiryDate})
            self.items = newItems
            self.foodTableView.reloadData()
        })
        
        //foodTableView.tableFooterView = UIView()
        
        //scanButton.layer.cornerRadius = 10
        //scanButton.layer.borderWidth = 10
        //scanButton.layer.borderColor = UIColor.green.cgColor
        
        title = "Online Fridge"
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 91/255, green: 179/255, blue: 70/255, alpha: 1.0)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(SSASideMenu.presentLeftMenuViewController))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(SSASideMenu.presentRightMenuViewController))
        
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 2
        
        foodTableView.allowsSelection = true
        foodTableView.allowsMultipleSelectionDuringEditing = true
        
        foodTableView.rowHeight = UITableViewAutomaticDimension
        foodTableView.estimatedRowHeight = 100
        
        view.layoutMargins.left = 32
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let customView = UIView()
        let button = UIButton()
        
        customView.addSubview(button)
        customView.backgroundColor = .clear
        button.frame = CGRect(x: 0, y: self.view.frame.size.height - 50, width: self.view.frame.size.width, height: 50)
        button.backgroundColor = UIColor(red: 91/255, green: 179/255, blue: 70/255, alpha: 1.0)
        
        button.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50)
        button.leadingAnchor.constraint(equalTo: customView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: customView.trailingAnchor).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.setTitle("Scan", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        return customView
    }
    
    func buttonAction(sender: UIButton) {
        let qrScannerController = self.storyboard?.instantiateViewController(withIdentifier: "QRScannerController") as! QRScannerController
        qrScannerController.accessCode = "public"
        self.present(qrScannerController, animated:true, completion:nil)
        print("Button tapped")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell") as! FoodCell
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
            let image = UIImage(data: data! as Data)
            
            // Bounce back to the main thread to update the UI
            DispatchQueue.main.async {
                // Main thread stuff.
                cell.imageView?.image = image
                cell.imageView?.frame = CGRect(x: 0, y:10, width:(cell.imageView?.frame.size.width)!/2, height:(cell.imageView?.frame.size.height)!/2)
                cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)!/2
                cell.imageView?.layer.masksToBounds = true
                cell.imageView?.trailingAnchor.constraint(equalTo: cell.stackView.leadingAnchor).isActive = true
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

extension FirstViewController: SwipeTableViewCellDelegate {
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
                let cell = tableView.cellForRow(at: indexPath) as! FoodCell
                cell.setStatus2()
            }
            flag.hidesWhenSelected = true

            configure(action: flag, with: .flag)

            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                let foodItem = self.items[indexPath.row]
                self.items.remove(at: indexPath.row)
                foodItem.ref?.removeValue()
            }
            configure(action: delete, with: .trash)

            let cell = tableView.cellForRow(at: indexPath) as! FoodCell
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailTableViewController") as! DetailTableViewController
        let food = self.items[indexPath.row]
        detailTableViewController.barcode = food.barcode
        detailTableViewController.category = food.category
        detailTableViewController.expiryDate = food.expiryDate
        detailTableViewController.foodDescription = food.description
        detailTableViewController.location = food.location
        detailTableViewController.name = food.name
        navigationController?.pushViewController(detailTableViewController, animated: true)
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

class FoodCell: SwipeTableViewCell {
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var stackView: UIStackView!
//    var animator: Any?
//
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
//
//    func setupIndicatorView() {
//        indicatorView.translatesAutoresizingMaskIntoConstraints = false
//        indicatorView.color = tintColor
//        indicatorView.backgroundColor = .clear
//        contentView.addSubview(indicatorView)
//
//        let size: CGFloat = 12
//        indicatorView.widthAnchor.constraint(equalToConstant: size).isActive = true
//        indicatorView.heightAnchor.constraint(equalTo: indicatorView.widthAnchor).isActive = true
//        indicatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12).isActive = true
//        indicatorView.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor).isActive = true
//    }
//
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

class IndicatorView: UIView {
    var color = UIColor.clear {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        color.set()
        UIBezierPath(ovalIn: rect).fill()
    }
}

class Email {
    let from: String
    let subject: String
    let body: String
    let date: Date
    var unread = false
    
    init(from: String, subject: String, body: String, date: Date) {
        self.from = from
        self.subject = subject
        self.body = body
        self.date = date
    }
    
    var relativeDateString: String {
        if Calendar.current.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: date)
        }
    }
}

extension Calendar {
    static func now(addingDays days: Int) -> Date {
        return Date().addingTimeInterval(Double(days) * 60 * 60 * 24)
    }
}

enum ActionDescriptor {
    case read, unread, more, flag, trash
    
    func title(forDisplayMode displayMode: ButtonDisplayMode) -> String? {
        guard displayMode != .imageOnly else { return nil }
        
        switch self {
        case .read: return "Share"
        case .unread: return "Unshare"
        case .more: return "Opened"
        case .flag: return "Consumed"
        case .trash: return "Delete"
        }
    }
    
    func image(forStyle style: ButtonStyle, displayMode: ButtonDisplayMode) -> UIImage? {
        guard displayMode != .titleOnly else { return nil }
        
        let name: String
        switch self {
        case .read: name = "Read"
        case .unread: name = "Unread"
        case .more: name = "More"
        case .flag: name = "Flag"
        case .trash: name = "Trash"
        }
        
        return UIImage(named: style == .backgroundColor ? name : name + "-circle")
    }
    
    var color: UIColor {
        switch self {
        case .read, .unread: return #colorLiteral(red: 0, green: 0.4577052593, blue: 1, alpha: 1)
        case .more: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        case .flag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        }
    }
}

enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

enum ButtonStyle {
    case backgroundColor, circular
}


