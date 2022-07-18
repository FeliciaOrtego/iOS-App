//
//  GWSLoginScreenViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 02/04/21.
//

import AuthenticationServices
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class GWSLoginScreenViewModel: NSObject, ObservableObject {
    @Published var phoneCountryCodeString: String = "US"
    @Published var phoneCodeString: String = "+1"
    @Published var verificationCode: String = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPhoneAuthActive: Bool = false
    @Published var isCodeSend: Bool = false
    @Published var showProgress: Bool = false
    @Published var shouldShowAlert = false
    @Published var alertMessage: String = ""
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject private var appRootScreenViewModel: AppRootScreenViewModel
    let loginManager: GWSSocialFirebaseUserManager
    private let readPermissions: [String] = ["public_profile",
                                             "email"]
    var appConfig: GWSConfigurationProtocol
    let authManager: AuthManager

    init(store: GWSPersistentStore, appRootScreenViewModel: AppRootScreenViewModel, appConfig: GWSConfigurationProtocol,
         authManager: AuthManager)
    {
        self.store = store
        self.appConfig = appConfig
        loginManager = GWSSocialFirebaseUserManager()
        self.appRootScreenViewModel = appRootScreenViewModel
        self.authManager = authManager
    }

    @objc func didTapLoginButton() async {
        GWSHapticsFeedbackGenerator.generateHapticFeedback(.mediumImpact)

        if isPhoneAuthActive, isCodeSend {
            if !verificationCode.isEmpty {
                showProgress = true
                do { try await authManager.postLogin(email: email, phone: phoneNumber) }
                catch HttpError.badAuth {
                    authManager.logOut()
                    store.logout()
                } catch {
                    print("Auth error \(error)")
                }
                let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") ?? ""
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: verificationCode
                )
                Auth.auth().signIn(with: credential) { [weak self] dataResult, error in
                    self?.showProgress = false
                    if let strongSelf = self, let user = dataResult?.user {
                        let atcUser = GWSUser(uid: user.uid,
                                              firstName: user.displayName ?? "",
                                              lastName: "",
                                              email: user.email ?? "",
                                              phoneNumber: user.phoneNumber ?? "")
                        strongSelf.loginManager.fetchUser(userID: user.uid, completion: { [weak strongSelf] _, error in
                            if let error = error {
                                self?.alertMessage = error.localizedDescription
                                self?.shouldShowAlert = true
                            } else if let secondStrongSelf = strongSelf {
                                secondStrongSelf.store.markUserAsLoggedIn(user: atcUser)
                                secondStrongSelf.appRootScreenViewModel.resyncCompleted = false
                                secondStrongSelf.appRootScreenViewModel.resyncSuccess = false
                                secondStrongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                            }
                        })
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                    }
                }
            } else {
                alertMessage = "The login credentials are invalid. Please try again".localizedCore
                shouldShowAlert = true
            }
            return
        } else if isPhoneAuthActive {
            if !phoneNumber.isEmpty {
                showProgress = true
                try? await authManager.postLogin(email: email, phone: phoneNumber)
                PhoneAuthProvider.provider().verifyPhoneNumber(phoneCodeString + phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
                    self?.showProgress = false
                    if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                    } else {
                        UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                        self?.isCodeSend = true
                    }
                }
            } else {
                alertMessage = "The login credentials are invalid. Please try again".localizedCore
                shouldShowAlert = true
            }
            return
        } else {
            if !email.isEmpty, !password.isEmpty {
                showProgress = true
                try? await authManager.postLogin(email: email, phone: phoneNumber)
                showProgress = false
                Auth.auth().signIn(withEmail: email, password: password) { [weak self] dataResult, error in
                    self?.showProgress = false
                    if let strongSelf = self, let user = dataResult?.user {
                        let atcUser = GWSUser(uid: user.uid,
                                              firstName: user.displayName ?? "",
                                              lastName: "",
                                              email: user.email ?? "",
                                              phoneNumber: user.phoneNumber ?? "")
                        strongSelf.loginManager.fetchUser(userID: user.uid, completion: { [weak strongSelf] _, error in
                            if let error = error {
                                self?.alertMessage = error.localizedDescription
                                self?.shouldShowAlert = true
                            } else if let secondStrongSelf = strongSelf {
                                secondStrongSelf.store.markUserAsLoggedIn(user: atcUser)
                                secondStrongSelf.appRootScreenViewModel.resyncCompleted = false
                                secondStrongSelf.appRootScreenViewModel.resyncSuccess = false
                                secondStrongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                            }
                        })
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                    }
                }
            } else {
                alertMessage = "The login credentials are invalid. Please try again".localizedCore
                shouldShowAlert = true
            }
            return
        }
    }

    @MainActor
    func APISignIn() async {
        do {
            try await authManager.postLogin(email: email, phone: phoneNumber)
        } catch {
            print("There was an issue when trying to sign in: \(error)")
        }
    }

    @objc func didTapFacebookButton() {
        GWSHapticsFeedbackGenerator.generateHapticFeedback(.mediumImpact)
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(permissions: readPermissions, from: nil) { result, _ in
            if result?.token != nil {
                self.didLoginWithFacebook()
            }
        }
    }

    private func didLoginWithFacebook() {
        //  Successful log in with Facebook
        if let accessToken = AccessToken.current {
            // If Firebase enabled, we log the user into Firebase
            if appConfig.isFirebaseAuthEnabled {
                showProgress = true
                Auth.auth().signIn(with: FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)) { [weak self] dataResult, error in
                    self?.showProgress = false
                    if let strongSelf = self, let user = dataResult?.user {
                        let atcUser = GWSUser(uid: user.uid,
                                              firstName: user.displayName ?? "",
                                              lastName: "",
                                              email: user.email ?? "",
                                              phoneNumber: user.phoneNumber ?? "")
                        strongSelf.saveUserToServerIfNeeded(user: atcUser, appIdentifier: "lawn-n-order")
                        if let strongSelf = self {
                            strongSelf.store.markUserAsLoggedIn(user: atcUser)
                            strongSelf.appRootScreenViewModel.resyncCompleted = false
                            strongSelf.appRootScreenViewModel.resyncSuccess = false
                            strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                        }
                    } else if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                    }
                }
            } else {
                let facebookAPIManager = GWSFacebookAPIManager(accessToken: accessToken)
                showProgress = true
                facebookAPIManager.requestFacebookUser(completion: { [weak self] facebookUser in
                    self?.showProgress = false
                    if let strongSelf = self, let email = facebookUser?.email {
                        let atcUser = GWSUser(uid: facebookUser?.id ?? "",
                                              firstName: facebookUser?.firstName ?? "",
                                              lastName: facebookUser?.lastName ?? "",
                                              avatarURL: facebookUser?.profilePicture ?? "",
                                              email: email)
                        strongSelf.store.markUserAsLoggedIn(user: atcUser)
                        strongSelf.appRootScreenViewModel.resyncCompleted = false
                        strongSelf.appRootScreenViewModel.resyncSuccess = false
                        strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                    }
                })
            }
            return
        }
        alertMessage = "The login credentials are invalid. Please try again".localizedCore
        shouldShowAlert = true
    }

    @objc func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func saveUserToServerIfNeeded(user: GWSUser, appIdentifier: String) {
        let ref = Firestore.firestore().collection("users")
        if let uid = user.uid {
            var dict = user.representation
            dict["appIdentifier"] = appIdentifier
            ref.document(uid).setData(dict, merge: true)
        }
    }
}

