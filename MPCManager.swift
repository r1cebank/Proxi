//
//  MPCManager.swift
//  MPCRevisited
//
//  Original Created by Gabriel Theodoropoulos on 11/1/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//  Modified by Siyuan Gao on May 20, 2015
//  Copyright (c) 2015 Siyuan Gao. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import JDStatusBarNotification


protocol MPCManagerDelegate {
    func foundPeer()
    
    func lostPeer()
    
    func invitationWasReceived(fromPeer: String)
    
    func connectedWithPeer(peerID: MCPeerID)
    
}


class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {

    var delegate: MPCManagerDelegate?
    
    var handle: String!
    
    var currentSession: MCSession!
    var currentPeerID   : String!
    var currentPeerHandle   : String!
    
    
    var sessions = [String : ProxiSession]()
    
    var peer: MCPeerID!
    
    var browser: MCNearbyServiceBrowser!
    
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    
    var invitationHandler: ((Bool, MCSession!)->Void)!
    
    var isVisible: Bool!
    
    lazy private var sessionArchivePath: String = {
        let fileManager = NSFileManager.defaultManager()
        let documentDirectoryURLs = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask) as! [NSURL]
        let archiveURL = documentDirectoryURLs.first!.URLByAppendingPathComponent("Proxi-Session", isDirectory: true)
        return archiveURL.path!
    }()
    
    func reset() {
        if NSFileManager.defaultManager().fileExistsAtPath(sessionArchivePath) {
            NSFileManager.defaultManager().removeItemAtPath(sessionArchivePath, error: nil)
        }
        sessions.removeAll()
    }
    
    
    init(hdl: String) {
        super.init()
        
        handle = hdl
        
        var signature = NSUserDefaults.standardUserDefaults().stringForKey("UUID")!
        signature += "$\(handle)"
        println(signature)
        
        peer = MCPeerID(displayName: signature)
        
        isVisible = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isVisible")
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "proxi-mpc-srv")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "proxi-mpc-srv")
        advertiser.delegate = self
    }
    
    func newHandle(hdl: String) {
        handle = hdl
        var signature = NSUserDefaults.standardUserDefaults().stringForKey("UUID")!
        signature += "$\(handle)"
        peer = MCPeerID(displayName: signature)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "proxi-mpc-srv")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "proxi-mpc-srv")
        advertiser.delegate = self
        
        println("MPCManager : newHandle called and new section is created")
        
    }
    
    func newOrGetSession(clientID: String) -> ProxiSession {
        for (key, value) in sessions {
            if(getDisplayNameFromID(key) == getDisplayNameFromID(clientID)) {
                println("Restoring session with: \(clientID)")
                //Replace key
                let session = sessions[key]!
                sessions.removeValueForKey(key)
                sessions[clientID] = session
                return sessions[clientID]!
            }
        }
        println("Creating a new session with: \(clientID)")
        sessions[clientID] = ProxiSession(s: MCSession(peer: peer))
        sessions[clientID]!.session.delegate = self
        return sessions[clientID]!
    }
    
    func unarchiveSavedItems() {
        if NSFileManager.defaultManager().fileExistsAtPath(sessionArchivePath) {
            let keys = NSKeyedUnarchiver.unarchiveObjectWithFile(sessionArchivePath) as! [String]
            for k in keys {
                sessions[k] = ProxiSession(s: newOrGetSession(k).session)
            }
        }
        
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        isVisible = true
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isVisible = false
    }
    
    // MARK: MCNearbyServiceBrowserDelegate method implementation
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        foundPeers.append(peerID)
        if(peer.displayName == peerID.displayName) {
            println("I am not connecting myself :D")
            return
        }
        if(sessions[peerID.displayName] != nil) {
            println("Recent peer is range, trying to reconnect (\(peerID.displayName))...")
            browser.invitePeer(peerID, toSession: newOrGetSession(peerID.displayName).session, withContext: nil, timeout: 20)
        }

        delegate?.foundPeer()
    }
    
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        for (index, aPeer) in enumerate(foundPeers){
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        
        delegate?.lostPeer()
    }
    
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println(error.localizedDescription)
    }
    
    
    // MARK: MCNearbyServiceAdvertiserDelegate method implementation
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        self.invitationHandler = invitationHandler
        if(ifExistSession(peerID.displayName)) {
            self.invitationHandler(true, self.newOrGetSession(peerID.displayName).session)
        } else {
            delegate?.invitationWasReceived(peerID.displayName)
        }
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println(error.localizedDescription)
    }
    
    
    // MARK: MCSessionDelegate method implementation
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        if(getDisplayNameFromID(self.peer.displayName) != getDisplayNameFromID(peer.displayName)) {
            newOrGetSession(peer.displayName).state = state
        }
        println("Changing session table state to: \(state.rawValue)")
        switch state{
        case MCSessionState.Connected:
            currentSession = session
            println("Connected to session: \(session)")
            dispatch_async(dispatch_get_main_queue(), {
                JDStatusBarNotification.showWithStatus("connected with \(getHandle(peer))", dismissAfter: NSTimeInterval(2), styleName: "JDStatusBarStyleSuccess")
            })
            delegate?.connectedWithPeer(peerID)
            
        case MCSessionState.Connecting:
            println("Connecting to session: \(session)")
            
        default:
            println("Did not connect to session: \(session)")
            dispatch_async(dispatch_get_main_queue(), {
                JDStatusBarNotification.showWithStatus("disconnected with \(getHandle(peer))", dismissAfter: NSTimeInterval(2), styleName: "JDStatusBarStyleError")
            })
        }
        NSKeyedArchiver.archiveRootObject(sessions.keys.array, toFile: sessionArchivePath)
    }
    
    func ifExistSession(peerID: String) -> Bool {
        let keys = sessions.keys.array
        for key in keys {
            if(getDisplayNameFromID(peerID) == getDisplayNameFromID(key)) {
                return true
            }
        }
        return false
    }
    
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let dictionary: [String: AnyObject] = ["data": data, "fromPeer": peerID, "session": session]
        println("MPCManager : recieved message")
        NSNotificationCenter.defaultCenter().postNotificationName("receivedMPCDataNotification", object: dictionary)
    }
    
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) { }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) { }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) { }
    
    
    
    // MARK: Custom method implementation
    
    func sendData(dictionaryWithData dictionary: Dictionary<String, String>, toPeer targetPeer: MCPeerID) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        let peersArray = NSArray(object: targetPeer)
        var error: NSError?
        
        if !currentSession.sendData(dataToSend, toPeers: peersArray as [AnyObject], withMode: MCSessionSendDataMode.Reliable, error: &error) {
            println(error?.localizedDescription)
            return false
        }
        
        return true
    }
    
}
