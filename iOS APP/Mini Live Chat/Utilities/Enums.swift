//
//  Enums.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/23/25.
//

import Foundation

enum RoomCreationStatus: String {
    case notStarted = "Loading..."
    case creating = "creating"
    case created = "created"
    case createFailed = "creation Failed"
}

enum RoomFindStatus: String {
    case notStarted = "Loading..."
    case searching = "searching"
    case found = "found"
    case notFound = "not Found"
}

enum RoomJoinStatus: String {
    case notStarted = "Loading..."
    case joining = "joining"
    case joined = "joined"
    case failedToJoin = "failed To Join"
}

enum SKWErrorCode : UInt, @unchecked Sendable {
    case availableCameraIsMissing = 0
    case cameraIsNotSet = 1
    case contextSetupError = 2
    case channelFindError = 3
    case channelCreateError = 4
    case channelFindOrCreateError = 5
    case channelJoinError = 6
    case channelLeaveError = 7
    case channelCloseError = 8
    case memberUpdateMetadataError = 9
    case memberLeaveError = 10
    case localPersonPublishError = 11
    case localPersonSubscribeError = 12
    case localPersonUnpublishError = 13
    case localPersonUnsubscribeError = 14
    case remotePersonSubscribeError = 15
    case remotePersonUnsubscribeError = 16
    case publicationUpdateMetadataError = 17
    case publicationCancelError = 18
    case publicationEnableError = 19
    case publicationDisableError = 20
    case subscriptionCancelError = 21
    case contextDisposeError = 22

    var rawValueDescription: String {
        switch self {
        case .availableCameraIsMissing: return "Available Camera is Missing"
        case .cameraIsNotSet: return "Camera is Not Set"
        case .contextSetupError: return "Context Setup Error"
        case .channelFindError: return "Channel Find Error"
        case .channelCreateError: return "Channel Create Error"
        case .channelFindOrCreateError: return "Channel Find Or Create Error"
        case .channelJoinError: return "Channel Join Error"
        case .channelLeaveError: return "Channel Leave Error"
        case .channelCloseError: return "Channel Close Error"
        case .memberUpdateMetadataError: return "Member Update Metadata Error"
        case .memberLeaveError: return "Member Leave Error"
        case .localPersonPublishError: return "Local Person Publish Error"
        case .localPersonSubscribeError: return "Local Person Subscribe Error"
        case .localPersonUnpublishError: return "Local Person Unpublish Error"
        case .localPersonUnsubscribeError: return "Local Person Unsubscribe Error"
        case .remotePersonSubscribeError: return "Remote Person Subscribe Error"
        case .remotePersonUnsubscribeError: return "Remote Person Unsubscribe Error"
        case .publicationUpdateMetadataError: return "Publication Update Metadata Error"
        case .publicationCancelError: return "Publication Cancel Error"
        case .publicationEnableError: return "Publication Enable Error"
        case .publicationDisableError: return "Publication Disable Error"
        case .subscriptionCancelError: return "Subscription Cancel Error"
        case .contextDisposeError: return "Context Dispose Error"
        }
    }
}

