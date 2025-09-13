//
//  MessageCell.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//


import UIKit

// MARK: - Custom Cell
class ThreadCell: UITableViewCell {
    static let identifier = "ThreadCell"
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.backgroundColor = .clear
        iv.clipsToBounds = true
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        iv.image = UIImage(systemName: "person.fill", withConfiguration: config)
        return iv
    }()
    
    private let imageContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .gray
        v.layer.cornerRadius = 25
        return v
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        return lbl
    }()
    
    private let messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 14)
        return lbl
    }()
    
    private let timeLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 12)
        return lbl
    }()
    
    private let unreadCountLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .white
        lbl.backgroundColor = .systemRed
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 12
        lbl.clipsToBounds = true
        lbl.isHidden = true
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.addSubview(imageContainer)
        imageContainer.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadCountLabel)
        
        NSLayoutConstraint.activate([
            
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            imageContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: 50),
            imageContainer.heightAnchor.constraint(equalToConstant: 50),
            
            profileImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            unreadCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            unreadCountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            unreadCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            unreadCountLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with thread: ThreadResponse) {
        nameLabel.text = thread.threadName
        messageLabel.text = thread.lastMessage?.text
        timeLabel.text = thread.lastMessage?.formattedTimestamp
        
        // Unread count
        if let unread = thread.unreadCount, unread > 0 {
            unreadCountLabel.isHidden = false
            unreadCountLabel.text = "\(unread)"
            messageLabel.font = UIFont.boldSystemFont(ofSize: 14) // dark text
        } else {
            unreadCountLabel.isHidden = true
            messageLabel.font = UIFont.systemFont(ofSize: 14)
        }
    }
}
