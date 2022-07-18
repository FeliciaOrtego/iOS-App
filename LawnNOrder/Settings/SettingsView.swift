//
//  SettingsView.swift
//  LawnNOrder
//
//  Created by Felicia Ortego on 6/15/22.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingFetcher: SettingManager

    @ObservedObject var store: GWSPersistentStore
    var viewer: GWSUser?
    var appConfig: GWSConfigurationProtocol
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showProgress = false
    @State private var didAppear = false
    @State private var pdfFooterText: String = ""

    @State private var updateSuccess: Bool = false

    init(store: GWSPersistentStore, viewer: GWSUser?, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.viewer = viewer
        self.appConfig = appConfig
        settingFetcher = SettingManager.shared
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Text("Invoice Footer")
                    TextEditor(text: $pdfFooterText)
                        .border(.secondary)
                }
                Button(action: {
                    Task(priority: .high) {
                        let putData: String = self.pdfFooterText
                        print("pre-flight putData: \(putData)")

                        self.showProgress = true
                        try? await settingFetcher.putFooterUpdate(text: putData)
                        self.showProgress = false
                        print("settingFetcher updateResponse on view: \(settingFetcher.updateResponse)")
                        self.updateSuccess = settingFetcher.updateResponse
                    }
                }) {
                    SubmitButtonContent()
                }
                .alert("Setting updated", isPresented: $updateSuccess) {
                    Button("OK") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if !self.didAppear {
                    self.didAppear = true
                    Task {
                        print("getting settings on view appear")
                        self.showProgress = true
                        try? await self.settingFetcher.fetchData()
                        self.showProgress = false
                        if let newPdfFooter = self.settingFetcher.settingData.first(where: { $0.attribute == "FooterText" }) {
                            self.pdfFooterText = newPdfFooter.value
                        }
                    }
                }
            }
            .task {
                print("getting settings on view task")
                try? await self.settingFetcher.fetchData()
                if let newPdfFooter = self.settingFetcher.settingData.first(where: { $0.attribute == "FooterText" }) {
                    self.pdfFooterText = newPdfFooter.value
                }
            }
            .overlay(
                VStack {
                    CPKProgressHUDSwiftUI()
                }
                .frame(width: 100,
                       height: 100)
                .opacity(self.showProgress ? 1 : 0)
            )
        }.navigationViewStyle(.stack)
    }
}
