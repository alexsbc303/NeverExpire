//
//  FirstViewController
//  Never Expire
//
//  Created by Bair Givan Lau on 24/10/2017.
//  Copyright © 2017年 Group 1. All rights reserved.
//

import Foundation
import UIKit

class LeftMenuViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.frame = CGRect(x: 20, y: (self.view.frame.size.height - 54 * 5) / 2.0, width: self.view.frame.size.width, height: 54 * 5)
        tableView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isOpaque = false
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.bounces = false
        return tableView
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}


// MARK : TableViewDataSource & Delegate Methods

extension LeftMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
   
        let titles: [String] = ["Home", "Online", "Settings", "", ""]
        
        let images: [String] = ["IconHome", "IconProfile", "IconSettings", "", ""]
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text  = titles[indexPath.row]
        cell.selectionStyle = .none
        cell.imageView?.image = UIImage(named: images[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var destinationVC : String
        
        switch indexPath.row {
        case 0:
            destinationVC = "SecondViewController"
            break
        case 1:
            destinationVC = "FirstViewController"
            break
        case 2:
            destinationVC = "SettingViewController"
            break
        default:
            destinationVC = "SecondViewController"
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        var destinationViewController = mainStoryboard.instantiateViewController(withIdentifier: destinationVC)
        if let navController = destinationViewController as? UINavigationController {
            destinationViewController = navController.visibleViewController!
        }
        sideMenuViewController?.contentViewController = UINavigationController(rootViewController: destinationViewController )
        sideMenuViewController?.hideMenuViewController()
    }
    
}
    
