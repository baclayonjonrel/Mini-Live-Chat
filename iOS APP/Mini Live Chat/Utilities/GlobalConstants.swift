//
//  GlobalConstants.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//

import UIKit

enum GlobalConstants {
    static let CURRENT_DEVICE_IP = "192.168.1.33"
    
    static let BASE_API_URL = "http://\(CURRENT_DEVICE_IP):4000"
    static let BASE_SOCKET_URL = "http://\(CURRENT_DEVICE_IP):3000"
    
    static let AUTHENTICATION_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI3MDZhMmEzZi05NzAxLTQ2YmUtYTg2Mi01NGU1MzAzODIxODUiLCJpYXQiOjE3NTY1MjY1MTcsImV4cCI6MTc1NjYxMjkxNywic2NvcGUiOnsiYXBwSWQiOiI4MzVkNjdmMS03ZTM0LTRjZjUtOWU0ZS1hZDBhMmNlNDIwOTIiLCJyb29tcyI6W3sibmFtZSI6IioiLCJtZXRob2RzIjpbImNyZWF0ZSIsImNsb3NlIiwidXBkYXRlTWV0YWRhdGEiXSwibWVtYmVyIjp7Im5hbWUiOiIqIiwibWV0aG9kcyI6WyJwdWJsaXNoIiwic3Vic2NyaWJlIiwidXBkYXRlTWV0YWRhdGEiXX19XX0sInZlcnNpb24iOjN9.3qtyI6peXERY_tLVMinPfH-iyVTnXJcQM8OLjiX-MVY"
}

extension Notification.Name {
    static let callUpdateNotification = Notification.Name("callUpdateNotification")
    static let messageUpdateNotification = Notification.Name("messageUpdateNotification")
    static let refreshMessagesNotification = Notification.Name("refreshMessagesNotification")
    static let refreshThreadsNotification = Notification.Name("refreshThreadsNotification")
}
