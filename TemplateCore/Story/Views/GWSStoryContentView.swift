//
//  GWSStoryContentView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/05/21.
//

import SwiftUI

struct GWSStoryContentView: View {
    @Binding var isStoryContentPresented: Bool
    @Binding var selectedStories: [GWSStory]
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var counter = 0.0
    @State private var selectedIndex = 0
    @State private var nextStoryUpdatingTime: Date = .init()
    @Binding var storiesUserState: GWSCoreStoriesUserState
    @Binding var userStoriesIndex: Int
    @State var isAnimationNeeded: Bool = true
    @State var animationOffCount: Int = 0
    @State var isImageDownloaded: Bool = false

    func showNextUserStories() {
        if storiesUserState.stories.count > userStoriesIndex + 1 {
            userStoriesIndex += 1
            selectedStories = storiesUserState.stories[userStoriesIndex]
            isAnimationNeeded = false
            isImageDownloaded = false
            selectedIndex = 0
            counter = 0
        } else {
            timer.upstream.connect().cancel()
            isStoryContentPresented = false
        }
    }

    private var tappableView: some View {
        GeometryReader { geometry in
            TappableView { location, _ in
                if location.x < geometry.size.width / 2 {
                    self.counter = 0
                    isAnimationNeeded = false
                    isImageDownloaded = false
                    selectedIndex = selectedIndex == 0 ? 0 : selectedIndex - 1
                } else {
                    if selectedIndex == selectedStories.count - 1 {
                        showNextUserStories()
                    } else {
                        isImageDownloaded = false
                        selectedIndex += 1
                        self.counter = 0
                    }
                }
                nextStoryUpdatingTime = Date()
            }
        }
    }

    var body: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            tappableView
            let story = selectedStories[selectedIndex]
            let mediaURL = story.storyMediaURL
            if story.storyType == "image" {
                ZStack {
                    GWSNetworkImage(imageURL: URL(string: mediaURL),
                                    placeholderImage: UIImage(named: "gray-back")!,
                                    completionHandler: {
                                        self.isImageDownloaded = true
                                    })
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                    .id(nextStoryUpdatingTime)
                    tappableView
                }
            }
            VStack {
                HStack(spacing: 2) {
                    ForEach(0 ..< selectedStories.count, id: \.self) { index in
                        ProgressView(value: selectedIndex == index ? counter : selectedIndex < index ? 0 : 5, total: 5)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor(hexString: "#DBDBDB"))))
                            .animation((selectedIndex == index && isAnimationNeeded) ? Animation.linear : nil)
                    }
                }
                .onReceive(timer) { _ in
                    if !isImageDownloaded { return }
                    if self.counter + 0.05 > 5.0 {
                        if selectedIndex == selectedStories.count - 1 {
                            showNextUserStories()
                        } else {
                            isImageDownloaded = false
                            selectedIndex += 1
                            self.counter = 0
                        }
                        nextStoryUpdatingTime = Date()
                    } else {
                        self.counter += 0.05
                    }
                    if !isAnimationNeeded {
                        if animationOffCount == 0 {
                            animationOffCount = 1
                        } else if animationOffCount == 1 {
                            animationOffCount = 0
                            isAnimationNeeded = true
                        }
                    }
                }
                HStack {
                    Spacer()
                    Image("dismissIcon")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            isStoryContentPresented = false
                        }
                }
                Spacer()
            }.padding(.top, 40)
        }.edgesIgnoringSafeArea(.all)
    }
}

struct GWSStoryMediaView: View {
    var imageName: String

    var body: some View {
        Image(imageName).resizable().frame(width: 200, height: 200, alignment: .center).scaledToFit()
    }
}

struct TappableView: UIViewRepresentable {
    var tappedCallback: (CGPoint, Int) -> Void

    func makeUIView(context: UIViewRepresentableContext<TappableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        gesture.numberOfTapsRequired = 1
        let gesture2 = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTapped))
        gesture2.numberOfTapsRequired = 2
        gesture.require(toFail: gesture2)
        v.addGestureRecognizer(gesture)
        v.addGestureRecognizer(gesture2)
        return v
    }

    class Coordinator: NSObject {
        var tappedCallback: (CGPoint, Int) -> Void
        init(tappedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.tappedCallback = tappedCallback
        }

        @objc func tapped(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            tappedCallback(point, 1)
        }

        @objc func doubleTapped(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            tappedCallback(point, 2)
        }
    }

    func makeCoordinator() -> TappableView.Coordinator {
        return Coordinator(tappedCallback: tappedCallback)
    }

    func updateUIView(_: UIView, context _: UIViewRepresentableContext<TappableView>) {}
}
