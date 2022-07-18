//
//  GWSPostVideoPlayerView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 07/05/21.
//

import AVKit
import SwiftUI

struct GWSPostVideoPlayerViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat(0)

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct GWSPostVideoPlayerViewOffsetPreferenceKeyReader: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .preference(key: GWSPostVideoPlayerViewOffsetPreferenceKey.self, value: geometry.frame(in: .global).origin.y)
        }
    }
}

struct GWSPostVideoPlayerView<Model>: View where Model: GWSFeedPostManagerProtocol {
    var postMedia: String
    var post: GWSPostModel
    @ObservedObject var feedViewModel: Model
    var shouldPlayAllVisibleVideo: Bool
    var shouldCreateLocalPlayer: Bool?
    var indexOfPlayer: Int

    init(postMedia: String, post: GWSPostModel, feedViewModel: Model, shouldPlayAllVisibleVideo: Bool = false, shouldCreateLocalPlayer: Bool = false, indexOfPlayer: Int) {
        self.postMedia = postMedia
        self.post = post
        self.feedViewModel = feedViewModel
        self.shouldPlayAllVisibleVideo = shouldPlayAllVisibleVideo
        self.shouldCreateLocalPlayer = shouldCreateLocalPlayer
        self.indexOfPlayer = indexOfPlayer
        if shouldCreateLocalPlayer, post.player1[indexOfPlayer] == nil {
            post.player1[indexOfPlayer] = AVPlayer(url: URL(string: postMedia)!)
            post.isVideoStartPlay1[indexOfPlayer] = false
        } else if post.player[indexOfPlayer] == nil {
            post.player[indexOfPlayer] = AVPlayer(url: URL(string: postMedia)!)
            if shouldPlayAllVisibleVideo {
                post.player[indexOfPlayer]?.isMuted = true
            }
            post.isVideoStartPlay[indexOfPlayer] = false
        }
    }

    var body: some View {
        if let shouldCreateLocalPlayer = shouldCreateLocalPlayer, shouldCreateLocalPlayer {
            AVPlayerControllerRepresented(player: post.player1[indexOfPlayer])
                .onAppear {
                    if !(post.player1[indexOfPlayer]?.isPlaying ?? false) && !post.isVideoStartPlay1[indexOfPlayer]! {
                        DispatchQueue.main.async {
                            print("local media \(post.player1) andand \((post.player1[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")

                            print("local media play2")
                            post.player1[indexOfPlayer]?.seek(to: CMTime.zero)
                            post.player1[indexOfPlayer]?.play()
                        }
                        post.isVideoStartPlay1[indexOfPlayer] = true
                    }
                }
                .onDisappear {
                    DispatchQueue.main.async {
                        post.player1[indexOfPlayer]?.pause()
                    }
                    post.isVideoStartPlay1[indexOfPlayer] = false
                }
        } else {
            GeometryReader { _ in
                Rectangle()
                    .background(GWSPostVideoPlayerViewOffsetPreferenceKeyReader())
                    .onPreferenceChange(GWSPostVideoPlayerViewOffsetPreferenceKey.self) { value in
                        DispatchQueue.main.async {
                            post.isVisible = !isPlayerHidden(value)
                            var checkIsPlaying = false
                            if post.isVisible {
                                var isMyPlayerReached = false
                                feedViewModel.posts.forEach { post in
                                    if self.post.id == post.id {
                                        isMyPlayerReached = true
                                    }
                                    if post.player[indexOfPlayer]?.isPlaying ?? false {
                                        if self.post.id != post.id, post.isVisible, !isMyPlayerReached, !shouldPlayAllVisibleVideo {
                                            checkIsPlaying = true
                                            if self.post.player[indexOfPlayer]?.isPlaying ?? false {
                                                print("player pause \((self.post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")
                                                self.post.player[indexOfPlayer]?.pause()
                                                self.post.isVisible = false
                                                self.post.isVideoStartPlay[indexOfPlayer] = false
                                            }
                                        } else if self.post.id != post.id, post.isVisible, !shouldPlayAllVisibleVideo {
                                            if post.player[indexOfPlayer]?.isPlaying ?? false {
                                                print("player pause \((post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")
                                                post.player[indexOfPlayer]?.pause()
                                                post.isVisible = false
                                                post.isVideoStartPlay[indexOfPlayer] = false
                                            }
                                        } else if self.post.id != post.id, !post.isVisible {
                                            if post.player[indexOfPlayer]?.isPlaying ?? false {
                                                print("player pause \((post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")
                                                post.player[indexOfPlayer]?.pause()
                                                post.isVisible = false
                                                post.isVideoStartPlay[indexOfPlayer] = false
                                            }
                                        }
                                    }
                                }
                            }
                            if !post.isVisible {
                                if post.player[indexOfPlayer]?.isPlaying ?? false {
                                    print("player pause \((post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")
                                    self.post.player[indexOfPlayer]?.pause()
                                    post.isVideoStartPlay[indexOfPlayer] = false
                                }
                            } else if post.isVisible, !(post.player[indexOfPlayer]?.isPlaying ?? false), !checkIsPlaying, !post.isVideoStartPlay[indexOfPlayer]! {
                                print("player play \((post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")
                                post.player[indexOfPlayer]?.seek(to: CMTime.zero)
                                post.player[indexOfPlayer]?.play()
                                post.isVideoStartPlay[indexOfPlayer] = true
                            }
                        }
                    }
                AVPlayerControllerRepresented(player: post.player[indexOfPlayer])
                    .onAppear {
                        if shouldPlayAllVisibleVideo && !(post.player[indexOfPlayer]?.isPlaying ?? false) && !post.isVideoStartPlay[indexOfPlayer]! {
                            DispatchQueue.main.async {
                                print("postMediapostMedia \(post.player) andand \((post.player[indexOfPlayer]?.currentItem?.asset as? AVURLAsset)?.url)")

                                print("postMediapostMedia play2")
                                post.player[indexOfPlayer]?.seek(to: CMTime.zero)
                                post.player[indexOfPlayer]?.play()
                            }
                            post.isVideoStartPlay[indexOfPlayer] = true
                        }
                    }
                    .onDisappear {
                        if post.player[indexOfPlayer]?.isPlaying ?? false {
                            DispatchQueue.main.async {
                                post.player[indexOfPlayer]?.pause()
                            }
                        }
                        post.isVideoStartPlay[indexOfPlayer] = false
                    }
            }
        }
    }

