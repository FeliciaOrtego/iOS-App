import Kingfisher
import SwiftUI
import UIKit

public struct GWSNetworkImage: SwiftUI.View {
    // swiftlint:disable:next redundant_optional_initialization
    @State private var image: UIImage? = nil

    public let imageURL: URL?
    public let placeholderImage: UIImage
    public let animation: Animation = .default
    public var needUniqueID: Bool = false
    public var completionHandler: (() -> Void)?

    public var body: some SwiftUI.View {
        if needUniqueID {
            Image(uiImage: image ?? placeholderImage)
                .resizable()
                .onAppear(perform: loadImage)
                .transition(.opacity)
                .id(UUID())
        } else {
            Image(uiImage: image ?? placeholderImage)
                .resizable()
                .onAppear(perform: loadImage)
                .transition(.opacity)
                .id(image ?? placeholderImage)
        }
    }

    private func loadImage() {
        guard let imageURL = imageURL, image == nil else { return }
        KingfisherManager.shared.retrieveImage(with: imageURL) { result in
            switch result {
            case let .success(imageResult):
                self.image = imageResult.image
                completionHandler?()
            case .failure:
                break
            }
        }
    }
}

#if DEBUG
    // swiftlint:disable:next type_name
    struct NetworkImage_Previews: PreviewProvider {
        static var previews: some SwiftUI.View {
            GWSNetworkImage(imageURL: URL(string: "https://www.apple.com/favicon.ico")!,
                            placeholderImage: UIImage(systemName: "bookmark")!)
        }
    }
#endif
