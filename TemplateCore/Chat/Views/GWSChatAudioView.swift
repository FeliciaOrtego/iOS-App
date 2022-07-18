//
//  GWSChatAudioView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/06/21.
//

import AVKit
import SwiftUI

struct GWSChatAudioView: View {
    @ObservedObject var viewModel: GWSChatAudioViewModel
    var appConfig: GWSConfigurationProtocol
    var isFromSender: Bool

    init(message: GWSChatMessage, isFromSender: Bool, appConfig: GWSConfigurationProtocol) {
        viewModel = GWSChatAudioViewModel(message: message)
        self.isFromSender = isFromSender
        self.appConfig = appConfig
        if !viewModel.message.isAudioDownloading, !viewModel.message.isAudioDownloaded {
            if let audioDownloadURL = viewModel.message.audioDownloadURL {
                viewModel.downloadAudioFileFromURL(url: audioDownloadURL)
            }
        }
    }

    var body: some View {
        HStack {
            if viewModel.message.isAudioDownloaded {
                if self.viewModel.isSelected {
                    Button(action: {
                        self.viewModel.isSelected = false
                        self.viewModel.pauseAudioChat()
                    }) {
                        Image("pause")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(isFromSender ? Color.white : Color(appConfig.mainTextColor))
                    }
                } else {
                    Button(action: {
                        self.viewModel.isSelected = true
                        if !self.viewModel.message.isAudioDownloading, !self.viewModel.message.isAudioDownloaded {
                            if let audioDownloadURL = self.viewModel.message.audioDownloadURL {
                                self.viewModel.downloadAudioFileFromURL(url: audioDownloadURL)
                            }
                        } else if self.viewModel.message.isAudioDownloaded {
                            self.viewModel.playAudioChat()
                        }
                    }) {
                        Image("play")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(isFromSender ? Color.white : Color(appConfig.mainTextColor))
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isFromSender ? Color.white : Color(appConfig.mainTextColor)))
                    .padding(.horizontal, 4)
            }
            Slider(value: $viewModel.sliderValue, in: 0 ... Double(viewModel.currentAudioMessageDuration))
                .accentColor(isFromSender ? Color.white : Color(appConfig.mainTextColor))
                .frame(width: 120)
                .disabled(true)
            Text(viewModel.audioDurationText)
                .foregroundColor(isFromSender ? Color.white : Color(appConfig.mainTextColor))
        }
    }
}
