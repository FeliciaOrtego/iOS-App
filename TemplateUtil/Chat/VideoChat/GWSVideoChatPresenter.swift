//
//  GWSVideoChatPresenter.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mac  on 05/12/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore
import UIKit

public enum GWSCallType {
    case video
    case audio

    var rawValue: String {
        switch self {
        case .video: return "video"
        case .audio: return "audio"
        }
    }
}

protocol GWSAudioVideoChatPresenterProtocol: AnyObject {
    func startCall(in viewController: UIViewController, chatType: GWSCallType, channel: GWSChatChannel, user: GWSUser, otherUser: GWSUser?) -> Void
}

class GWSAudioVideoChatPresenter: GWSAudioVideoChatPresenterProtocol {
    func startCall(in viewController: UIViewController, chatType: GWSCallType, channel: GWSChatChannel, user: GWSUser, otherUser: GWSUser?) {
        receiverids.removeAll()
        if channel.participants.count > 2 {
            var allReceivers: [String] = []
            for channelUsers in channel.participants {
                if let userID = channelUsers.uid {
                    allReceivers.append(userID)
                }
            }
            for channelUsers in channel.participants {
                if let userID = channelUsers.uid {
                    if userID != user.uid {
                        Firestore.firestore().collection("users").document(userID).collection("call_data").addDocument(data: [
                            "callStatus": "Receiving",
                            "groupCall": true,
                            "callerID": user.uid ?? "",
                            "receiverIDs": allReceivers,
                            "callerName": user.fullName(),
                            "callType": chatType.rawValue,
                            "callerProfilePictureURL": user.profilePictureURL ?? "",
                        ])
                        receiverids.append(userID)
                        otherreceiverid = userID
                    }
                }
            }
            let vc = GWSCallingViewController()
            vc.isModalInPresentation = true
            vc.isIncomingCall = false
            vc.chatType = chatType
            callerName = otherUser?.fullName() ?? ""
            callerProfilePictureURL = otherUser?.profilePictureURL ?? ""
            senderid = user.uid ?? ""
            isGroupCall = true
            viewController.present(vc, animated: true, completion: nil)
        } else {
            if let otherUserID = otherUser?.uid {
                Firestore.firestore().collection("users").document(otherUserID).collection("call_data").addDocument(data: [
                    "callStatus": "Receiving",
                    "groupCall": false,
                    "callerID": user.uid ?? "",
                    "callerName": user.fullName(),
                    "callType": chatType.rawValue,
                    "callerProfilePictureURL": user.profilePictureURL ?? "",
                ])
                receiverids.append(otherUserID)
                let vc = GWSCallingViewController()
                vc.isModalInPresentation = true
                vc.isIncomingCall = false
                vc.chatType = chatType
                otherreceiverid = otherUser?.uid ?? ""
                callerName = otherUser?.fullName() ?? ""
                callerProfilePictureURL = otherUser?.profilePictureURL ?? ""
                senderid = user.uid ?? ""
                viewController.present(vc, animated: true, completion: nil)
            }
        }
        if let userID = user.uid {
            let pkScheduler = GWSPushKitNotificationScheduler()
            pkScheduler.schedulePKNotifications(callerID: userID, recipientsIDs: receiverids, callType: chatType.rawValue, channelID: channel.id, channelName: channel.name)
        }
    }
}
