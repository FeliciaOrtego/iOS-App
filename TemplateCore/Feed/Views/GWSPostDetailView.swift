//
//  GWSPostDetailView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 15/04/21.
//

import SwiftUI

struct GWSPostDetailView<Model>: View where Model: GWSFeedPostManagerProtocol {
    @ObservedObject var post: GWSPostModel
    @ObservedObject var postViewModel: Model
    var viewer: GWSUser?
    var loggedInUser: GWSUser?
    @State var commentText = ""
    @ObservedObject var store: GWSPersistentStore
    var appConfig: GWSConfigurationProtocol

    init(post: GWSPostModel, postViewModel: Model, viewer: GWSUser? = nil, loggedInUser: GWSUser?, store: GWSPersistentStore, appConfig: GWSConfigurationProtocol) {
        self.post = post
        self.postViewModel = postViewModel
        self.viewer = viewer
        self.loggedInUser = loggedInUser
        self.store = store
        self.appConfig = appConfig
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    GWSPostView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, isPostDetailNavigationDisabled: true, store: store, appConfig: appConfig)
                        .padding(.top, 10)
                    ForEach(postViewModel.postComments) { postComment in
                        GWSPostCommentView(postComment: postComment, appConfig: appConfig)
                    }
                }
            }
            HStack {
                TextField("Add a Comment".localizedFeed, text: $commentText)
                    .padding()
                Image("send")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
                    .padding()
                    .onTapGesture {
                        self.handlePostCommentButton()
                    }
            }
            .background(Color(appConfig.grey1))
            .frame(height: 45)
        }
        .navigationBarTitle("Post".localizedFeed, displayMode: .inline)
        .onAppear {
            self.postViewModel.postComments.removeAll()
            self.postViewModel.fetchPostComments(post: post)
        }
    }

    func handlePostCommentButton() {
        // Handle Post Button To Firebase here
        guard let loggedInUser = viewer else { return }
        guard let loggedInUserUID = loggedInUser.uid else { return }
        guard let postAuthorID = post.authorID else { return }
        let commentComposer = GWSCommentComposerState()

        commentComposer.postID = post.id
        commentComposer.commentAuthorID = loggedInUser.uid
        commentComposer.date = Date()

        if !(commentText.isEmpty) {
            commentComposer.commentText = commentText
        } else {
            print("No comment to post")
            return
        }
        let notificationComposer = GWSNotificationComposerState(post: post, notificationAuthorID: loggedInUserUID, reacted: false, commented: true, isInteracted: false, createdAt: Date())

        if postAuthorID != loggedInUserUID {
            postViewModel.postNotification(composer: notificationComposer) {
                print("Notification Posted")
            }
            let message = "\(loggedInUser.fullName()) " + "commented on your post".localizedFeed
            postViewModel.sendPushToPostUser(message: message, post: post)
        }

        postViewModel.saveNewComment(loggedInUser: loggedInUser, commentComposer: commentComposer, post: post) {
            self.commentText = ""
            self.postViewModel.fetchPostComments(post: post)
        }
    }
}
