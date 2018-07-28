//
//  QRScannerController.swift
//  NeverExpire
//
//  Created by Alex Sin on 2017/10/23.
//  Copyright © 2017年 EE4304. All rights reserved.
//

import UIKit
import AVFoundation

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    var accessCode: String!
    //var mainVC:QRCodeViewController!
    
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                              AVMetadataObject.ObjectType.code39,
                              AVMetadataObject.ObjectType.code39Mod43,
                              AVMetadataObject.ObjectType.code93,
                              AVMetadataObject.ObjectType.code128,
                              AVMetadataObject.ObjectType.ean8,
                              AVMetadataObject.ObjectType.ean13,
                              AVMetadataObject.ObjectType.aztec,
                              AVMetadataObject.ObjectType.pdf417,
                              AVMetadataObject.ObjectType.qr]
    
    @IBAction func dismiss(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.accessCode)
        
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession = AVCaptureSession()
            
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            view.bringSubview(toFront: messageLabel)
            view.bringSubview(toFront: topbar)
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 1
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
        } catch {
            print(error)
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func manualTapped(_ sender: AnyObject) {
        self.captureSession?.stopRunning()
        
        let alert = UIAlertController(title: "Food Item", message: "Add an item", preferredStyle: UIAlertControllerStyle.alert)
        
        let addAction = UIAlertAction(title: "Add", style: .default, handler: {(action: UIAlertAction!) in
            guard let textField = alert.textFields?.first, let text = textField.text else { return }
            let pvc = self.presentingViewController
            self.dismiss(animated: true, completion: {
                let addInfoVC = self.storyboard?.instantiateViewController(withIdentifier: "AddInfoController") as! AddInfoController
                addInfoVC.barcodeText = text
                addInfoVC.accessCode = self.accessCode
                pvc?.present(addInfoVC, animated:true, completion:nil)
            })
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {(action: UIAlertAction!) in
            self.messageLabel.text = "No code is detected"
            self.qrCodeFrameView?.frame = CGRect.zero
            self.captureSession?.startRunning()
        })
        
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "Enter UPC-13 barcode (optional)"
//            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
//                addAction.isEnabled = textField.text!.characters.count > 0
//            }
        })
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        let code: String = self.accessCode
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No code is detected"
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
            }
            
            self.captureSession?.stopRunning()
            
            let alert = UIAlertController(title: "Barcode Scanned", message: metadataObj.stringValue!, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {(action: UIAlertAction!) in
                let pvc = self.presentingViewController
                self.dismiss(animated: true, completion: {
                    let addInfoVC = self.storyboard?.instantiateViewController(withIdentifier: "AddInfoController") as! AddInfoController
                    addInfoVC.barcodeText = metadataObj.stringValue
                    print(code)
                    addInfoVC.accessCode = code
                    
                    pvc?.present(addInfoVC, animated:true, completion:nil)
                })
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(action: UIAlertAction!) in
                self.messageLabel.text = "No code is detected"
                self.qrCodeFrameView?.frame = CGRect.zero
                self.captureSession?.startRunning()
            }))
            present(alert, animated: true, completion: nil)
            
        }
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        super.prepare(for: segue, sender: sender)
    //        if let report = segue.destination as? AddInfoController {
    //            report.barcodeText = (messageLabel.text!)
    //            report.mainVC = self.mainVC
    //        }
    //    }
}

