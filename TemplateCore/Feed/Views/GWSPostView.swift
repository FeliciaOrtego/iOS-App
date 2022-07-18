//
//  GWSPostView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 10/04/21.
//

import SwiftUI

let kMyPostDeletedNotificationName = NSNotification.Name(rawValue: "kMyPostDeletedNotificationName")

struct GWSPostView<Model>: View where Model: GWSFeedPostManagerProtocol {
    @ObservedObject var post: GWSPostModel
    @ObservedObject var postViewModel: Model
    var viewer: GWSUser?
    var loggedInUser: GWSUser?
    var isPostDetailNavigationDisabled: Bool
    @State var showMoreOptions: Bool = false
    @State var showReportOptions: Bool = false
    var appConfig: GWSConfigurationProtocol
    @ObservedObject var store: GWSPersistentStore
    let author: GWSUser

    init(post: GWSPostModel, postViewModel: Model, viewer: GWSUser? = nil, loggedInUser: GWSUser?, isPostDetailNavigationDisabled: Bool = false, store: GWSPersistentStore, appConfig: GWSConfigurationProtocol) {
        self.post = post
        self.appConfig = appConfig
        author = GWSUser(uid: post.authorID ?? "",
                         firstName: "",
                         lastName: "")
        self.postViewModel = postViewModel
        self.viewer = viewer
        self.loggedInUser = loggedInUser
        self.isPostDetailNavigationDisabled = isPostDetailNavigationDisabled
        self.store = store
    }

    func reportAction(reason: GWSReportingReason) {
        postViewModel.report(post, reason: reason, viewer: loggedInUser)
        removePosts()
    }

    func removePosts() {
        postViewModel.posts = postViewModel.posts.filter { $0.authorID != post.authorID }
    }

    func removePost(postID: String) {
        postViewModel.posts = postViewModel.posts.filter { $0.id != postID }
    }

