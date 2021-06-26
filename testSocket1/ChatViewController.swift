//
//  ChatViewController.swift
//  testSocket1
//
//  Created by mac on 23/04/2021.
//

import UIKit
import MessageKit
import Alamofire
import InputBarAccessoryView


class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {
    
    @IBOutlet weak var onlineUsersView: UIView!
    @IBOutlet weak var onlineUsersLabel: UILabel!
    @IBOutlet weak var joinedUserView: UIView!
    @IBOutlet weak var joinedUserLabel: UILabel!
    
    var currentUser : Sender?
    var checkSender : Sender?
    let socket = SocketIOManager.sharedInstance.socket
    let userDef = UserDefaults.standard
    var pseudoUser = ""
    var isCurrentUserTyping = true
    var photoCurrentUser : UIImage?
    var messagesArrayWS = [MessageWS]()
    var messages = [MessageType]()
    var lastDisplayedSentDate: Date?
    var imageCache = NSCache<NSString, UIImage>() // el key wel value makloubin

    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        messagesCollectionView.addSubview(onlineUsersView)
        messagesCollectionView.addSubview(joinedUserView)
        joinedUserView.layer.cornerRadius = 20
        messagesCollectionView.contentInset.top = 40 // hedhy bech taamel ecart mel fouk

        pseudoUser = userDef.value(forKey: "nom") as! String
        let imageFromData = UIImage(data: userDef.value(forKey: "photo") as! Data)
        photoCurrentUser = imageFromData
        currentUser = Sender(senderId: "self", displayName: pseudoUser)
        
        // Setup
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.backgroundColor = .white
        showMessageTimestampOnSwipeLeft = true

        // Input text and send button design
        messageInputBar.delegate = self
        messageInputBar.sendButton.title = "Send"
        messageInputBar.sendButton.setTitleColor(.orange, for: .normal)
        messageInputBar.inputTextView.tintColor = .orange
        messageInputBar.inputTextView.placeholder = "Your Message..."
        messageInputBar.inputTextView.textColor = .orange
        
        
        API_Manager.sharedInstance.apiGetMessages(messagesCollectionView: messagesCollectionView, messageArrayWS: &messagesArrayWS, completion: {
                (success) -> Void in
                       if success {
                           self.exchangeArrays()
                           self.savePhotosToCache()
                       }
        })
        
        socket?.on("new message") { (data,ack) in
            guard let dataInfo = data.first else {return}
            if  let JSON = dataInfo as? Dictionary<String, Any> {

                let message = JSON["message"]
                let username = JSON["username"] as? String
                let date = JSON["date"] as? String
                let photo = JSON["photo"] as! Data
                
                let photoFromData = UIImage(data: photo)
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeStyle = .short
                formatter.dateStyle = .medium
                let dateFormatted = formatter.date(from: date!)
                
                if username == self.pseudoUser {
                    self.checkSender = self.currentUser!
                } else {
                    self.checkSender = Sender(senderId: "other", displayName: username!)
                    
                    if self.imageCache.object(forKey: username! as NSString) == nil {
                       self.imageCache.setObject(photoFromData!, forKey: username! as NSString)
                    }
                }

            self.messages.append(Message(sender: self.checkSender!,
                                    messageId: "4",
                                    sentDate: dateFormatted!,
                                    kind: .text("\(message!)")
            ))
            self.messagesCollectionView.reloadData() // Reload the collectionView after sending/receiving a message
            self.messagesCollectionView.scrollToLastItem() // Scroll to last item after sending/receiving a message
            }
        } // Socket.on("new message")
        
        
        socket?.on("all users") { (data,ack) in
            guard let dataInfo = data.first else {return}
            self.onlineUsersLabel.text = "Total of \(dataInfo) users online"
        }
        
        socket?.on("user joined") { (data,ack) in
            guard let dataInfo = data.first else {return}
            self.joinedUserView.isHidden = false
            self.joinedUserLabel.text = "\(dataInfo) joined ..."
            
            UIView.animate(withDuration: 5,
                           animations: {
                            self.joinedUserView.alpha = 0
                           }, completion: { _ in
                            self.joinedUserView.isHidden = true
                            self.joinedUserView.alpha = 1
                           }
            )
        } // Socket.on("user joined")
        
