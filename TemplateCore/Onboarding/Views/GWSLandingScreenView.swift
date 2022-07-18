//
//  GWSLandingScreenView.swift
//  SCore
//
//  Created by Jared Sullivan and Mayil Kannan on 09/03/21.
//

import SwiftUI

struct GWSLandingScreenView: View {
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject var appRootScreenViewModel: AppRootScreenViewModel
    var appConfig: GWSConfigurationProtocol
    let welcomeTitle: String
    let welcomeDescription: String
    let authManager: AuthManager

    var body: some View {
        NavigationView {
            VStack {
                Image("app-logo")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                Text(welcomeTitle)
                    .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                Text(welcomeDescription)
                    .foregroundColor(Color(appConfig.mainTextColor))
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                NavigationLink(destination: GWSLoginScreenView(store: store, appRootScreenViewModel: appRootScreenViewModel, appConfig: appConfig, authManager: authManager)) {
                    Text("Log In".localizedCore)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(Color.white)
                        .background(Color(appConfig.mainThemeForegroundColor))
                        .cornerRadius(45 / 2)
                        .padding(.horizontal, 50)
                        .padding(.top, 30)
                }
                NavigationLink(destination: GWSSignUpScreenView(store: store, appRootScreenViewModel: appRootScreenViewModel, appConfig: appConfig, authManager: authManager)) {
                    Text("Sign Up".localizedCore)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(Color(appConfig.mainThemeForegroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 45 / 2)
                                .stroke(Color(appConfig.mainThemeForegroundColor), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 50)
                        .padding(.top, 10)
                }
            }.offset(y: -50)
        }
    }
}
