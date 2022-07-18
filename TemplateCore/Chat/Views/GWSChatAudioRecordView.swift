//
//  GWSChatAudioRecordView.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/06/21.
//

import SwiftUI

struct GWSChatAudioRecordView: View {
    @ObservedObject var viewModel: GWSChatAudioRecordViewModel

    init(user: GWSUser?, channel: GWSChatChannel, showRecordView: Binding<Bool>, showLoader: Binding<Bool>) {
        viewModel = GWSChatAudioRecordViewModel(user: user,
                                                channel: channel,
                                                showRecordView: showRecordView,
                                                showLoader: showLoader)
    }

    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.timerString)
            Spacer()
            HStack {
                if viewModel.isRecordStarted {
                    Button(action: {
                        viewModel.isRecordStarted.toggle()
                        viewModel.cancelAudioRecord()
                    }) {
                        Text("Cancel".localizedCore)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)

                    Button(action: {
                        viewModel.isRecordStarted.toggle()
                        viewModel.sendAudioRecord()
                    }) {
                        Text("Send".localizedThirdParty)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)
                } else {
                    Button(action: {
                        viewModel.isRecordStarted.toggle()
                        viewModel.startAudioRecord()
                    }) {
                        Text("Record".localizedThirdParty)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .frame(height: 45)
                    .background(Color.red)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom], 10)
                }
            }
        }
    }
}
