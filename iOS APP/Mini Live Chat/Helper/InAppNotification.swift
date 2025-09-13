//
//  InAppNotification.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import UIKit
import AudioToolbox

class InAppNotificationView: UIView {

    // MARK: - UI Elements
    private let contentView = UIView()
    private let lblNotification = UILabel()
    private let userNameLabel = UILabel()
    private let displayImage = UIImageView()
    
    var actionBlock: (() -> Void)?
    
    private var hideTimer: Timer?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGesture()
    }
    
    private func setupViews() {
        contentView.backgroundColor = UIColor(white: 1.0, alpha: 1)
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.25
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.clipsToBounds = false
        addSubview(contentView)
        
        displayImage.layer.cornerRadius = 20
        displayImage.clipsToBounds = true
        displayImage.contentMode = .scaleAspectFill
        contentView.addSubview(displayImage)
        
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        userNameLabel.textColor = .black
        contentView.addSubview(userNameLabel)
        
        lblNotification.font = UIFont.systemFont(ofSize: 13)
        lblNotification.numberOfLines = 2
        lblNotification.textColor = .black
        contentView.addSubview(lblNotification)
        
        // Layout
        contentView.translatesAutoresizingMaskIntoConstraints = false
        displayImage.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        lblNotification.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            displayImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            displayImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            displayImage.widthAnchor.constraint(equalToConstant: 40),
            displayImage.heightAnchor.constraint(equalToConstant: 40),
            
            userNameLabel.leadingAnchor.constraint(equalTo: displayImage.trailingAnchor, constant: 10),
            userNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            lblNotification.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor),
            lblNotification.trailingAnchor.constraint(equalTo: userNameLabel.trailingAnchor),
            lblNotification.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 2),
            lblNotification.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    private func setupGesture() {
        // Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        contentView.addGestureRecognizer(tap)
        
        // Swipe up
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(didSwipeUp(_:)))
        contentView.addGestureRecognizer(swipe)
    }
    
    @objc private func didTap() {
        actionBlock?()
        hide()
    }
    
    @objc private func didSwipeUp(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        if translation.y < -30 {
            hide()
        }
    }
    
    // MARK: - Show / Hide
    func show(in window: UIWindow?, duration: TimeInterval = 3.0) {
        guard let window = window else { return }
        window.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        // Use top anchor instead of bottom
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 68),
            topAnchor.constraint(equalTo: window.topAnchor, constant: -100) // start off-screen
        ])
        
        window.layoutIfNeeded()
        
        // Animate in from top
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            self.transform = CGAffineTransform(translationX: 0, y: 140) // slide down into view
        }
        
        // Auto-hide
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
            self.hide()
        })
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        
        UIView.animate(withDuration: 0.5, animations: {
            self.transform = .identity // slide back up off-screen
        }) { _ in
            self.removeFromSuperview()
        }
    }

    
    // MARK: - Configure content
    func configure(title: String, message: String, image: UIImage?, action: (() -> Void)? = nil) {
        userNameLabel.text = title
        lblNotification.text = message
        displayImage.image = image ?? UIImage(systemName: "person.circle")
        self.actionBlock = action
    }
}

