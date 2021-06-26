//
//  API_Manager.swift
//  testSocket1
//
//  Created by mac on 15/06/2021.
//

import UIKit
import Alamofire
import MessageKit

class API_Manager: NSObject {
    
    let URL_MESSAGE_ADD = "http://localhost:3000/messages/add"
    static let sharedInstance = API_Manager()
    
    func apiAddMessage(senderId : String, displayName : String, sentDate : String, photo : String, text : String) {
        
        let headers: HTTPHeaders = [.contentType("application/json")]
        let parameters: Parameters = [
                    "senderId": senderId,
                    "displayName": displayName,
                    "sentDate": sentDate,
                    "photo": photo,
                    "text": text
                    ]
        
        
    //Sending http post request
    AF.request(URL_MESSAGE_ADD, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler:
                    {
                        response in
                    
                    switch response.result {
                    case .success(let value) :

     if let JSON = value as? Dictionary<String, Any>{
    
         let status = JSON["success"] as! Int

      if status == 1 {
                   print("message added !")
                    }
    
                else {
                print("failed !")
                    }
    
                }
                    
                    case .failure(let err) :
                        print(err)
                    }
                     
                })
    } // apiAdd

    
    func apiGetMessages(messagesCollectionView : UICollectionView,  messageArrayWS : UnsafeMutablePointer<[MessageWS]>, completion: @escaping (_ success: Bool) -> Void) {
        
        guard let url = URL(string: "http://localhost:3000/messages") else {return}
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return }
            
            //decoding from JSON to model
            do {
                //here dataResponse received from a network request
            let decoder = JSONDecoder()
                let model = try decoder.decode([MessageWS].self, from:dataResponse) //Decode JSONResponseData
                messageArrayWS.pointee = model
                
                completion(true)
                
                DispatchQueue.main.async{
                    messagesCollectionView.reloadData()
            }
                
            } catch let parsingError {
                print("Error", parsingError)
                completion(false)
            }
        }
        task.resume()
        
        messagesCollectionView.reloadData()
    }
    
} // Class
