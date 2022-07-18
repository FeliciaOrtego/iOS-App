//
//  GWSChatThreadView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/04/21.
//

import AVKit
import SwiftUI

struct GWSChatThreadView: View {
    var viewer: GWSUser?
    @ObservedObject private var viewModel: GWSChatThreadViewModel
    var channel: GWSChatChannel
    var appConfig: GWSConfigurationProtocol
    var hideNavigation: Bool = true
    var blockUserText = "Are you sure you want to block this user? You won't see their messages again.".localizedChat
    var leaveGroupText = "Are you sure you want to leave this group?".localizedChat
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(viewer: GWSUser? = nil, channel: GWSChatChannel, appConfig: GWSConfigurationProtocol) {
        self.viewer = viewer
        self.channel = channel
        self.appConfig = appConfig
        viewModel = GWSChatThreadViewModel(channel: channel)
        viewModel.chatTitleText = title(channel: channel)
    }

    var sheet: ActionSheet {
        ActionSheet(
            title: Text("Photo Upload".localizedFeed),
            buttons: [
                .default(Text("Camera".localizedFeed), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showImagePicker = true
                    self.viewModel.showingSheet = true
                }),
                .default(Text("Library".localizedFeed), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showImagePicker = true
                    self.viewModel.showingSheet = true
                }),
                .cancel(Text("Close".localizedFeed), action: {
                    self.viewModel.showAction = false
                }),
            ]
        )
    }

    var friendActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Actions".localizedCore),
            buttons: [
                .default(Text("Block User".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlert = true
                    self.viewModel.showingAlertForBlockUser = true
                }),
                .default(Text("Report User".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showReportUserActionSheet = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.viewModel.showAction = true
                    }
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                }),
            ]
        )
    }

    var reportUserActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Why are you reporting this account?".localizedChat),
            buttons: [
                .default(Text("Spam".localizedCore), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .spam)
                }),
                .default(Text("Sensitive photos".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .sensitiveImages)
                }),
                .default(Text("Abusive content".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .abusive)
                }),
                .default(Text("Harmful information".localizedChat), action: {
                    self.viewModel.showReportUserActionSheet = false
                    self.reportAction(reason: .harmful)
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showReportUserActionSheet = false
                }),
            ]
        )
    }

    func reportAction(reason: GWSReportingReason) {
        viewModel.reportAction(sourceUser: viewer, destUser: otherUser(), reason: reason)
        presentationMode.wrappedValue.dismiss()
    }

    var groupActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Group Settings".localizedChat),
            buttons: [
                .default(Text("Rename Group".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlertForRenameGroup = true
                }),
                .destructive(Text("Leave Group".localizedChat), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                    self.viewModel.showingAlert = true
                    self.viewModel.showingAlertForBlockUser = false
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.viewModel.showAction = false
                    self.viewModel.showFriendGroupActionSheet = false
                }),
            ]
        )
    }

    fileprivate func otherUser() -> GWSUser? {
        for recipient in channel.participants {
            if recipient.uid != viewer?.uid {
                return recipient
            }
        }
        return nil
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                ScrollViewReader { value in
                    LazyVStack {
                        ForEach(viewModel.messages, id: \.id) { message in
                            GWSMessageView(viewer: viewer, message: message, isShowVideoPlayer: $viewModel.showVideoPlayer, isShownSheet: $viewModel.showingSheet, videoDownloadURL: $viewModel.videoDownloadURL, appConfig: appConfig)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            value.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }.padding(.top, 8)
            HStack {
                Image("camera-filled-icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                    .frame(width: 20, height: 20)
                    .padding(.leading, 10)
                    .onTapGesture {
                        self.viewModel.showAction = true
                        self.viewModel.showFriendGroupActionSheet = false
                        self.viewModel.showReportUserActionSheet = false
                    }
                HStack {
                    Image("icons8-microphone-24")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            self.viewModel.showRecordView = true
                        }
                    TextField("Start typing...".localizedCore, text: $viewModel.chatText, onEditingChanged: { _ in
                        self.viewModel.showRecordView = false
                    })
                    .padding(.leading, 2)
                    .padding(.trailing, 10)
                    Image("send")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                        .frame(width: 20, height: 20)
                        .padding()
                        .onTapGesture {
                            self.handleSendMessageButton()
                        }
                }
                .frame(height: 35)
                .background(Color(appConfig.grey1))
                .cornerRadius(35 / 2)
                .padding(10)
            }
            if viewModel.showRecordView {
                GWSChatAudioRecordView(user: self.viewer,
                                       channel: self.channel,
                                       showRecordView: $viewModel.showRecordView,
                                       showLoader: $viewModel.showLoader)
                    .frame(height: 300)
            }
        }
        .overlay(
            VStack {
                CPKProgressHUDSwiftUI()
            }
            .frame(width: 100,
                   height: 100)
            .opacity(viewModel.showLoader ? 1 : 0)
        )
        .sheet(isPresented: $viewModel.showingSheet, onDismiss: {
            if viewModel.showImagePicker {
                viewModel.showImagePicker = false
            } else if viewModel.showVideoPlayer {
                viewModel.showVideoPlayer = false
            }
        }, content: {
            if viewModel.showImagePicker {
                GWSImagePicker(isShown: self.$viewModel.showImagePicker, isShownSheet: self.$viewModel.showingSheet, allMedia: true) { image, url in
                    if let image = image {
                        viewModel.sendPhoto(image, channel: channel, user: viewer)
                    } else if let url = url {
                        viewModel.sendMedia(url, channel: channel, user: viewer)
                    }
                }
            } else if viewModel.showVideoPlayer {
                if let downloadURL = viewModel.videoDownloadURL {
                    let player = AVPlayer(url: downloadURL)
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                }
            }
        })
        .alert(isPresented: $viewModel.showingAlert) {
            if viewModel.showingAlertForBlockUser {
                return Alert(
                    title: Text("Are you sure?".localizedChat),
                    message: Text(blockUserText),
                    primaryButton: .default(Text("Yes".localizedCore)) {
                        self.viewModel.blockUser(sourceUser: viewer, destUser: self.otherUser()) { _ in
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("\("Leave".localizedChat) \(viewModel.chatTitleText)"),
                    message: Text(leaveGroupText),
                    primaryButton: .default(Text("Yes".localizedCore)) {
                        self.viewModel.leaveGroup(channel: channel, user: viewer)
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .textFieldAlert(isPresented: $viewModel.showingAlertForRenameGroup) { () -> TextFieldAlert in
            TextFieldAlert(title: "Change Name".localizedChat, message: "", text: self.$viewModel.groupNameText, isOkayPressed: $viewModel.isOkayPressed)
        }
        .onAppear {
            self.viewModel.messages.removeAll()
            self.viewModel.fetchChat(channel: channel, user: viewer)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(self.viewModel.chatTitleText, displayMode: .inline)
        .navigationBarItems(leading:
            Button(action: {
                NotificationCenter.default.post(name: kConversationsScreenVisibleNotificationName, object: nil, userInfo: nil)
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image("arrow-back-icon")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color(appConfig.mainThemeForegroundColor))
            },
            trailing:
            HStack {
                Button(action: {
                    self.viewModel.showAction = true
                    self.viewModel.showFriendGroupActionSheet = true
                }) {
                    Image("settings-icon")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                }
            })
        .actionSheet(isPresented: $viewModel.showAction) {
            if viewModel.showFriendGroupActionSheet {
                if self.channel.participants.count > 2 || !self.channel.groupCreatorID.isEmpty {
                    return groupActionSheet
                } else {
                    return friendActionSheet
                }
            } else if viewModel.showReportUserActionSheet {
                return reportUserActionSheet
            } else {
                return sheet
            }
        }
    }

    fileprivate func title(channel: GWSChatChannel) -> String {
        if channel.name.count > 0 {
            return channel.name
        }
        let participants = channel.participants
        var name = ""
        for p in participants {
            if p.uid != viewer?.uid {
                let tmp = (participants.count > 2) ? p.firstWordFromName() : p.fullName()
                if name.count == 0 {
                    name += tmp
                } else {
                    name += ", " + tmp
                }
            }
        }
        return name
    }

    func handleSendMessageButton() {
        guard let user = viewer else { return }
        let attributedString = NSAttributedString(string: viewModel.chatText)
        let message = GWShatMessage(messageId: UUID().uuidString,
                                    messageKind: MessageKind.attributedText(attributedString),
                                    createdAt: Date(),
                                    atcSender: user,
                                    recipient: user,
                                    lastMessageSeeners: [],
                                    seenByRecipient: false,
                                    allTagUsers: viewModel.allTagUsers,
                                    inReplyToMessage: viewModel.inReplyToMessage)
        viewModel.save(message, channel, user: user)
        viewModel.chatText = ""
    }
}
