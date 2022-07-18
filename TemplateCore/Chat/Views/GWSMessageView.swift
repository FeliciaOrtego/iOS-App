//
//  GWSMessageView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 26/04/21.
//

import FirebaseStorage
import SwiftUI

struct GWSMessageView: View {
    var viewer: GWSUser? = nil
    @ObservedObject var message: GWSChatMessage
    @Binding var isShowVideoPlayer: Bool
    @Binding var isShownSheet: Bool
    @Binding var videoDownloadURL: URL?
    var appConfig: GWSConfigurationProtocol
    @State private var isImageClicked = false

    var background: some View {
        if message.sender.senderId == viewer?.uid {
            return Color(appConfig.mainThemeForegroundColor)
        } else {
            return Color(appConfig.grey1)
        }
    }

    var body: some View {
        HStack(alignment: VerticalAlignment.bottom) {
            if message.sender.senderId == viewer?.uid {
                Spacer()
            } else {
                if let urlString = message.atcSender.profilePictureURL {
                    GWSNetworkImage(imageURL: URL(string: urlString)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 25, height: 25)
                        .padding([.leading, .bottom], 4)
                }
            }

            switch message.kind {
            case let .photo(mediaItem):
                if message.downloadURLCompleted {}
                if let downloadURL = message.downloadURL, message.downloadURLCompleted {
                    GWSNetworkImage(imageURL: downloadURL,
                                    placeholderImage: UIImage(named: "gray-back")!)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .onTapGesture {
                            self.isImageClicked = true
                        }
                } else {
                    Image("gray-back")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            case let .video(mediaItem):
                if let downloadURL = mediaItem.thumbnailUrl {
                    ZStack {
                        GWSNetworkImage(imageURL: downloadURL,
                                        placeholderImage: UIImage(named: "gray-back")!)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(12)
                        Image("play")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }.contentShape(Rectangle())
                        .onTapGesture {
                            if let downloadURL = message.videoDownloadURL {
                                let storage = Storage.storage()
                                storage.reference(forURL: downloadURL.absoluteString).downloadURL { url, _ in

                                    guard let url = url else {
                                        return
                                    }

                                    self.videoDownloadURL = url
                                    self.isShownSheet = true
                                    self.isShowVideoPlayer = true
                                }
                            }
                        }
                } else {
                    Image(uiImage: mediaItem.image ?? mediaItem.placeholderImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            case let .audio(item):
                GWSChatAudioView(message: message, isFromSender: message.sender.senderId == viewer?.uid, appConfig: appConfig)
                    .padding(8)
                    .background(background)
                    .cornerRadius(12)
            default:
                Text(self.message(message: message))
                    .padding(8)
                    .foregroundColor(message.sender.senderId == viewer?.uid ? Color.white : Color(appConfig.mainTextColor))
                    .background(background)
                    .cornerRadius(12)
            }

            if message.sender.senderId != viewer?.uid {
                Spacer()
            } else {
                if let urlString = message.atcSender.profilePictureURL {
                    GWSNetworkImage(imageURL: URL(string: urlString)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 25, height: 25)
                        .padding([.trailing, .bottom], 4)
                }
            }
        }.fullScreenCover(isPresented: $isImageClicked) {
            if let downloadURL = message.downloadURL {
                ZStack {
                    GWSNetworkImage(imageURL: downloadURL,
                                    placeholderImage: UIImage(named: "gray-back")!)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    VStack {
                        HStack {
                            Spacer()
                            Image("dismissIcon")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .onTapGesture {
                                    isImageClicked = false
                                }
                        }
                        Spacer()
                    }.padding(.top, 40)
                        .padding(.trailing, 10)
                }.ignoresSafeArea()
                    .padding(.top, -13)
            }
        }
    }

    fileprivate func message(message: GWSChatMessage) -> String {
        if let htmlContent = message.htmlContent {
            return htmlContent.string
        } else {
            return message.content
        }
    }
}
