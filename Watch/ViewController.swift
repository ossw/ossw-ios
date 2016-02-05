//
//  ViewController.swift
//  Watch
//
//  Created by Marek Smigielski on 20/01/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    let OSSWMyWatchUUID = NSUUID(UUIDString: "AE4A5368-12FC-2697-A8E3-4E37C33F6FD6")
    // IR Temp UUIDs
    let OSSWServiceUUID = CBUUID(string: "58C60001-20B7-4904-96FA-CBA8E1B95702")
    let OSSWTxCharacteristicUUID = CBUUID(string: "58C60002-20B7-4904-96FA-CBA8E1B95702")
    let OSSWRxCharacteristicUUID = CBUUID(string: "58C60003-20B7-4904-96FA-CBA8E1B95702")
    
    let DeveiceInformationServiceUUID = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    let FirmwareVersionCharacteristicUUID = CBUUID(string: "00002A26-0000-1000-8000-00805F9B34FB")
    
    
    var titleLabel : UILabel!
    var statusLabel : UILabel!
    var tempLabel : UILabel!
    
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up title label
        titleLabel = UILabel()
        titleLabel.text = "My SensorTag"
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: self.view.frame.midX, y: self.titleLabel.bounds.midY+28)
        self.view.addSubview(titleLabel)
        
        // Set up status label
        statusLabel = UILabel()
        statusLabel.textAlignment = NSTextAlignment.Center
        statusLabel.text = "Loading..."
        statusLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        statusLabel.sizeToFit()
        statusLabel.frame = CGRect(x: self.view.frame.origin.x, y: self.titleLabel.frame.maxY, width: self.view.frame.width, height: self.statusLabel.bounds.height)
        self.view.addSubview(statusLabel)
        
        // Set up temperature label
        tempLabel = UILabel()
        tempLabel.text = "firmware version"
        tempLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 36)
        tempLabel.sizeToFit()
        tempLabel.center = self.view.center
        self.view.addSubview(tempLabel)
        
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
//        let image = UIImage(named: "scenary")!
//        let rgbaImage = RGBAImage(image: image)!
//        
//        let avgRed = 107
//        
//        for y in 0..<rgbaImage.height {
//            for x in 0..<rgbaImage.width{
//                
//            }
//        }

        // Do any additional setup after loading the view, typically from a nib.

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? String
        print("Found: " , nameOfDeviceFound!, "(",peripheral.identifier,")")

        if (peripheral.identifier == OSSWMyWatchUUID) {
            
            
            // Update Status Label
            self.statusLabel.text = "Sensor Tag Found"
            // Stop scanning
            self.centralManager.stopScan()
            // Set as the peripheral to use and establish connection
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
        else {
            self.statusLabel.text = "Sensor Tag NOT Found"
        }
    }
    
    // If disconnected, start searching again
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        self.statusLabel.text = "Disconnected"
        central.scanForPeripheralsWithServices(nil, options: nil)
    }

    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripheralsWithServices(nil, options: nil)
            self.statusLabel.text = "Searching for BLE Devices"
        }
        else {
            // Can have different conditions for all states if needed - print generic message for now
            print("Bluetooth switched off or not initialized")
        }
    }
    
    // Discover services of the peripheral
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }

    // Check if the service discovered is a valid IR Temperature Service
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        self.statusLabel.text = "Looking at peripheral services"
        for service in peripheral.services! {
            let thisService = service as CBService
            if service.UUID == DeveiceInformationServiceUUID {
                // Discover characteristics of IR Temperature Service
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
            if service.UUID == OSSWServiceUUID {
                // Discover characteristics of IR Temperature Service
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
            // Uncomment to print list of UUIDs
            print(thisService.UUID)
        }
    }
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        // update status label
        self.statusLabel.text = "connecting to watch"
        

        if service.UUID == DeveiceInformationServiceUUID {
        // check the uuid of each characteristic to find config and data characteristics
            for charateristic in service.characteristics! {
                let thisCharacteristic = charateristic as CBCharacteristic
            // check for data characteristic
//            if thisCharacteristic.UUID == IRTemperatureDataUUID {
                // Enable Sensor Notification
//                self.sensorTagPeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
//            }
            // check for config characteristic
                if thisCharacteristic.UUID == FirmwareVersionCharacteristicUUID {
                // Enable Sensor
//                self.sensorTagPeripheral.writeValue(enablyBytes, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithResponse)
                    print("read firmware version")
                self.sensorTagPeripheral.readValueForCharacteristic(thisCharacteristic)
                }
            }
        } else if service.UUID == OSSWServiceUUID {
            // check the uuid of each characteristic to find config and data characteristics
            for charateristic in service.characteristics! {
                let thisCharacteristic = charateristic as CBCharacteristic
                // check for data characteristic
                //            if thisCharacteristic.UUID == IRTemperatureDataUUID {
                // Enable Sensor Notification
                //                self.sensorTagPeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
                //            }
                // check for config characteristic
                if thisCharacteristic.UUID == OSSWTxCharacteristicUUID {
                    // 0x01 data byte to enable sensor
                            let data = NSMutableData()
                            var command = 0x10

                            data.appendBytes(&command, length: sizeof(UInt8))
                            var currentTime = currentTimeMillis()
                                                var val = currentTime.bigEndian
                            data.appendBytes(&val, length: sizeofValue(val))
                            data.appendBytes(&currentTime, length: sizeof(UInt32))
                    

                    
                    
                    // Enable Sensor
                    print("write time: ",currentTime)
                    self.sensorTagPeripheral.writeValue(data, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
                }
            }
        }
        
    }
    
    func currentTimeMillis() -> UInt32{
        let nowDouble = NSDate().timeIntervalSince1970
        let timezone = NSTimeZone.localTimeZone().secondsFromGMT
        return UInt32(nowDouble) + UInt32(timezone)
    }
    
    // Get data values when they are updated
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        self.statusLabel.text = "Connected"
        
        if characteristic.UUID == FirmwareVersionCharacteristicUUID {
            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value
            let dataLength = dataBytes!.length
            var dataArray = [UInt8](count: dataLength, repeatedValue: 0)
            dataBytes!.getBytes(&dataArray, length: dataLength * sizeof(UInt8))
            
            // Element 1 of the array will be ambient temperature raw value
            let ambientTemperature = NSString(bytes: dataArray, length: dataArray.count, encoding: NSUTF8StringEncoding)
            print(ambientTemperature)
            // Display on the temp label
            self.tempLabel.text = String( ambientTemperature!)
        }
    }


}

