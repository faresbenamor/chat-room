//
//  ViewController.swift
//  testSocket1
//
//  Created by mac on 15/04/2021.
//

import UIKit
import Foundation
import SocketIO

class ViewController: UIViewController {
    
    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var photoUser: UIImageView!
    let userDef = UserDefaults.standard
    let socket = SocketIOManager.sharedInstance.socket

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        photoUser.layer.borderWidth = 3
        photoUser.layer.borderColor = UIColor.black.cgColor
        photoUser.layer.cornerRadius = photoUser.frame.size.width / 2
        photoUser.clipsToBounds = true
        
        // bech yetnaha el clavier ki tenzel aal ecran
        hideKeyboardWhenTappedAround()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        // if user is connected go directly to Chat
        if userDef.bool(forKey: "isLoggedIn") == true {
            SocketIOManager.sharedInstance.connectSocket {
                (success) -> Void in
                if success {
                    self.socket?.emit("add user", self.userDef.value(forKey: "nom") as! SocketData)
                   self.performSegue(withIdentifier: "toChat", sender: self)
                }
                else {
                    let alert = UIAlertController(title: "Alert", message: "Could not connect to server !", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    

    @IBAction func clickAction(_ sender: UIButton) {
        SocketIOManager.sharedInstance.connectSocket {
            (success) -> Void in
            if success {
                self.socket?.emit("add user", self.tf.text!)
                self.userDef.setValue(self.tf.text, forKey: "nom")
                self.userDef.setValue(self.photoUser.image?.jpegData(compressionQuality: 0.1), forKey: "photo")
                self.userDef.set(true, forKey: "isLoggedIn")
                self.performSegue(withIdentifier: "toChat", sender: self)
                }
            else {
                let alert = UIAlertController(title: "Alert", message: "Could not connect to server !", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    
    @IBAction func importerAction(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
}

    /// UIImagePickerDelegate
    extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        photoUser.image = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

