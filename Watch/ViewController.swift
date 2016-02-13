//
//  ViewController.swift
//  Watch
//
//  Created by Marek Smigielski on 20/01/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import UIKit
import CoreBluetooth
import SocketIOClientSwift


class ViewController: UIViewController,ModalViewControllerDelegate  {

    let OSSWMyWatchUUID = NSUUID(UUIDString: "AE4A5368-12FC-2697-A8E3-4E37C33F6FD6")
    
    var watch: OSSWatch!
    var bleManager:BleManager!
    
    
    var timer = NSTimer()
    
    
    @IBOutlet weak var watchStatus: UILabel!
    @IBOutlet weak var watchConnectionTime: UILabel!
    @IBOutlet weak var watchReceivedBytes: UILabel!
    @IBOutlet weak var watchSendBytest: UILabel!
    
    @IBOutlet weak var watchButton: UIButton!
    
    @IBOutlet weak var firmwareLabel: UILabel!
    
    var connection: BleManager.ConnectionStatus = .NotConnected
    
    
    @IBOutlet weak var serverAddress: UILabel!
    @IBOutlet weak var serverStatus: UILabel!
    @IBOutlet weak var serverConnectionTime: UILabel!
    
    @IBOutlet weak var serverReceivedBytes: UILabel!
    
    @IBOutlet weak var serverSendBytes: UILabel!
    
    @IBOutlet weak var serverButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func connectWatch(sender: UIButton) {
        
        if bleManager==nil{
            bleManager = BleManager(updateStatus:updateStatus,peripheralUUID: OSSWMyWatchUUID!)
        }
        
        self.watchButton.enabled=false
        if connection == .NotConnected || connection == .NotInitialized  {
            bleManager.connect(connected);
        } else {
            bleManager.disconnect(watch.peripheral);
            watch=nil
        }

    }
    
    @IBAction func scanQrCode(sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let qrCodeScanner = storyboard.instantiateViewControllerWithIdentifier("QRCodeScanner") as! QRCodeScanner
        qrCodeScanner.delegate=self;
        self.presentViewController(qrCodeScanner, animated: true, completion: nil)
    }
    
    func foundCode(value : NSString){
        print(value)
        
        let qrcode = parseQRCode(value)
        
        
        
        let socket = SocketIOClient(socketURL: qrcode.url! )
        socket.on("message") {data, ack in
            print("Message for you! \(data[0])")
        }
        socket.on("connect") {data, ack in
            print("socket connected")
            socket.emit("channel", ["token": qrcode.token!])
//            socket.emit("message", "test")
        }
        socket.connect()
        
    }
    
    struct QRCode {
        var token: String?
        var url : NSURL?
    }
    
    func parseQRCode(value : NSString) -> QRCode{
        var qrCode = QRCode()
        do {
            let data = value.dataUsingEncoding(NSUTF8StringEncoding)
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            if let token = json["token"] as? String {
                qrCode.token=token
            }
            if let url = json["url"] as? String {
                qrCode.url=NSURL(string:url)
            }
            
        } catch {
            print("error serializing JSON: \(error)")
        }
        return qrCode
    }

    
    
    func updateStatus(connection: BleManager.ConnectionStatus){
        self.connection=connection;
        switch connection {
        case .NotInitialized:
            self.watchStatus.text = "Not initialized"
        case .NotConnected:
            self.watchStatus.text = "Disconnected"
            self.watchButton.setTitle("Connect watch", forState: UIControlState.Normal)
            stopRefresh()
            self.watchButton.enabled=true
        case .Searching:
            self.watchButton.enabled=false
            self.watchStatus.text = "Searching..."
        case .Connecting:
            self.watchStatus.text = "Connecting..."
            self.watchButton.setTitle("Disconnect watch", forState: UIControlState.Normal)
            self.watchButton.enabled=true
        case .Connected:
            self.watchStatus.text = "Connected"
            self.watch.prepare(updateFirmware)
        }
    }
    
    func connected(watch: CBPeripheral){
        self.watch = OSSWatch(watch: watch)
        startRefresh()
    }
    
    func updateFirmware(version: NSString?){
        firmwareLabel.text=String(version!)
        watch.synchTime()
    }
    
    func startRefresh() {
        if !timer.valid {
            let aSelector : Selector = "updateStatistics"
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: aSelector,     userInfo: nil, repeats: true)
        }
    }
    
    func stopRefresh() {
        timer.invalidate()
    }
    
    func updateStatistics() {
        if watch != nil {
            watchConnectionTime.text = updateTime(watch.connectionTime)
            watchReceivedBytes.text = String(watch.dataIn)
            watchSendBytest.text  = String(watch.dataOut)
        }
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTime(connectionTime: NSTimeInterval) -> String {
        
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        
        //Find the difference between current time and start time.
        
        var elapsedTime: NSTimeInterval = currentTime - connectionTime
        
        //calculate the minutes in elapsed time.
        
        let hours = UInt8(elapsedTime / 3600.0)
        
        elapsedTime -= (NSTimeInterval(hours) * 3600)
        
        
        let minutes = UInt8(elapsedTime / 60.0)
        
        elapsedTime -= (NSTimeInterval(minutes) * 60)
        
        //calculate the seconds in elapsed time.
        
        let seconds = UInt8(elapsedTime)
        
        elapsedTime -= NSTimeInterval(seconds)
        
        //add the leading zero for minutes, seconds and millseconds and store them as string constants
        let strHours = String(format: "%02d", hours)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        //concatenate minuets, seconds and milliseconds as assign it to the UILabel
        
        return "\(strHours):\(strMinutes):\(strSeconds)"
    }

}

protocol ModalViewControllerDelegate
{
    func foundCode(var value : NSString)
}
