//
//  Extensions.swift
//  testSocket1
//
//  Created by mac on 12/05/2021.
//

import Foundation
import UIKit

// hedhy bech yetnaha el clavier mtaa el input ki tenzel aal ecran w fi ay view controller
extension UIViewController {

func hideKeyboardWhenTappedAround() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
    //tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
}

@objc func dismissKeyboard() {
    view.endEditing(true)
}
    
}


//hedhy bech tconverti image lel string
extension UIImage {
    func ImagetoString() -> String? {
        let data: Data? = self.jpegData(compressionQuality: 0.1)
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}


//convert string to image
extension String {
    func StringtoImage() -> UIImage? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data)
        }
        return nil
    }
}
