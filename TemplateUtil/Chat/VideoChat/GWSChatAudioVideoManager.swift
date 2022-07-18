//
//  GWSChatAudioVideoManager.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mac  on 15/12/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore
import UIKit

let kGWSAudioVideoCallAnswerNotification = Notification.Name("kGWSAudioVideoCallAnswerNotification")

class GWSChatAudioVideoManager {
    var observerSignalRef: DocumentReference?
    var signalListener: ListenerRegistration?

    public static let shared = GWSChatAudioVideoManager()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeSignal), name: kLogoutNotificationName, object: nil)
    }

    func observerSignal(forUser user: GWSUser) {
        if let userID = user.uid {
            observerSignalRef = Firestore.firestore().collection("users").document(userID)
            clearPreviousCallStatus()
            signalListener = observerSignalRef?.collection("call_data").addSnapshotListener { [weak self] snapshot, error in

                guard let snapshot = snapshot else {
                    print("Error listening for users: \(error?.localizedDescription ?? "No error")")
                    return
                }

                snapshot.documentChanges.forEach { change in
                    let responseData = change.document.data()
                    let type = responseData["callStatus"] as? String

                    if type == "Accepted" || type == "Rejected" {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: kGWSAudioVideoCallAnswerNotification, object: nil, userInfo: responseData)
                        }
                        self?.clearPreviousCallStatus()
                    } else if type == "Receiving" {
                        otherreceiverid = responseData["callerID"] as? String ?? ""
                        callerName = responseData["callerName"] as? String ?? ""
                        callerProfilePictureURL = responseData["callerProfilePictureURL"] as? String ?? ""
                        senderid = userID
                        let groupCall = responseData["groupCall"] as? Bool
                        isGroupCall = groupCall ?? false
                        let callType = responseData["callType"] as? String
                        let receiverIDs = responseData["receiverIDs"] as? [String]
                        receiverids.removeAll()
                        if isGroupCall {
                            if let receiverIDs = receiverIDs {
                                receiverids = receiverIDs.filter { $0 != senderid }
                            }
                        } else {
                            receiverids.append(otherreceiverid)
                        }
                        DispatchQueue.main.async {
                            if !(GWSHostViewController.topViewController() is GWSCallingViewController) {
                                let vc = GWSCallingViewController()
                                vc.isModalInPresentation = true
                                vc.isIncomingCall = true
                                if let callType = callType {
                                    if callType == GWSCallType.audio.rawValue {
                                        vc.chatType = .audio
                                    } else {
                                        vc.chatType = .video
                                    }
                                }
                                GWSHostViewController.topViewController()?.present(vc, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }

    func clearPreviousCallStatus() {
        observerSignalRef?.collection("audiochat").getDocuments(completion: { querySnapshot, _ in
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    document.reference.delete()
                }
            }
        })
        observerSignalRef?.collection("call_data").getDocuments(completion: { querySnapshot, _ in
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    document.reference.delete()
                }
            }
        })
    }

    @objc private func removeSignal() {
        if let signalListener = signalListener {
            signalListener.remove()
            self.signalListener = nil
        }
    }
}
