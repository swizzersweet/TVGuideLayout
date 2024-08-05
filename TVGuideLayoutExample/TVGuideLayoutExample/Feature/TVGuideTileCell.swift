//
//  TVGuideTileCell.swift
//  TVGuideLayoutExample
//
//  Created by Jonathan Menard on 2024-08-05.
//

import UIKit

class TVGuideTileCell: UICollectionViewCell {
    private var backgroundImageContainerView: UIView!
    private(set) var backgroundImageView: UIImageView!
    private(set) var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setup() {
        clipsToBounds = true
        contentView.backgroundColor = .systemPink
        
        self.backgroundImageContainerView = UIView()
        backgroundImageContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageContainerView)
        backgroundImageContainerView.pin(to: contentView)
        backgroundImageContainerView.backgroundColor = .yellow
        
        self.backgroundImageView = UIImageView()
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageContainerView.addSubview(backgroundImageView)
        backgroundImageView.pin(to: backgroundImageContainerView)
        
        self.label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = label.font.withSize(16.0)
        label.textColor = UIColor(named: "Orange2")
        label.text = "Default Text"
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10.0),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func onTap(_ gestureRecognizer: UITapGestureRecognizer) {
        print("onTap", gestureRecognizer)
    }
    
    public func configure(text: String) {
        self.label.text = text
        setNeedsDisplay()
    }
}
