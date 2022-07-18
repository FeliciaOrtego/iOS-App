//
//  GWSSignUpScreenViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 06/04/21.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class GWSSignUpScreenViewModel: ObservableObject {
    @Published var phoneCountryCodeString: String = "US"
    @Published var phoneCodeString: String = "+1"
    @Published var verificationCode: String = ""
    @Published var phoneNumber: String = ""
    @Published var firtName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPhoneAuthActive: Bool = false
    @Published var isCodeSend: Bool = false
    @Published var showProgress: Bool = false
    @Published var shouldShowAlert = false
    @Published var alertMessage: String = ""
    @Published var uiImage: UIImage? = nil
    @ObservedObject var store: GWSPersistentStore
    @ObservedObject private var appRootScreenViewModel: AppRootScreenViewModel
    let profileFirebaseUpdater: GWSProfileFirebaseUpdater
    let authManager: AuthManager

    init(store: GWSPersistentStore, appRootScreenViewModel: AppRootScreenViewModel,
         authManager: AuthManager)
    {
        self.store = store
        profileFirebaseUpdater = GWSProfileFirebaseUpdater(usersTable: "users")
        self.appRootScreenViewModel = appRootScreenViewModel
        self.authManager = authManager
    }

    @objc func didTapSignUpButton() async {
        GWSHapticsFeedbackGenerator.generateHapticFeedback(.mediumImpact)

        if isPhoneAuthActive, isCodeSend {
            if !verificationCode.isEmpty {
                showProgress = true
                let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") ?? ""
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: verificationCode
                )
                Auth.auth().signIn(with: credential) { [weak self] dataResult, error in
                    if let strongSelf = self, let user = dataResult?.user {
                        let user = GWSUser(uid: user.uid,
                                           firstName: user.displayName ?? self?.firtName,
                                           lastName: user.displayName ?? self?.lastName,
                                           avatarURL: user.photoURL?.absoluteString ?? "",
                                           email: user.email ?? "",
                                           phoneNumber: user.phoneNumber ?? "")
                        if let uiImage = strongSelf.uiImage {
                            strongSelf.profileFirebaseUpdater.uploadPhoto(image: uiImage, user: user, isProfilePhoto: true) { [weak self] _ in
                                strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "lawn-n-order")
                                if let strongSelf = self {
                                    strongSelf.store.markUserAsLoggedIn(user: user)
                                    strongSelf.appRootScreenViewModel.resyncCompleted = false
                                    strongSelf.appRootScreenViewModel.resyncSuccess = false
                                    strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                }
                                self?.showProgress = false
                            }
                        } else {
                            strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "lawn-n-order")
                            if let strongSelf = self {
                                strongSelf.store.markUserAsLoggedIn(user: user)
                                strongSelf.appRootScreenViewModel.resyncCompleted = false
                                strongSelf.appRootScreenViewModel.resyncSuccess = false
                                strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                            }
                            self?.showProgress = false
                        }
                    } else if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                        self?.showProgress = false
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
                Auth.auth().createUser(withEmail: email, password: password) { [weak self] dataResult, error in
                    if let strongSelf = self, let user = dataResult?.user {
                        let user = GWSUser(uid: user.uid,
                                           firstName: user.displayName ?? self?.firtName,
                                           lastName: user.displayName ?? self?.lastName,
                                           avatarURL: user.photoURL?.absoluteString ?? "",
                                           email: user.email ?? "")
                        if let uiImage = strongSelf.uiImage {
                            strongSelf.profileFirebaseUpdater.uploadPhoto(image: uiImage, user: user, isProfilePhoto: true) { [weak self] _ in
                                strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "lawn-n-order")
                                if let strongSelf = self {
                                    strongSelf.store.markUserAsLoggedIn(user: user)
                                    strongSelf.appRootScreenViewModel.resyncCompleted = false
                                    strongSelf.appRootScreenViewModel.resyncSuccess = false
                                    strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                                }
                                self?.showProgress = false
                            }
                        } else {
                            strongSelf.saveUserToServerIfNeeded(user: user, appIdentifier: "lawn-n-order")
                            if let strongSelf = self {
                                strongSelf.store.markUserAsLoggedIn(user: user)
                                strongSelf.appRootScreenViewModel.resyncCompleted = false
                                strongSelf.appRootScreenViewModel.resyncSuccess = false
                                strongSelf.appRootScreenViewModel.resyncPersistentCredentials()
                            }
                            self?.showProgress = false
                        }
                    } else if let error = error {
                        self?.alertMessage = error.localizedDescription
                        self?.shouldShowAlert = true
                        self?.showProgress = false
                    } else {
                        self?.alertMessage = "The login credentials are invalid. Please try again".localizedCore
                        self?.shouldShowAlert = true
                        self?.showProgress = false
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
    func APISignUp() async {
        do {
            let user = UserDTO(
                name: firtName + " " + lastName,
                phone: phoneNumber,
                email: email
            )

            print("Logging in user : \(String(describing: user))")

            do {
                try await authManager.postUserCreate(user: user)
            } catch HttpError.badAuth {
                authManager.logOut()
                store.logout()
            }
        } catch {
            print("There was an issue when trying to sign in: \(error)")
        }
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
