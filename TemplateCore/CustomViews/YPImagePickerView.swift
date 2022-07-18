//
//  YPImagePickerView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 29/04/21.
//

import AVKit
import SwiftUI
import YPImagePicker

struct YPImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedItems: [YPMediaItem]
    @Binding var isNewPostPresented: Bool

    func makeUIViewController(context _: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.library.mediaType = .photoAndVideo
        config.library.itemOverlayType = .grid
        config.shouldSaveNewPicturesToAlbum = false
        config.video.compression = AVAssetExportPresetPassthrough
        config.startOnScreen = .library
        config.screens = [.library, .photo, .video]
        config.video.libraryTimeLimit = 500.0
        config.showsCrop = .rectangle(ratio: 16 / 9)
        config.wordings.libraryTitle = "Gallery"
        config.hidesStatusBar = false
        config.hidesBottomBar = false
        config.maxCameraZoomFactor = 2.0
        config.library.maxNumberOfItems = 5
        config.gallery.hidesRemoveButton = false
        config.library.preselectedItems = selectedItems

        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking { [unowned picker] items, cancelled in

            if cancelled {
                print("Picker was canceled")
                picker.dismiss(animated: true, completion: nil)
                return
            }
            _ = items.map { print("🧀 \($0)") }

            self.selectedItems = items
            if let firstItem = items.first {
                switch firstItem {
                case let .photo(photo):
                    picker.dismiss(animated: true, completion: nil)
                    isNewPostPresented = true
                case let .video(video):

                    let assetURL = video.url
                    let playerVC = AVPlayerViewController()
                    let player = AVPlayer(playerItem: AVPlayerItem(url: assetURL))
                    playerVC.player = player

                    picker.dismiss(animated: true, completion: {
//                        self.present(playerVC, animated: true, completion: nil)
                        print("😀 \(String(describing: self.resolutionForLocalVideo(url: assetURL)!))")
                    })
                    isNewPostPresented = true
                }
            }
        }

        return picker
    }

    func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }

    func updateUIViewController(_: YPImagePicker, context _: Context) {}

    typealias UIViewControllerType = YPImagePicker
}
