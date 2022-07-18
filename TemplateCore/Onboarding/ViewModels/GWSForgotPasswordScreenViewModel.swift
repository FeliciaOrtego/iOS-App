//
//  GWSForgotPasswordScreenViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 07/04/21.
//

import FirebaseAuth
import SwiftUI

class GWSForgotPasswordScreenViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showProgress: Bool = false
    @Published var shouldShowAlert = false
    @Published var alertMessage: String = ""
    var shouldDismissView = false

    @objc func didTapResetPasswordButton() {
        if !email.isEmpty {
            showProgress = true
            Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
                self?.showProgress = false
                if let error = error {
                    self?.alertMessage = error.localizedDescription
                    self?.shouldShowAlert = true
                } else {
                    self?.alertMessage = "We have just sent you a password reset email. Please check your inbox and follow the instructions to reset your password".localizedCore
                    self?.shouldShowAlert = true
                    self?.shouldDismissView = true
                }
            }
        } else {
            alertMessage = "E-mail is invalid. Please try again".localizedCore
            shouldShowAlert = true
        }
    }
}
