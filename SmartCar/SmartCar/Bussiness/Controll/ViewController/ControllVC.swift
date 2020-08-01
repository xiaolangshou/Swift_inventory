//
//  ControllVC.swift
//  SmartCar
//
//  Created by Thomas Lau on 2020/7/18.
//  Copyright © 2020 TLLTD. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import SnapKit
import AVFoundation
import CocoaMQTT

class ControllVC: UIViewController, WKUIDelegate {
    
    static let shared = ControllVC()
    
    let playerView = TLPlayerView()
    
    var webView = WKWebView()
    var mqttMng: MQTTMng?
    var stickView: StickView?
    var slider: UISlider?
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var urlStr = "http://192.168.1.88:8080/?action=stream"
    
    enum controlModel: String {
        case left = "3"
        case right = "4"
        case up = "1"
        case down = "2"
    }
    
    enum gimbalModel: String {
        case up = "top+"
        case down = "top-"
        case left = "bt+"
        case right = "bt-"
    }
    
    var speed: Int = 1

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DirectionTool.topViewController = navigationController?.topViewController;
        DirectionTool.forceOrientationAll()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(recievedRotation),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func recievedRotation() {
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.unknown:
            print("方向未知")
        case .portrait:
            print("屏幕直立")
            self.tabBarController?.tabBar.isHidden = false
        case .portraitUpsideDown:
            print("屏幕倒立")
            self.tabBarController?.tabBar.isHidden = false
        case .landscapeLeft:
            print("屏幕左在上方")
            self.tabBarController?.tabBar.isHidden = true
        case .landscapeRight:
            print("屏幕右在上方")
            self.tabBarController?.tabBar.isHidden = true
        case .faceUp:
            print("屏幕朝上")
        case .faceDown:
            print("屏幕朝下")
        @unknown default:
            fatalError()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        initMQTT()
    }

