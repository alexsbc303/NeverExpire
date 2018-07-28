//
//  SettingViewController.swift
//  Never Expire
//
//  Created by Bair Givan Lau on 22/11/2017.
//  Copyright © 2017年 Group 1. All rights reserved.
//

import UIKit
import FirebaseDatabase

class SettingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var code: UILabel!
    @IBOutlet var shareBtn: UIButton!
    @IBOutlet var changeBtn: UIButton!
    @IBOutlet var codeTextField: UITextField!
    @IBOutlet var codeTextView: UITextView!
    
    let defaults:UserDefaults = UserDefaults.standard
    var accessCode = ""
    var ref: DatabaseReference!
    var childref: DatabaseReference!
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        return false; //do not show keyboard nor cursor

    }
    
    func respondsToTf()  {
        
        //
        print("you can pop-up the data picker here")
    }

    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if codeTextField.isFirstResponder {
            DispatchQueue.main.async(execute: {
                (sender as? UIMenuController)?.setMenuVisible(false, animated: false)
            })
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    @IBAction func share(_ sender: Any) {
        accessCode = defaults.string(forKey: "AccessCode")!
        let string = "Let's manage our food together! Here's my fridge code : \(accessCode)"
        let activityVC = UIActivityViewController(activityItems: [string], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func change(_ sender: Any) {
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurVisualEffectView = UIVisualEffectView(effect: blurEffect)
        blurVisualEffectView.frame = view.bounds
        blurVisualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let alert = UIAlertController(title: "Fridge Access Code", message: "Enter an access code of existing fridge.", preferredStyle: UIAlertControllerStyle.alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: {(action: UIAlertAction!) in
            guard let textField = alert.textFields?.first, let text = textField.text else { return }
            self.accessCode = text
            self.defaults.set(self.accessCode, forKey: "AccessCode")
            self.childref = self.ref.child(self.accessCode)
            self.code.text = "Access Code: \(self.accessCode)"
            self.codeTextView.text = self.code.text
            blurVisualEffectView.removeFromSuperview()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action: UIAlertAction!) in
            blurVisualEffectView.removeFromSuperview()
        })
        
        
        
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .default
            textField.placeholder = "Enter access code"
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                
                if textField.text!.characters.count > 0 {
                    
                    self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        if snapshot.hasChild(textField.text!) {
                            confirmAction.isEnabled = true
                            print("true rooms exist")
                        } else {
                            confirmAction.isEnabled = false
                            print("false room doesn't exist")
                        }
                    })
                }
            }
        })
        
        confirmAction.isEnabled = false
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        view.addSubview(blurVisualEffectView)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeTextField.delegate = self
        codeTextField.backgroundColor = .clear
        codeTextField.addTarget(self, action: #selector(respondsToTf), for: .touchDown)
        
        //        codeTextField.selec
        ref = Database.database().reference()
        code.text = "Access Code: "
        
        shareBtn.setTitle("Share access code", for: UIControlState.normal)
        changeBtn.setTitle("Change access code", for: UIControlState.normal)
        
        if let accessCode = defaults.string(forKey: "AccessCode") {
            code.text = code.text! + accessCode
            codeTextField.text = "Access Code: \(accessCode)"
            codeTextView.text = "Access Code: \(accessCode)"
        }
        
        title = "Setting"
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 91/255, green: 179/255, blue: 70/255, alpha: 1.0)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(SSASideMenu.presentLeftMenuViewController))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(SSASideMenu.presentRightMenuViewController))
        
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 2
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