    var reportPostActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Report".localizedFeed),
            message: Text("Select the reason of reporting:".localizedFeed),
            buttons: [
                .default(Text("Sensitive Images".localizedFeed), action: {
                    self.showReportOptions = false
                    self.reportAction(reason: .sensitiveImages)
                }),
                .default(Text("Spam".localizedFeed), action: {
                    self.showReportOptions = false
                    self.reportAction(reason: .spam)
                }),
                .default(Text("Abusive".localizedFeed), action: {
                    self.showReportOptions = false
                    self.reportAction(reason: .abusive)
                }),
                .default(Text("Harmful".localizedFeed), action: {
                    self.showReportOptions = false
                    self.reportAction(reason: .harmful)
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.showMoreOptions = false
                }),
            ]
        )
    }

    var otherUsersPostActionSheet: ActionSheet {
        ActionSheet(
            title: Text("More".localizedFeed),
            buttons: [
                .default(Text("Share Post".localizedFeed), action: {
                    self.showMoreOptions = false
                    self.sharePostActionSheet()
                }),
                .default(Text("Block User".localizedFeed), action: {
                    self.showMoreOptions = false
                    self.postViewModel.block(post, viewer: loggedInUser)
                    self.removePosts()
                }),
                .default(Text("Report Post".localizedFeed), action: {
                    self.showMoreOptions = false
                    self.showReportOptions = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showMoreOptions = true
                    }
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.showMoreOptions = false
                }),
            ]
        )
    }

    var myPostActionSheet: ActionSheet {
        ActionSheet(
            title: Text("More".localizedFeed),
            buttons: [
                .default(Text("Share Post".localizedFeed), action: {
                    self.showMoreOptions = false
                    self.sharePostActionSheet()
                }),
                .destructive(Text("Delete Post".localizedFeed), action: {
                    self.showMoreOptions = false
                    self.postViewModel.deletePost(post: post, completion: {
                        self.removePost(postID: post.id)
                        NotificationCenter.default.post(name: kMyPostDeletedNotificationName, object: nil, userInfo: nil)
                    })
                }),
                .cancel(Text("Cancel".localizedCore), action: {
                    self.showMoreOptions = false
                }),
            ]
        )
    }

    func sharePostActionSheet() {
        var firstActivityItem = post.postText
        if let postMedia = post.postMedia.first {
            firstActivityItem = postMedia
        }
        let items: [Any] = [firstActivityItem]

        let activityViewController = UIActivityViewController(
            activityItems: items, applicationActivities: nil
        )
        activityViewController.completionWithItemsHandler = { _, _, _, error in
            if error == nil {}
        }

        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            .postToWeibo,
            .postToTencentWeibo,
            .print,
            .postToFlickr,
            .postToVimeo,
        ]

        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }

    var body: some View {
        VStack {
            HStack {
                if !post.profileImage.isEmpty {
                    NavigationLink(destination: GWSProfileView(store: store, loggedInUser: loggedInUser, viewer: author, isFollowing: false, hideNavigationBar: true, appConfig: appConfig)) {
                        GWSNetworkImage(imageURL: URL(string: post.profileImage)!,
                                        placeholderImage: UIImage(named: "empty-avatar")!)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 34, height: 34)
                            .padding([.leading], 4)
                    }
                }
                Text(post.postUserName ?? "")
                NavigationLink(destination: EmptyView()) {}
                Spacer()
                Image("more")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding(.trailing, 8)
                    .foregroundColor(Color(appConfig.mainTextColor))
                    .onTapGesture {
                        self.showReportOptions = false
                        self.showMoreOptions = true
                    }
            }.padding([.bottom], 3)
            TabView {
                ForEach(0 ..< post.postMedia.count) { i in
                    if post.postMedia.count > i, let postMedia = post.postMedia[i], post.postMediaType.count > i, let postMediaType = post.postMediaType[i] {
                        if postMediaType.contains("video") {
                            GWSPostVideoPlayerView(postMedia: postMedia, post: post, feedViewModel: postViewModel, shouldCreateLocalPlayer: isPostDetailNavigationDisabled, indexOfPlayer: i)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 300)
                                .padding(.vertical, 4)
                        } else {
                            NavigationLink(destination: GWSPostDetailView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig)) {
                                GWSNetworkImage(imageURL: URL(string: postMedia)!,
                                                placeholderImage: UIImage(named: "gray-back")!)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                                    .padding(.vertical, 4)
                            }
                            .disabled(isPostDetailNavigationDisabled)
                        }
                    } else if post.postMedia.count > i, let postMedia = post.postMedia[i] {
                        NavigationLink(destination: GWSPostDetailView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig)) {
                            GWSNetworkImage(imageURL: URL(string: postMedia)!,
                                            placeholderImage: UIImage(named: "gray-back")!)
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 300)
                                .clipped()
                                .padding(.vertical, 4)
                        }
                        .disabled(isPostDetailNavigationDisabled)
                    }
                }
            }.tabViewStyle(PageTabViewStyle())
                .frame(height: 308)
            HStack {
                if post.isSelectedReaction {
                    Image("filled-heart")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(.leading, 8)
                        .onTapGesture {
                            post.selectedReaction = "no_reaction"
                            post.postLikes -= 1
                            self.postViewModel.updatePostReactions(loggedInUser: viewer, post: post, reaction: "no_reaction") {}
                        }
                } else {
                    Image("heart-unfilled")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(.leading, 8)
                        .foregroundColor(Color(appConfig.mainTextColor))
                        .onTapGesture {
                            post.selectedReaction = "like"
                            post.postLikes += 1

                            if let viewer = viewer, let viewerUserUID = viewer.uid {
                                let notificationComposer = GWSNotificationComposerState(post: post, notificationAuthorID: viewerUserUID, reacted: true, commented: false, isInteracted: false, createdAt: Date())

                                if post.authorID != viewerUserUID {
                                    postViewModel.postNotification(composer: notificationComposer) {
                                        print("Notification Posted")
                                    }
                                    let message = "\(viewer.fullName()) " + "liked your post.".localizedChat
                                    postViewModel.sendPushToPostUser(message: message, post: post)
                                }
                            }

                            self.postViewModel.updatePostReactions(loggedInUser: viewer, post: post, reaction: "like") {}
                        }
                }
                NavigationLink(destination: GWSPostDetailView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig)) {
                    Image("comment-unfilled")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(.leading, 4)
                        .foregroundColor(Color(appConfig.mainTextColor))
                }
                .disabled(isPostDetailNavigationDisabled)
                Spacer()
            }
            if post.postLikes > 0 {
                HStack {
                    Text("\(post.postLikes) \((post.postLikes > 1 ? "likes" : "like").localizedFeed)")
                        .padding(.leading, 8)
                        .padding(.top, 4)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
            }
            if !post.postText.isEmpty {
                HStack {
                    Text(post.postText)
                        .padding(.leading, 8)
                        .padding(.top, 2)
                        .font(.system(size: 13))
                    Spacer()
                }
            }
            if !isPostDetailNavigationDisabled && post.postComment > 0 {
                HStack {
                    NavigationLink(destination: GWSPostDetailView(post: post, postViewModel: postViewModel, viewer: viewer, loggedInUser: loggedInUser, store: store, appConfig: appConfig)) {
                        Text("\((post.postComment > 1 ? "View all" : "View").localizedFeed) \(post.postComment) \((post.postComment > 1 ? "comments" : "comment").localizedFeed)")
                            .padding(.leading, 8)
                            .padding(.top, 2)
                            .foregroundColor(Color.gray)
                            .font(.system(size: 13))
                    }
                    Spacer()
                }
            }
            HStack {
                Text(post.dateAsString)
                    .padding(.leading, 8)
                    .padding(.top, 2)
                    .foregroundColor(Color.gray)
                    .font(.system(size: 13))
                Spacer()
            }
        }
        .actionSheet(isPresented: $showMoreOptions) {
            if showReportOptions {
                return reportPostActionSheet
            } else if post.authorID == loggedInUser?.uid {
                return myPostActionSheet
            } else {
                return otherUsersPostActionSheet
            }
        }
        .alert(isPresented: $postViewModel.shouldShowAlert) { () -> Alert in
            Alert(title: Text(postViewModel.alertTitle),
                  message: Text(postViewModel.alertMessage))
        }
    }
}
