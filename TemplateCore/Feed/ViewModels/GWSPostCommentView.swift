//
//  GWSPostCommentView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 15/04/21.
//

import SwiftUI

struct GWSPostCommentView: View {
    let postComment: GWSPostComment
    var appConfig: GWSConfigurationProtocol

    var body: some View {
        HStack {
            if let commentAuthorProfilePicture = postComment.commentAuthorProfilePicture, !commentAuthorProfilePicture.isEmpty {
                GWSNetworkImage(imageURL: URL(string: commentAuthorProfilePicture)!,
                                placeholderImage: UIImage(named: "empty-avatar")!)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                    .padding([.leading, .bottom], 4)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(postComment.commentAuthorUsername ?? "")
                        .font(.system(size: 13))
                    Text(postComment.commentText ?? "")
                        .foregroundColor(Color(UIColor.darkGray))
                        .font(.system(size: 13))
                        .padding(.top, 2)
                }
                .padding([.leading, .trailing], 15)
                .padding([.top, .bottom], 10)
                Spacer()
            }
            .background(Color(appConfig.grey1))
            .cornerRadius(12)
            Spacer(minLength: 40)
        }
    }
}
