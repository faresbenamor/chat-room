//
//  MessageWS.swift
//  testSocket1
//
//  Created by mac on 16/06/2021.
//

import Foundation
import UIKit
import MessageKit

struct KindMessage : Codable {
    var text : String
}

struct SenderMessage : SenderType, Codable {
    var senderId: String
    var displayName: String
}

struct MessageWS : Codable {
    var sender: SenderMessage
    var messageId: String
    var sentDate: String
    var photo: String
    var kind : KindMessage
}
