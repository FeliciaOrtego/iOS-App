//
//  GWSNotificationView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/05/21.
//

import SwiftUI

struct GWSNotificationView: View {
    var notification: GWSFeedPostNotification
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        VStack {
            HStack(alignment: VerticalAlignment.center) {
                if let profilePictureURL = notification.notificationAuthorProfileImage, !profilePictureURL.isEmpty {
                    GWSNetworkImage(imageURL: URL(string: profilePictureURL)!,
                                    placeholderImage: UIImage(named: "empty-avatar")!)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .padding(.leading, 4)
                } else {
                    Image("empty-avatar")
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                        .padding(.leading, 4)
                }
                VStack {
                    let notificationAuthorName = notification.notificationAuthorUsername
                    let reactionText = " reacted to your post.".localizedFeed
                    let commentedText = " commented on your post.".localizedFeed

                    let message = notification.reacted ? notificationAuthorName + reactionText : notificationAuthorName + commentedText
                    HStack {
                        Text(message)
                            .lineLimit(nil)
                            .font(.system(size: 14))
                            .foregroundColor(Color(appConfig.mainTextColor))
                        Spacer()
                    }
                    HStack {
                        Text(TimeFormatHelper.timeAgoString(date: notification.createdAt ?? Date()))
                            .font(.system(size: 12))
                            .foregroundColor(Color(appConfig.mainTextColor))
                            .padding(.top, 8)
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding()
            Divider()
        }
    }
}
