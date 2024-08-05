import UIKit

extension UIView {
    func pin(to other: UIView) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor),
            rightAnchor.constraint(equalTo: other.rightAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor),
            leftAnchor.constraint(equalTo: other.leftAnchor)
        ])
    }
}