    deinit {
        mqttMng?.mqtt?.disconnect()
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "status")
    }
    
    func setupView() {
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // setupLayer()
        setupWebPlayer()
        
        stickView = StickView.init(frame: CGRect.init(x: 0,
                                                      y: 0,
                                                      width: view.frame.height,
                                                      height: view.frame.width))
        view.addSubview(stickView ?? UIView())
        stickView?.frontBtnTouchdown = {
            
            if !GCDTimer.shared.isExistTimer(WithTimerName: "timer") {
                GCDTimer.shared.scheduledDispatchTimer(WithTimerName: "timer", timeInterval: 0.1, queue: DispatchQueue.main, repeats: true) {
                    print("\(controlModel.up.rawValue)" + "\(self.speed)")
                    let msg = "\(controlModel.up.rawValue)" + "\(self.speed)"
                    self.mqttMng?.sendMsg(topic: "EV", msg: msg)
                }
            }
        }
        stickView?.frontBtnTouchcancel = {
            
            GCDTimer.shared.cancelTimer(WithTimerName: "timer")
        }
        stickView?.backBtnTouchdown = {
            
            if !GCDTimer.shared.isExistTimer(WithTimerName: "timer") {
                GCDTimer.shared.scheduledDispatchTimer(WithTimerName: "timer", timeInterval: 0.1, queue: DispatchQueue.main, repeats: true) {
                    print("\(controlModel.down.rawValue)" + "\(self.speed)")
                    
                    let msg = "\(controlModel.down.rawValue)" + "\(self.speed)"
                    self.mqttMng?.sendMsg(topic: "EV", msg: msg)
                }
            }
        }
        stickView?.backBtnTouchcancel = {

            GCDTimer.shared.cancelTimer(WithTimerName: "timer")
        }
        stickView?.leftBtnTouchdown = {
            
            if !GCDTimer.shared.isExistTimer(WithTimerName: "timer") {
                GCDTimer.shared.scheduledDispatchTimer(WithTimerName: "timer", timeInterval: 0.1, queue: DispatchQueue.main, repeats: true) {
                    print("\(controlModel.left.rawValue)" + "\(self.speed)")
                    
                    let msg = "\(controlModel.left.rawValue)" + "\(self.speed)"
                    self.mqttMng?.sendMsg(topic: "EV", msg: msg)
                }
            }
        }
        stickView?.leftBtnTouchcancel = {
            
            GCDTimer.shared.cancelTimer(WithTimerName: "timer")
        }
        
        stickView?.rightBtnTouchdown = {
            
            if !GCDTimer.shared.isExistTimer(WithTimerName: "timer") {
                GCDTimer.shared.scheduledDispatchTimer(WithTimerName: "timer", timeInterval: 0.1, queue: DispatchQueue.main, repeats: true) {
                    print("\(controlModel.right.rawValue)" + "\(self.speed)")
                    
                    let msg = "\(controlModel.right.rawValue)" + "\(self.speed)"
                    self.mqttMng?.sendMsg(topic: "EV", msg: msg)
                }
            }
        }
        stickView?.rightBtnTouchcancel = {
            
            GCDTimer.shared.cancelTimer(WithTimerName: "timer")
        }
        
        stickView?.leftAction = {
            self.mqttMng?.sendMsg(topic: "EV", msg: gimbalModel.left.rawValue)
        }
        
        stickView?.rightAction = {
            self.mqttMng?.sendMsg(topic: "EV", msg: gimbalModel.right.rawValue)
        }
        
        stickView?.upAction = {
            self.mqttMng?.sendMsg(topic: "EV", msg: gimbalModel.up.rawValue)
        }
        
        stickView?.downAction = {
            self.mqttMng?.sendMsg(topic: "EV", msg: gimbalModel.down.rawValue)
        }
        
        slider = UISlider()
        view.addSubview(slider!)
        slider!.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(60)
        }
        slider!.value = 1
        slider!.minimumValue = 1
        slider!.maximumValue = 3
        slider!.addTarget(self, action: #selector(SliderChanged), for: .valueChanged)
    }
    
    @objc func SliderChanged(_ slider: UISlider) {
        print("self.speed = \(slider.value)")
        self.speed = Int(slider.value)
    }
    
    func setupWebPlayer() {
        webView = WKWebView()
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = false
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let myURL = URL(string: urlStr)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    func setupLayer() {
        guard let url = URL(string: urlStr) else { fatalError("连接错误") }
        
        playerItem = AVPlayerItem(url: url)
        // 监听缓冲进度改变
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        // 监听状态改变
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer?.contentsScale = UIScreen.main.scale
        playerView.playerLayer = self.playerLayer
        playerView.layer.insertSublayer(playerLayer!, at: 0)
    
        view.addSubview(playerView)
        playerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func initMQTT() {
        self.mqttMng = MQTTMng.init(clientID: "id",
                                    host: "192.168.1.220",
                                    port: 1883,
                                    username: "admin",
                                    password: "public",
                                    topic: "EV",
                                    message: "",
                                    keepAlive: 60)
        self.mqttMng?.connect()
        self.mqttMng?.mqtt!.delegate = self
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == "loadedTimeRanges"{
            // 缓冲进度 暂时不处理
        } else if keyPath == "status" {
            // 监听状态改变
            if playerItem.status == AVPlayerItem.Status.readyToPlay {
                // 只有在这个状态下才能播放
                self.player?.play()
            } else {
                print("加载异常")
            }
        }
    }
}

extension ControllVC: CocoaMQTTDelegate {

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print(#function)
        if ack == .accept {
            mqtt.subscribe("EV", qos: CocoaMQTTQOS.qos1)
            mqtt.ping()
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string!)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {

        print("didReceivedMessage: \(String(describing: message.string)) with id \(id)")

//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MQTTMessageNotification"),
//                                        object: self,
//                                        userInfo: ["message": message.string!, "topic": message.topic])
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        print("didSubscribeTopic to \(topics)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
         print("didUnsubscribeTopic to \(topic)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print(#function)
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print(#function)
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print(#function)
    }

}
