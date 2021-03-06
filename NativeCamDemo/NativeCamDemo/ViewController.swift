//
//  ViewController.swift
//  NativeCamDemo
//
//  Created by Thomas Lau on 2020/4/16.
//  Copyright © 2020 TLLTD. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
 
    /// 摄像头授权状态
    var cameraAuthStatus: AVAuthorizationStatus!
    /// 预览Layer
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!
    /// Session
    var session: AVCaptureSession!
    /// 硬件Input
    var captureInput: AVCaptureDeviceInput!
    /// 数据Output
    var captureOutput: AVCaptureVideoDataOutput!
    var count = 0
    var imageView = UIImageView(frame: CGRect(x: 5,
                                              y: 300,
                                              width: UIScreen.main.bounds.width - 10,
                                              height: 350))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.session.stopRunning()
        
        super.viewWillDisappear(animated)
    }
    
    func setupView() {
        
        let titleV = UILabel.init(frame: CGRect.init(x: 0,
                                                    y: 20,
                                                    width: UIScreen.main.bounds.width,
                                                    height: 20))
        view.addSubview(titleV)
        titleV.text = "本地视频采集预览(上)和重新显示(下)"
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(imageView)
    }
    
    // 摄像头设置
    func setupCamera() {
        
        self.session = AVCaptureSession()
        let device = AVCaptureDevice.default(for: AVMediaType.video)!
        self.captureOutput = AVCaptureVideoDataOutput()
        do {
            try self.captureInput = AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            print(error)
        }
        
        self.checkVideoAuth()
 
        self.session.beginConfiguration()
        // 画面质量设置
        self.session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let dic = [kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_32BGRA)]
        var videoSettings = AVCaptureVideoDataOutput().videoSettings
        videoSettings = dic as [String : Any]
        self.captureOutput.videoSettings = videoSettings
        if (self.session.canAddInput(self.captureInput)) {
            self.session.addInput(self.captureInput)
        }
        if (self.session.canAddOutput(self.captureOutput)) {
            self.session.addOutput(self.captureOutput)
        }
        
        let subQueue = DispatchQueue.init(label: "subQueue")
        captureOutput.setSampleBufferDelegate(self, queue: subQueue)
        
        // 预览Layer设置
        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.captureVideoPreviewLayer.frame = CGRect(x: 5,
                                                     y: 30,
                                                     width: UIScreen.main.bounds.width - 10,
                                                     height: 250)
        self.captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.captureVideoPreviewLayer)
        self.session.commitConfiguration()
    }
    
   // 检查授权状态
   func checkVideoAuth() {

       switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
       case AVAuthorizationStatus.authorized: // 已经授权
           self.cameraAuthStatus = AVAuthorizationStatus.authorized
           break
       case AVAuthorizationStatus.notDetermined:
           AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
               if (granted) {
                   //受限制
                   self.cameraAuthStatus = AVAuthorizationStatus.restricted
                   exit(0)
               }
           })
           break
       case AVAuthorizationStatus.denied:
           AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
               if(!granted){
                   //否认
                   self.cameraAuthStatus = AVAuthorizationStatus.denied
                   print("摄像头权限未开启")
               }
           })
           break
       default:
           break
       }
   }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        print("converting sampleBuffer to Image \(count)")
        count += 1
        let img = self.getImageData(sampleBuffer: sampleBuffer)
        DispatchQueue.main.async {
            self.imageView.image = img
            self.imageView.contentMode = .scaleAspectFit
        }
    }
    
    /**
     数据流BufferRef转Image
     - parameter sampleBuffer: 数据流
     - returns: UIImage
     */
    func getImageData(sampleBuffer: CMSampleBuffer!) -> UIImage {
    
        let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, [])
        
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: size_t = CVPixelBufferGetWidth(imageBuffer)
        let height: size_t = CVPixelBufferGetHeight(imageBuffer)
        
        let safepoint: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(imageBuffer)!
        let bitMapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // RGB
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let context:CGContext = CGContext(data: safepoint, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitMapInfo)!
        
        let quartImage: CGImage = context.makeImage()!
        CVPixelBufferUnlockBaseAddress(imageBuffer, [])
        
        return UIImage(cgImage: quartImage, scale: 1, orientation: .right)
    }
}
