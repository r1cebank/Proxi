//
//  ChatManager.swift
//  Proxi
//
//  Created by Siyuan Gao on 4/22/15.
//  Copyright (c) 2015 Siyuan Gao. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ChatManagerDelegate {
    func gotMessage(receivedDataDictionary: Dictionary<String, AnyObject>)
}


class ChatManager: NSObject {
    
    var delegate: ChatManagerDelegate?
    var mpcManager: MPCManager!
    var currentSession: MCSession!
    var messageArchive = [String:NSMutableArray]()
    var unreadFrom = [String:Int32]()
    
    lazy private var messageArchivePath: String = {
        let fileManager = NSFileManager.defaultManager()
        let documentDirectoryURLs = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask) as! [NSURL]
        let archiveURL = documentDirectoryURLs.first!.URLByAppendingPathComponent("Proxi-Message", isDirectory: true)
        return archiveURL.path!
    }()
    lazy private var unreadArchivePath: String = {
        let fileManager = NSFileManager.defaultManager()
        let documentDirectoryURLs = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask) as! [NSURL]
        let archiveURL = documentDirectoryURLs.first!.URLByAppendingPathComponent("Proxi-Unread", isDirectory: true)
        return archiveURL.path!
    }()
    
    func saveMsg() {
        NSKeyedArchiver.archiveRootObject(messageArchive, toFile: messageArchivePath)
    }
    
    func unarchiveSavedItems() {
        if NSFileManager.defaultManager().fileExistsAtPath(messageArchivePath) {
            messageArchive = NSKeyedUnarchiver.unarchiveObjectWithFile(messageArchivePath) as! [String: NSMutableArray]
        }
        
    }
    
    func reset() {
        if NSFileManager.defaultManager().fileExistsAtPath(messageArchivePath) {
            NSFileManager.defaultManager().removeItemAtPath(messageArchivePath, error: nil)
        }
        messageArchive.removeAll()
    }
    
    init(manager: MPCManager) {
        super.init()
        mpcManager = manager
    }
    func newOrGetUnread(clientID: String) -> Int32 {
        var count: Int32 = -1
        
        if let a = unreadFrom[clientID] {
            println("Restoring unreadCount with: \(clientID)")
            count = a
        } else {
            println("Creating a new unreadCount with: \(clientID)")
            unreadFrom[clientID] = count
        }
        
        return count
    }
    func newOrGetArchive(clientID: String) -> NSMutableArray {
        for (key, value) in messageArchive {
            if(getDisplayNameFromID(key) == getDisplayNameFromID(clientID)) {
                println("Restoring archive with: \(clientID)")
                let archive = messageArchive[key]!
                messageArchive.removeValueForKey(key)
                messageArchive[clientID] = archive
                return messageArchive[clientID]!
            }
        }
        println("Creating a new archive with: \(clientID)")
        messageArchive[clientID] = NSMutableArray()
        return messageArchive[clientID]!
    }
    //Handle inner application notifications
    func handleMPCReceivedDataWithNotification(notification: NSNotification) {
        let receivedDataDictionary = notification.object as! Dictionary<String, AnyObject>
        delegate?.gotMessage(receivedDataDictionary)
        /*
        // "Extract" the data and the source peer from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        let session = receivedDataDictionary["session"] as! MCSession
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! Dictionary<String, String>
        if let message = dataDictionary["message"] {
            println("ChatManager : handleMPC : \(message) : from : \(fromPeer.displayName)")
            let archive = newOrGetArchive(fromPeer.displayName)
            let chatMessage = ChatMessage(sender: false, msg: message)
            archive.addObject(chatMessage)
        }*/
    }
}