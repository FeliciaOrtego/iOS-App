//
//  TextFieldAlertViewController.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 29/05/21.
//

import Combine
import SwiftUI

class TextFieldAlertViewController: UIViewController {
    init(title: String, message: String?, text: Binding<String?>, isOkayPressed: Binding<Bool>, isPresented: Binding<Bool>?) {
        alertTitle = title
        self.message = message
        _text = text
        _isOkayPressed = isOkayPressed
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Dependencies

    private let alertTitle: String
    private let message: String?
    @Binding private var text: String?
    @Binding private var isOkayPressed: Bool
    private var isPresented: Binding<Bool>?

    // MARK: - Private Properties

    private var subscription: AnyCancellable?

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentAlertController()
    }

    private func presentAlertController() {
        guard subscription == nil else { return } // present only once

        let vc = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)

        // add a textField and create a subscription to update the `text` binding
        vc.addTextField { [weak self] textField in
            guard let self = self else { return }
            self.subscription = NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: textField)
                .map { ($0.object as? UITextField)?.text }
                .assign(to: \.text, on: self)
        }

        vc.addAction(UIAlertAction(title: "Cancel".localizedCore, style: .cancel, handler: { [weak self] _ in
            self?.isOkayPressed = false
        }))

        // create a `Ok` action that updates the `isPresented` binding when tapped
        // this is just for Demo only but we should really inject
        // an array of buttons (with their title, style and tap handler)
        let action = UIAlertAction(title: "OK".localizedCore, style: .default) { [weak self] _ in
            self?.isPresented?.wrappedValue = false
            self?.isOkayPressed = true
        }
        vc.addAction(action)
        present(vc, animated: true, completion: nil)
    }
}

struct TextFieldAlert {
    // MARK: Properties

    let title: String
    let message: String?
    @Binding var text: String?
    @Binding var isOkayPressed: Bool
    var isPresented: Binding<Bool>? = nil

    // MARK: Modifiers

    func dismissable(_ isPresented: Binding<Bool>) -> TextFieldAlert {
        TextFieldAlert(title: title, message: message, text: $text, isOkayPressed: $isOkayPressed, isPresented: isPresented)
    }
}

extension TextFieldAlert: UIViewControllerRepresentable {
    typealias UIViewControllerType = TextFieldAlertViewController

    func makeUIViewController(context _: UIViewControllerRepresentableContext<TextFieldAlert>) -> UIViewControllerType {
        TextFieldAlertViewController(title: title, message: message, text: $text, isOkayPressed: $isOkayPressed, isPresented: isPresented)
    }

    func updateUIViewController(_: UIViewControllerType,
                                context _: UIViewControllerRepresentableContext<TextFieldAlert>)
    {
        // no update needed
    }
}

struct TextFieldWrapper<PresentingView: View>: View {
    @Binding var isPresented: Bool
    let presentingView: PresentingView
    let content: () -> TextFieldAlert

    var body: some View {
        ZStack {
            if isPresented { content().dismissable($isPresented) }
            presentingView
        }
    }
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>,
                        content: @escaping () -> TextFieldAlert) -> some View
    {
        TextFieldWrapper(isPresented: isPresented,
                         presentingView: self,
                         content: content)
    }
}
