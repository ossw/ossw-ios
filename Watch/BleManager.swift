//
//  BleManager.swift
//  Watch
//
//  Created by Marek Smigielski on 20/01/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import Foundation
import CoreBluetooth

class BleManager : NSObject, CBCentralManagerDelegate{
    
    enum ConnectionStatus {
        case NotInitialized
        case NotConnected
        case Searching
        case Connecting
        case Connected
    }
    
    let uuid:NSUUID!
    
    var centralManager : CBCentralManager!
    var onConnecting : ((CBPeripheral) -> Void)?
    let updateStatus:(ConnectionStatus)-> Void!

    
    var reconnect = false

    
    init(updateStatus:(ConnectionStatus)-> Void, peripheralUUID: NSUUID ) {
        self.updateStatus=updateStatus
        self.uuid=peripheralUUID
        
    }
    
    func connect(onConnecting: (CBPeripheral) -> Void){
        self.reconnect=true
        self.onConnecting=onConnecting
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func disconnect(peripheral: CBPeripheral){
        self.centralManager.cancelPeripheralConnection(peripheral)
        self.reconnect=false
    }

    
        

        
        
        init(updateStatus:(ConnectionStatus)-> Void,uuid: NSUUID){
            self.uuid=uuid
            self.updateStatus = updateStatus
        }
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripheralsWithServices(nil, options: nil)
            updateStatus(.Searching)
        }
        else {
            updateStatus(.NotInitialized)
            // Can have different conditions for all states if needed - print generic message for now
            print("Bluetooth switched off or not initialized")
        }
    }
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
 
        
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? String
        print("Found: " , nameOfDeviceFound!, "(",peripheral.identifier,")")
        
        if (peripheral.identifier == uuid) {
            // Update Status Label
            updateStatus(.Connecting)
            // Stop scanning
            central.stopScan()
            
            if onConnecting != nil {
                onConnecting!(peripheral)
            }
            // Set as the peripheral to use and establish connection
            central.connectPeripheral(peripheral, options: nil)
            
            
        }
    }
    
    
    // If disconnected, start searching again
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        updateStatus(.NotConnected)
        //
        if reconnect {
            central.scanForPeripheralsWithServices(nil, options: nil)
            updateStatus(.Searching)
        }
    }
    
    // Discover services of the peripheral
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("connected")
        updateStatus(.Connected)

    }
    
}