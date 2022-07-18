//
//  GWSPasscodeField.swift
//  SCore
//
//  Created by Jared Sullivan and Mayil Kannan on 09/03/21.
//

import SwiftUI

public struct GWSPasscodeField: View {
    var maxDigits: Int = 6

    @Binding var verificationCode: String
    @State var showPin = true
    @State var isDisabled = false

    var handler: (String, (Bool) -> Void) -> Void

    public var body: some View {
        ZStack {
            pinDots
            backgroundField
        }
    }

    private var pinDots: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< maxDigits) { index in
                if index < self.verificationCode.count {
                    Text(self.verificationCode.digits[index].numberString)
                        .frame(minWidth: 0, maxWidth: .infinity)
                } else {
                    Text("")
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                if index < maxDigits - 1 {
                    Divider()
                }
            }
        }
        .frame(height: 42)
        .frame(minWidth: 0, maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 42 / 2)
                .stroke(Color(UIColor(hexString: "#e6e6f2")), lineWidth: 1)
        )
    }

    private var backgroundField: some View {
        return TextField("", text: $verificationCode)
            .onChange(of: verificationCode, perform: { _ in
                if verificationCode.count > maxDigits {
                    verificationCode = String(verificationCode.prefix(maxDigits))
                }
            })
            .accentColor(.clear)
            .foregroundColor(.clear)
            .keyboardType(.numberPad)
            .disabled(isDisabled)
    }
}

extension String {
    var digits: [Int] {
        var result = [Int]()
        for char in self {
            if let number = Int(String(char)) {
                result.append(number)
            }
        }
        return result
    }
}

extension Int {
    var numberString: String {
        guard self < 10 else { return "0" }
        return String(self)
    }
}
