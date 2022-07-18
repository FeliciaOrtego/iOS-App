//
//  GWSChatMessage.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/04/21.
//

import AVKit
import SwiftUI

class GWSChatMessage: GWShatMessage, ObservableObject, Identifiable {
    @Published var downloadURLCompleted: Bool = false
    @Published var isAudioDownloaded: Bool = false
    @Published var isAudioDownloading: Bool = false
    @Published var audioPlayer: AVAudioPlayer? = nil
}
