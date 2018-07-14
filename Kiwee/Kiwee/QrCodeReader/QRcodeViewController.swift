//
//  QRcodeViewController.swift
//  Invite
//
//  Created by Luc CASIMIR on 07/06/2018.
//  Copyright © 2018 bmw. All rights reserved.
//

import UIKit
import AVFoundation

public class QRcodeViewController: UIViewController {
    
    public static var instanciateController : QRcodeViewController? {
        return UIStoryboard(name: "QRcode", bundle: Bundle(for: QRcodeViewController.self)).instantiateInitialViewController() as? QRcodeViewController
    }
    
    //---------------------------------------------------------------------------------------------------
    // MARK: Properties
    //---------------------------------------------------------------------------------------------------

    fileprivate var captureSession              : AVCaptureSession?
    fileprivate var videoPreviewLayer           : AVCaptureVideoPreviewLayer?
    
    fileprivate let qrcodeQueue = DispatchQueue(label: "Qrcode.queue")
    
    public var qrCompletion : ((String) -> Void)?
    
    //---------------------------------------------------------------------------------------------------
    // MARK: Setup
    //---------------------------------------------------------------------------------------------------
    
    private func setupCamera() {
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        do {
            
            // get the Input device
            let captureInput = try AVCaptureDeviceInput(device: captureDevice)
            
            // Connect sessions with capture device videos
            self.captureSession = AVCaptureSession()
            self.captureSession?.addInput(captureInput)
            
            // Set a metaoutput on the captureSession
            let metaOutput = AVCaptureMetadataOutput()
            self.captureSession?.addOutput(metaOutput)
            
            // Sets delegate and meta object type
            metaOutput.setMetadataObjectsDelegate(self, queue: qrcodeQueue)
            metaOutput.metadataObjectTypes = [.qr]
            
        } catch let err {
            print("Error => \(err)")
            self.captureSession = nil
        }
        
        // create the video layer
        if let captureSession = self.captureSession {
            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        }
    }
    
    //---------------------------------------------------------------------------------------------------
    // MARK: Life cycle
    //---------------------------------------------------------------------------------------------------
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        self.setupCamera()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewDidLayoutSubviews() {}
    
    //---------------------------------------------------------------------------------------------------
    // MARK: public
    //---------------------------------------------------------------------------------------------------
    
    public func startScan() {
        
        self.captureSession?.startRunning()
        self.videoPreviewLayer?.isHidden = false
        
        if let videoLayer = self.videoPreviewLayer {
            videoLayer.frame = self.view.bounds
            videoLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(videoLayer)
        }
    }

    public func stopScan() {
        
        self.captureSession?.stopRunning()
        self.videoPreviewLayer?.isHidden = true
        
        if let videoLayer = self.videoPreviewLayer {
            videoLayer.removeFromSuperlayer()
        }
    }
}

//---------------------------------------------------------------------------------------------------
// MARK: Capture Meta Data Output Delegate
//---------------------------------------------------------------------------------------------------

extension QRcodeViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        DispatchQueue.main.async {self.stopScan()}
        
        for elem in metadataObjects {
            if let data = elem as? AVMetadataMachineReadableCodeObject {
                if let qrValue = data.stringValue {
                    self.qrCompletion?(qrValue)
                }
            }
        }
        
    }
}