    private func isPlayerHidden(_ maxY: CGFloat) -> Bool {
        if maxY - 100 <= 0 {
            post.isVisible = false
            print("postpost hidden \(post.id) && maxYmaxY \(maxY - 100) isVisibleisVisible \(post.isVisible)")
            return true
        }
        post.isVisible = true
        print("postpost no hidden \(post.id) && maxYmaxY \(maxY - 100) isVisibleisVisible \(post.isVisible)")
        return false
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

struct AVPlayerControllerRepresented: UIViewControllerRepresentable {
    var player: AVPlayer?
    var activityIndicator: UIActivityIndicatorView = .init()

    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = UIViewController()

        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false

        viewController.addChild(controller)
        viewController.view.addSubview(controller.view)
        controller.didMove(toParent: viewController)

        // controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor).isActive = true
        controller.view.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
        controller.view.widthAnchor.constraint(equalTo: viewController.view.widthAnchor).isActive = true
        controller.view.heightAnchor.constraint(equalTo: viewController.view.heightAnchor).isActive = true

        viewController.view.addSubview(activityIndicator)
        // activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
        activityIndicator.color = .white
        viewController.view.bringSubviewToFront(activityIndicator)

        return viewController
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(player: player, activityIndicator: activityIndicator)
    }

    class Coordinator: NSObject {
        var player: AVPlayer?
        var activityIndicator: UIActivityIndicatorView

        init(player: AVPlayer?, activityIndicator: UIActivityIndicatorView) {
            self.player = player
            self.activityIndicator = activityIndicator
            super.init()
            player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        }

        override func observeValue(forKeyPath keyPath: String?, of _: Any?, change: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
            if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
                if #available(iOS 10.0, *) {
                    let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
                    let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
                    if newStatus != oldStatus {
                        DispatchQueue.main.async { [weak self] in
                            if newStatus == .playing || newStatus == .paused {
                                self?.activityIndicator.stopAnimating()
                            } else {
                                self?.activityIndicator.startAnimating()
                            }
                        }
                    }
                } else {
                    // Fallback on earlier versions
                    activityIndicator.stopAnimating()
                }
            }
        }

        deinit {
            player?.removeObserver(self, forKeyPath: "timeControlStatus")
        }
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
