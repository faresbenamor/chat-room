//
//  SocketIOManager.swift
//  testSocket1
//
//  Created by mac on 16/04/2021.
//

import Foundation
import SocketIO

class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    
    // MARK: - Properties
    let manager = SocketManager(socketURL: URL(string :"http://localhost:3000")!, config: [.log(false), .compress, .reconnects(true)])
    var socket: SocketIOClient!
    
    // MARK: - Life Cycle
    override init() {
            super.init()
        socket = manager.defaultSocket
    }
    
    
    func connectSocket(completion: @escaping (_ success: Bool) -> Void) {
        socket.on(clientEvent: .connect) { (data, ack) in
               print("socket connected")
               completion(true) // el fonction tekmel houny
                }
        
        socket.on(clientEvent: .error) { (data, ack) in
               print("could not connect to server")
               print(data)
               completion(false)
                }
        
        socket.connect()
    }
    
    func closeConnection() {
        socket.removeAllHandlers()
        socket.disconnect()
        print("socket disconnected")
    }
    
}
