//
//  ChatListDataCell.swift
//  Proxi
//
//  Created by Siyuan Gao on 4/20/15.
//  Copyright (c) 2015 Siyuan Gao. All rights reserved.
//

import Foundation
import UIKit
import SWTableViewCell

class ChatListDataCell: SWTableViewCell {
    @IBOutlet weak var peerName: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var peerID: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
}