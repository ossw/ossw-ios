//
//  ServerManager.swift
//  Watch
//
//  Created by Marek Smigielski on 13/02/16.
//  Copyright © 2016 ossw. All rights reserved.
//

import Foundation
import SocketIOClientSwift

class SocketManager
{
    enum ConnectionStatus {
        case NotConnected
        case Connecting
        case Connected
    }
    
    let updateStatus:(ConnectionStatus)-> Void!
    let channel :  AnyObject
    
    var serverAddress : String
    var connectionTime = NSDate.timeIntervalSinceReferenceDate()
    var dataIn = 0
    var dataOut = 0
    
    var socket : SocketIOClient!

    init(updateStatus:(ConnectionStatus)-> Void, channel : AnyObject ){
        self.updateStatus=updateStatus
        self.channel=channel
        serverAddress=channel["url"] as! String
    }
    
    func connect(){
        updateStatus(.Connecting);
        self.socket = SocketIOClient(socketURL: NSURL(string:channel["url"] as! String)!)
        self.socket.on("message") {data, ack in
            print("Message for you! \(data[0])")
            self.dataOut+=data[0].length
        }
        self.socket.on("connect") {data, ack in
            self.updateStatus(.Connected);
            print("socket connected")
            self.socket.emit("channel", ["token": self.channel["token"] as! String])
            //            socket.emit("message", "test")
        }
        self.socket.connect()

    }
    
    func disconnect(){
        self.socket.disconnect()
        updateStatus(.NotConnected);
    }
}