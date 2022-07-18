//
//  GWSChatAudioViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/06/21.
//

import AVKit
import FirebaseStorage
import SwiftUI

class GWSChatAudioViewModel: ObservableObject {
    @Published var isSelected: Bool = false
    @Published var audioPlayingTimeUpdater: CADisplayLink? = nil
    @Published var audioDownloadTask: StorageDownloadTask?
    var currentAudioMessageDuration: Float = 0.0
    @Published var sliderValue: Double = 0
    @ObservedObject var message: GWSChatMessage
    @Published var audioDurationText: String = ""

    init(message: GWSChatMessage) {
        self.message = message
        currentAudioMessageDuration = message.audioDuration ?? 0.0
        audioDurationText = audioProgressTextFormat(currentAudioMessageDuration)
    }

    func downloadAudioFileFromURL(url: URL) {
        message.isAudioDownloading = true

        let storage = Storage.storage()
        storage.reference(forURL: url.absoluteString).downloadURL { url, error in
            guard let url = url else {
                return
            }

            let storeRef = Storage.storage().reference(forURL: url.absoluteString)
            let audioDownloadTask = storeRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                self.message.isAudioDownloading = false
                if let error = error {
                    print(error)
                } else {
                    if let d = data {
                        do {
                            self.message.objectWillChange.send()
                            self.message.audioPlayer = try AVAudioPlayer(data: d, fileTypeHint: AVFileType.mp3.rawValue)
                            self.message.isAudioDownloaded = true
                            if self.isSelected {
                                self.playAudioChat()
                            }
                        } catch let error as NSError {
                            // self.player = nil
                            print(error.localizedDescription)
                            self.message.isAudioDownloaded = false
                        } catch {
                            print("AVAudioPlayer init failed")
                            self.message.isAudioDownloaded = false
                        }
                    }
                }
            }
            self.audioDownloadTask = audioDownloadTask
        }
    }

    func playAudioChat() {
        audioConfig()
        message.audioPlayer?.play()
        startUpdateAudioPlayingTime()
    }

    func pauseAudioChat() {
        message.audioPlayer?.pause()
        stopUpdateAudioPlayingTime()
    }

    fileprivate func audioConfig() {
        // Play sound in Video when device is on RINGER mode and SLIENT mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print(error.localizedDescription)
        }
    }

    func startUpdateAudioPlayingTime() {
        audioPlayingTimeUpdater = CADisplayLink(target: self, selector: #selector(trackAudio))
        audioPlayingTimeUpdater?.preferredFramesPerSecond = 1
        audioPlayingTimeUpdater?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }

    @objc func trackAudio() {
        if message.audioPlayer?.isPlaying ?? false {
            sliderValue = message.audioPlayer?.currentTime ?? 0.1
            audioDurationText = audioProgressTextFormat(Float(sliderValue))
        } else {
            sliderValue = 0
            audioDurationText = audioProgressTextFormat(currentAudioMessageDuration)
            isSelected = false
            stopUpdateAudioPlayingTime()
        }
    }

    func stopUpdateAudioPlayingTime() {
        audioPlayingTimeUpdater?.invalidate()
    }

    func audioProgressTextFormat(_ duration: Float) -> String {
        var retunValue = "0:00"
        // print the time as 0:ss if duration is up to 59 seconds
        // print the time as m:ss if duration is up to 59:59 seconds
        // print the time as h:mm:ss for anything longer
        if duration < 60 {
            retunValue = String(format: "0:%.02d", Int(duration.rounded(.up)))
        } else if duration < 3600 {
            retunValue = String(format: "%.02d:%.02d", Int(duration / 60), Int(duration) % 60)
        } else {
            let hours = Int(duration / 3600)
            let remainingMinutsInSeconds = Int(duration) - hours * 3600
            retunValue = String(format: "%.02d:%.02d:%.02d", hours, Int(remainingMinutsInSeconds / 60), Int(remainingMinutsInSeconds) % 60)
        }
        return retunValue
    }
}