        socket?.on("isTyping") { (data,ack) in
            guard let dataInfo = data.first else {return}
            if  let JSON = dataInfo as? Dictionary<String, Any> {
            let message = JSON["message"] as? String
            let username = JSON["username"] as? String
                
            if username == self.pseudoUser {
                self.isCurrentUserTyping = true
            } else {
                self.isCurrentUserTyping = false
            }
            if !self.isCurrentUserTyping {
                if message != "" {
                    self.setTypingIndicatorViewHidden(false, animated: true)
                    
                    // don't scroll to last item if the user is reading an old message
                    if self.isLastSectionVisible() {
                    self.messagesCollectionView.scrollToLastItem()
                    }
                }
                else {
                    self.setTypingIndicatorViewHidden(true, animated: true)
                }
            }
          } // JSON
        } // Socket.on("isTyping")
        
    } // ViewDidLoad
    
    @IBAction func logoutAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Alert", message: "Logout ?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            SocketIOManager.sharedInstance.closeConnection()
            self.userDef.set(false, forKey: "isLoggedIn")
            self.performSegue(withIdentifier: "toLogin", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func currentSender() -> SenderType {
        return currentUser!
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // bech maatech tecrashi ki nabaath msg wel app fel background
        if indexPath.section >= messages.startIndex && indexPath.section < messages.endIndex {
            return messages[indexPath.section]
        }
        
//        if messages.indices.contains(indexPath.section) {
//            return messages[indexPath.section]
//        }
        
        else {
            return Message(sender: Sender(senderId: "4", displayName: "Fares"),
                           messageId: "4",
                           sentDate: Date().addingTimeInterval(-7005),
                           kind: .text("feragh"))
        }
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // Send message action
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let currentDate = Date()
        let formatter2 = DateFormatter()
        //formatter2.dateFormat = "yyyy-MM-dd hh:mm:ss"
        formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let todayDateJSON = formatter2.string(from: currentDate)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        let todayDate = formatter.string(from: currentDate) // Apr 28, 2021 at 1:30 PM
        
        let photoCurrentUserString = photoCurrentUser?.jpegData(compressionQuality: 0.1)
        let photoBase64 = photoCurrentUser?.ImagetoString()
        
        let userInfo : [String : Any] = [
            "message" : text,
            "date" : todayDate,
            "photo" : photoCurrentUserString!
        ]
        socket?.emit("new message", userInfo)
        API_Manager.sharedInstance.apiAddMessage(senderId: currentSender().senderId, displayName: currentSender().displayName, sentDate: todayDateJSON, photo: photoBase64!, text: text)
        messageInputBar.inputTextView.text = ""
    }
    
    // While texting
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        let userInfo : [String : Any] = [
            "message" : text,
            "username" : pseudoUser
        ]
        socket?.emit("typing", userInfo)
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return .blue
        }
        else {
            return .orange
        }
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .white
    }
    
    // Photo of user
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        if message.sender.displayName == pseudoUser {
            avatarView.image = photoCurrentUser?.withRenderingMode(.alwaysOriginal)
        }
         else {
                let imageFromCache = imageCache.object(forKey: message.sender.displayName as NSString)
                avatarView.image = imageFromCache
          }
    }
    
    // hedhy lezem thotha bech yjik el esm mel fouk
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 35
    }
    
    // Display name of sender on top of the message
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor(white: 0.3, alpha: 1)
          ]
        )
    }
    
    // hedhy lezem thotha bech yjik el date mel fouk
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 35
    }
    
    // Display date of the message on top of the cell
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if let lastDisplayedSentDate = lastDisplayedSentDate, Calendar.current.isDate(lastDisplayedSentDate, inSameDayAs: message.sentDate) && (indexPath.section > 0) {
            return nil
        }
        lastDisplayedSentDate = message.sentDate
        let date = message.sentDate
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium // Apr 28, 2021 at 1:30 PM
        return NSAttributedString(string: dateFormatter.string(from: date), attributes:[.font:UIFont.preferredFont(forTextStyle:.caption1), .foregroundColor: UIColor(white: 0.3, alpha: 1)])
    }
    
    // Display Time of the message when Swiping left
    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let date = message.sentDate
        let dateFormatter = DateFormatter()
    //  dateFormatter.amSymbol = "am" // ken thebha el am wala pm minuscule
        dateFormatter.dateFormat = "HH:mm a" // el a edhika bech tzidlek AM/PM felekher
        return NSAttributedString(string: dateFormatter.string(from: date), attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor(white: 0.3, alpha: 1)
          ]
        )
    }
    
    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    
    func exchangeArrays() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        for i in 0..<messagesArrayWS.count {
            let date = messagesArrayWS[i].sentDate
            guard let formattedDate = dateFormatter.date(from: date) else { return  }
            
            if messagesArrayWS[i].sender.displayName == pseudoUser {
                messagesArrayWS[i].sender.senderId = "self"
            }
            else {
                messagesArrayWS[i].sender.senderId = "other"
            }
            
            messages.append(Message(sender: messagesArrayWS[i].sender,
                                    messageId: messagesArrayWS[i].messageId,
                                    sentDate: formattedDate,
                                    kind: .text(messagesArrayWS[i].kind.text)
            ))
        }
    }
    
    func savePhotosToCache() {
        for i in 0..<messagesArrayWS.count {
            
            if imageCache.object(forKey: messagesArrayWS[i].sender.displayName as NSString) == nil {
                guard let imageData = messagesArrayWS[i].photo.StringtoImage() else { return }
                imageCache.setObject(imageData, forKey: messagesArrayWS[i].sender.displayName as NSString)
            }
        }
    }
    
} // Class
