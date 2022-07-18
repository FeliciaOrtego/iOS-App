//
//  GWSChatAudioRecordViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/06/21.
//

import AVKit
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct kAudioRecordingConfig {
    static let kAudioMessageTimeLimit: TimeInterval = 59.0
}

class GWSChatAudioRecordViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var timerString: String = "0:00"
    @Published var isRecordStarted: Bool = false
    @Binding var showRecordView: Bool
    @Binding var showLoader: Bool

    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?

    var audioRecordingTimeLeft: Double = 0.0
    var audioRecordingTimer: Timer?
    var isSendingMedia = false

    private let storage = Storage.storage().reference()
    var channel: GWSChatChannel
    var user: GWSUser?
    private var reference: CollectionReference?
    private let db = Firestore.firestore()

    init(user: GWSUser?, channel: GWSChatChannel, showRecordView: Binding<Bool>, showLoader: Binding<Bool>) {
        self.user = user
        self.channel = channel
        _showRecordView = showRecordView
        _showLoader = showLoader
        reference = db.collection(["channels", channel.id, "thread"].joined(separator: "/"))
    }

    func startAudioRecord() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                        self.audioRecordingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.onTimerFires), userInfo: nil, repeats: true)
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }

    private func startRecording() {
        audioRecordingTimeLeft = 0.0
        let audioFilename = documentDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            finishRecording(success: false)
        }
    }

    func sendAudioRecord() {
        timerString = "0:00"
        if let audioRecordingTimer = audioRecordingTimer {
            stopTimer(audioRecordingTimer)
        }
        finishRecording(success: true)
    }

    func cancelAudioRecord() {
        timerString = "0:00"
        if let audioRecordingTimer = audioRecordingTimer {
            stopTimer(audioRecordingTimer)
        }
        finishRecording(success: false)
    }

    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil

        showRecordView = false
        guard let user = user else {
            return
        }
        if success {
            let audioFileUrl = documentDirectory().appendingPathComponent("recording.m4a")
            isSendingMedia = true
            uploadMediaMessage(audioFileUrl, to: channel) { [weak self] url in

                guard let self = self else {
                    return
                }
                self.isSendingMedia = false

                guard let url = url else {
                    return
                }

                let asset = AVURLAsset(url: audioFileUrl, options: nil)
                let audioDuration = asset.duration
                let audioDurationSeconds = CMTimeGetSeconds(audioDuration)

                let message = GWShatMessage(user: user, audioURL: url, audioDuration: Float(audioDurationSeconds))
                message.audioDownloadURL = url
                self.save(message, user: self.user, channel: self.channel)
            }
        }
    }

    @objc func onTimerFires() {
        audioRecordingTimeLeft += 1.0

        let currentTime = Int(audioRecordingTimeLeft)
        let minutes = currentTime / 60
        let seconds = currentTime - minutes * 60

        timerString = String(format: "%2d:%02d", minutes, seconds)

        if audioRecordingTimeLeft >= kAudioRecordingConfig.kAudioMessageTimeLimit {
            if let audioRecordingTimer = audioRecordingTimer {
                stopTimer(audioRecordingTimer)
            }
        }
    }

    func stopTimer(_ timer: Timer) {
        timer.invalidate()
    }

    func documentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }

    private func uploadMediaMessage(_ url: URL, to channel: GWSChatChannel, completion: @escaping (URL?) -> Void) {
        showLoader = true

        let fileName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        storage.child(channel.id).child(fileName).putFile(from: url, metadata: nil) { meta, _ in
            self.showLoader = false
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }

    private func save(_ message: GWShatMessage, allTagUsers: [String] = [], user: GWSUser?, channel: GWSChatChannel) {
        reference?.addDocument(data: message.representation) { [weak self] error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            guard let self = self else { return }

            let channelRef = Firestore.firestore().collection("channels").document(self.channel.id)
            var lastMessage = ""
            switch message.kind {
            case let .text(text), let .inReplyToItem((_, text)):
                lastMessage = text
            case let .attributedText(text):
                lastMessage = text.fetchAttributedText(allTagUsers: allTagUsers)
            case .audio:
                lastMessage = "Someone sent an audio message.".localizedChat
            case .photo:
                lastMessage = "Someone sent a photo.".localizedChat
            case .video:
                lastMessage = "Someone sent a video.".localizedChat
            default:
                break
            }
            let newData: [String: Any] = [
                "lastMessageDate": Date(),
                "lastMessage": lastMessage,
                "lastMessageSeeners": [],
            ]
            channelRef.setData(newData, merge: true)
            self.updateChannelParticipationIfNeeded(channel: channel)
            self.sendOutPushNotificationsIfNeeded(message: message, user: user, channel: channel)
        }
    }

    private func sendOutPushNotificationsIfNeeded(message: GWShatMessage, user: GWSUser?, channel: GWSChatChannel) {
        var lastMessage = ""
        let senderName = user?.firstName ?? "Someone"
        switch message.kind {
        case let .text(text):
            lastMessage = text
        case let .attributedText(text):
            lastMessage = text.string
        case .photo:
            lastMessage = "\(senderName) sent you a photo."
        case .audio:
            lastMessage = "\(senderName) sent you an audio message."
        case .video:
            lastMessage = "\(senderName) sent you a video message."
        default:
            break
        }

        let notificationSender = GWSPushNotificationSender()
        channel.participants.forEach { recipient in
            if let token = recipient.pushToken, recipient.uid != user?.uid {
                notificationSender.sendPushNotification(token: token,
                                                        title: user?.firstName ?? "Instachatty",
                                                        body: lastMessage,
                                                        notificationType: .chatAppNewMessage,
                                                        payload: ["channelId": channel.id])
            }
        }
    }

    func updateChannelParticipationIfNeeded(channel: GWSChatChannel) {
        if channel.participants.count != 2 {
            return
        }
        guard let uid1 = channel.participants.first?.uid, let uid2 = channel.participants[1].uid else { return }
        updateChannelParticipationIfNeeded(channel: channel, uID: uid1)
        updateChannelParticipationIfNeeded(channel: channel, uID: uid2)
    }

    private func updateChannelParticipationIfNeeded(channel: GWSChatChannel, uID: String) {
        let ref1 = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uID).whereField("channel", isEqualTo: channel.id)
        ref1.getDocuments { querySnapshot, _ in
            if querySnapshot?.documents.count == 0 {
                let data: [String: Any] = [
                    "user": uID,
                    "channel": channel.id,
                ]
                Firestore.firestore().collection("channel_participation").addDocument(data: data, completion: nil)
            }
        }
    }
}
