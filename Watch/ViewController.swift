//
//  ViewController.swift
//  Watch
//
//  Created by Marek Smigielski on 20/01/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController  {

    let OSSWMyWatchUUID = NSUUID(UUIDString: "AE4A5368-12FC-2697-A8E3-4E37C33F6FD6")
    
    var watch: OSSWatch!
    var bleManager:BleManager!
    
    
    @IBOutlet weak var watchStatus: UILabel!
    @IBOutlet weak var watchConnectionTime: UILabel!
    @IBOutlet weak var watchReceivedBytes: UILabel!
    @IBOutlet weak var watchSendBytest: UILabel!
    
    @IBOutlet weak var watchButton: UIButton!
    
    @IBOutlet weak var firmwareLabel: UILabel!

    var watchConnectionStartTime = NSTimeInterval()
    
    var connection: BleManager.ConnectionStatus = .NotConnected


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
    
    func connected(watch: CBPeripheral){
        self.watch = OSSWatch(watch: watch)
    }
    
    func updateStatus(connection: BleManager.ConnectionStatus){
        self.connection=connection;
        switch connection {
        case .NotInitialized:
            self.watchStatus.text = "Not initialized"
        case .NotConnected:
            self.watchStatus.text = "Disconnected"
            self.watchButton.setTitle("Connect watch", forState: UIControlState.Normal)
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
    
    func updateFirmware(version: NSString?){
        firmwareLabel.text=String(version!)
        watch.synchTime()
    }
    
    @IBAction func scanQrCode(sender: UIButton) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

