//
//  GWSWalkthoughView.swift
//  SCore
//
//  Created by Jared Sullivan and Mayil Kannan on 03/03/21.
//

import SwiftUI

struct GWSWalkthoughView: View {
    @State private var selectedTab = 0
    @ObservedObject var store: GWSPersistentStore
    var walkthroughData: [GWSWalkthroughModel]
    var appConfig: GWSConfigurationProtocol

    func isTabViewAtEnd() -> Bool {
        return selectedTab == appConfig.walkthroughData.count - 1
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                ZStack {
                    TabView(selection: $selectedTab) {
                        ForEach(0 ... walkthroughData.count - 1, id: \.self) { index in
                            VStack {
                                VStack {
                                    Image(walkthroughData[index].icon)
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                    Text(appConfig.walkthroughData[index].title)
                                        .foregroundColor(Color.white)
                                        .font(.title)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    Text(appConfig.walkthroughData[index].subtitle)
                                        .foregroundColor(Color.white)
                                        .padding(.top, 20)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .frame(minWidth: 0,
                                   maxWidth: .infinity,
                                   minHeight: 0,
                                   maxHeight: .infinity)
                            .background(Color(appConfig.mainThemeForegroundColor))
                        }
                    }.frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    ).tabViewStyle(PageTabViewStyle())
                    VStack {
                        Spacer()
                        HStack {
                            if !isTabViewAtEnd() {
                                Button("Skip".localizedChat) {
                                    store.markWalkthroughCompleted()
                                }
                                .foregroundColor(Color.white)
                            }
                            Spacer()
                            Button((!isTabViewAtEnd() ? "Next" : "Done").localizedChat) {
                                if !isTabViewAtEnd() {
                                    selectedTab = (selectedTab != appConfig.walkthroughData.count - 1) ? selectedTab + 1 : selectedTab
                                } else {
                                    store.markWalkthroughCompleted()
                                }
                            }.foregroundColor(Color.white)
                        }.frame(height: 20)
                    }.frame(alignment: .bottom)
                        .padding(.bottom, 20)
                        .padding(.horizontal, 20)
                }
            }.background(Color(appConfig.mainThemeForegroundColor))
        }.edgesIgnoringSafeArea(.all)
    }
}
