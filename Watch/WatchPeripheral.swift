//
//  WatchPeripheral.swift
//  Watch
//
//  Created by Marek Smigielski on 09/02/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import Foundation
import CoreBluetooth


class OSSWatch{
    

    let DeveiceInformationServiceUUID = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    let FirmwareVersionCharacteristicUUID = CBUUID(string: "00002A26-0000-1000-8000-00805F9B34FB")
    
    let OSSWServiceUUID = CBUUID(string: "58C60001-20B7-4904-96FA-CBA8E1B95702")
    let OSSWTxCharacteristicUUID = CBUUID(string: "58C60002-20B7-4904-96FA-CBA8E1B95702")
    let OSSWRxCharacteristicUUID = CBUUID(string: "58C60003-20B7-4904-96FA-CBA8E1B95702")
    

    var peripheralHandler : PeripheralHandler
    var peripheral : CBPeripheral
    var onInitialize : ((NSString?) -> Void)?
    
    
    init(watch: CBPeripheral){
        print("init watch")
        self.peripheral=watch
        self.peripheralHandler = PeripheralHandler(peripheral: watch, expectedServices: [DeveiceInformationServiceUUID,OSSWServiceUUID])
    }
    
    func prepare(onInitialize: (NSString?) -> Void){
        print("preparing watch")
        self.onInitialize=onInitialize
        peripheralHandler.prepare( self.ready )
    }
    
    
    func ready() {
        
        peripheralHandler.registerCallback(FirmwareVersionCharacteristicUUID, callback: readFirmware)
        print("request firmware")
        peripheralHandler.readValue(FirmwareVersionCharacteristicUUID)
        
        print("subscribe for notifications")
    }
    
    func synchTime(){
        print("synchronise time")
        let data = NSMutableData()
        
        var command = 0x10
        data.appendBytes(&command, length: sizeof(UInt8))
        var currentTime = currentTimeMillis()
        var val = currentTime.bigEndian
        data.appendBytes(&val, length: sizeofValue(val))
        data.appendBytes(&currentTime, length: sizeof(UInt32))

        peripheralHandler.writeValue(OSSWTxCharacteristicUUID,data:data)
        
        
    }
    
    func currentTimeMillis() -> UInt32{
        let nowDouble = NSDate().timeIntervalSince1970
        let timezone = NSTimeZone.localTimeZone().secondsFromGMT
        return UInt32(nowDouble) + UInt32(timezone)
    }
    
    func readFirmware(dataBytes:NSData){
        print("firmware received")
        // Convert NSData to array of signed 16 bit values
        let dataLength = dataBytes.length
        var dataArray = [UInt8](count: dataLength, repeatedValue: 0)
        dataBytes.getBytes(&dataArray, length: dataLength * sizeof(UInt8))
        if onInitialize != nil {
            onInitialize!(NSString(bytes: dataArray, length: dataArray.count, encoding: NSUTF8StringEncoding))
        }
    }
    
    class PeripheralHandler: NSObject, CBPeripheralDelegate{
        
        var updateFunction : [CBUUID: (NSData) -> Void]
        var onInit : (() -> Void)?
        var characteristics : [CBUUID: CBCharacteristic]
        var expectedServices : [CBUUID]
        
        var peripheral : CBPeripheral
//        var services 
        
        
        init(peripheral: CBPeripheral, expectedServices: [CBUUID]){
            self.updateFunction = [:]
            self.characteristics = [:]

            self.expectedServices=expectedServices
            self.peripheral=peripheral

        }
        
        func prepare(onInit: () -> Void){
            self.onInit=onInit
            self.peripheral.delegate = self
            self.peripheral.discoverServices(expectedServices)
        }
        
        
        func readValue(characteristic: CBUUID){
            if characteristics[characteristic] != nil {
                peripheral.readValueForCharacteristic(characteristics[characteristic]!)
            }
        }
        
        func writeValue(characteristic: CBUUID,data: NSData ){
            if characteristics[characteristic] != nil {
                peripheral.writeValue(data, forCharacteristic: characteristics[characteristic]!, type: CBCharacteristicWriteType.WithoutResponse)
            }
        }
        
        func registerCallback(characteristicUUID: CBUUID, callback:(NSData) -> Void){
            updateFunction[characteristicUUID] = callback
        }

        
        func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
            for service in peripheral.services! {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
        
        // Enable notification and sensor for each characteristic of valid service
        func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
            //update characterisitcs
            for characteristic in service.characteristics! {
                characteristics[characteristic.UUID]=characteristic
            }
            //check if all characteristics are found
            expectedServices.removeObject(service.UUID)
        
            if expectedServices.count == 0 && onInit != nil {
                onInit!();
            }
            
        }
        
        
        
        // Get data values when they are updated
        func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            
            if updateFunction[characteristic.UUID] != nil {
                updateFunction[characteristic.UUID]!(characteristic.value!)
            }
        }
    }
    

    
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}