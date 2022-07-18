//
//  GWSConversationView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/04/21.
//

import SwiftUI

struct GWSConversationView: View {
    var channel: GWSChatChannel
    var viewer: GWSUser? = nil
    var appConfig: GWSConfigurationProtocol
    @State var showChatThread: Bool = false

    var body: some View {
        let unseenByMe = channel.lastMessageSeeners.filter { $0["uid"] == viewer?.uid }.isEmpty
        let participants = channel.participants
        let imageURLs = self.imageURLs(participants: participants)

        NavigationLink(destination: GWSChatThreadView(viewer: viewer, channel: channel, appConfig: appConfig), isActive: $showChatThread) {}
        HStack(alignment: VerticalAlignment.center) {
            if imageURLs.count < 2 {
                if let profilePictureURL = imageURLs.first, !profilePictureURL.isEmpty {
                    GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 60, height: 60)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 60, height: 60)
                }
            } else {
                ZStack {
                    if let profilePictureURL = imageURLs.first, !profilePictureURL.isEmpty {
                        GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.leading, .bottom], 15)
                    } else {
                        Image("empty-avatar")
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.leading, .bottom], 15)
                    }

                    if let profilePictureURL = imageURLs[1], !profilePictureURL.isEmpty {
                        GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.trailing, .top], 15)
                    } else {
                        Image("empty-avatar")
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                            .padding([.trailing, .top], 15)
                    }
                }.frame(width: 60, height: 60)
            }
            VStack(alignment: HorizontalAlignment.leading, spacing: 5) {
                HStack {
                    Text(self.title(channel: channel))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(appConfig.mainTextColor))
                    Spacer()
                }
                HStack {
                    Text(self.subtitle(channel: channel).string)
                        .lineLimit(2)
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                    Spacer()
                }
            }
        }.contentShape(Rectangle())
            .onTapGesture {
                NotificationCenter.default.post(name: kConversationsScreenHiddenNotificationName, object: nil, userInfo: nil)
                showChatThread = true
            }
            .padding(10)
    }

    fileprivate func imageURLs(participants: [GWSUser]) -> [String] {
        var res: [String] = []
        for p in participants {
            if p.uid != viewer?.uid, let profilePictureURL = p.profilePictureURL {
                res.append(profilePictureURL)
            }
        }
        res.shuffle()
        return Array(res.prefix(2))
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

    fileprivate func subtitle(channel: GWSChatChannel) -> NSMutableAttributedString {
        let lastMessage = channel.lastMessage
        let subtitle = NSMutableAttributedString(string: lastMessage)
        subtitle.append(NSAttributedString(string: " \u{00B7} " + TimeFormatHelper.chatString(for: channel.lastMessageDate)))
        return subtitle
    }
}