extension GWSLoginScreenViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller _: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = userIdentifier + "@applesignin.com"
            signIn(didFetchAppleUserWith: fullName?.givenName,
                   lastName: fullName?.familyName,
                   email: email,
                   password: userIdentifier)
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            signIn(didFetchAppleUserWith: nil,
                   lastName: nil,
                   email: username,
                   password: password)
        }
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError _: Error) {
        // Handle error.
    }

    func signIn(didFetchAppleUserWith firstName: String?,
                lastName: String?,
                email: String?,
                password: String)
    {
        guard let email = email else { return }
        let trimmedEmail = email.atcTrimmed()
        let trimmedPass = password.atcTrimmed()
        showProgress = true
        Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPass) { [weak self] result, error in
            self?.showProgress = false
            if let error = error, let errCode = AuthErrorCode(rawValue: error._code) {
                switch errCode {
                case .userNotFound:
                    Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPass) { _, error in
                        if error == nil {
                            self?.signIn(didFetchAppleUserWith: firstName, lastName: lastName, email: email, password: password)
                        }
                    }
                case .wrongPassword:
                    self?.alertMessage = "E-mail already exists. Did you sign up with a different method (email, facebook, apple)?".localizedCore
                    self?.shouldShowAlert = true
                    return
                default:
                    return
                }
            } else {
                if let strongSelf = self, let user = result?.user {
                    let atcUser = GWSUser(uid: user.uid,
                                          firstName: user.displayName ?? "",
                                          lastName: "",
                                          email: user.email ?? "",
                                          phoneNumber: user.phoneNumber ?? "")
                    strongSelf.saveUserToServerIfNeeded(user: atcUser, appIdentifier: "lawn-n-order")
                    strongSelf.loginManager.fetchUser(userID: user.uid, completion: { [weak strongSelf] _, error in
                        if let error = error {
                            self?.alertMessage = error.localizedDescription
                            self?.shouldShowAlert = true
                        } else if let secondStrongSelf = strongSelf {
                            secondStrongSelf.store.markUserAsLoggedIn(user: atcUser)
                            secondStrongSelf.appRootScreenViewModel.resyncCompleted = false
                            secondStrongSelf.appRootScreenViewModel.resyncSuccess = false
                            secondStrongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                        }
                    })
                } else if let error = error {
                    self?.alertMessage = error.localizedDescription
                    self?.shouldShowAlert = true
                }
            }
        }
    }
}

extension GWSLoginScreenViewModel: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows[0]
    }
}
