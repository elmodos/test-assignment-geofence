//
//  UNNotificationSetting+Description.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/4/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import Foundation
import UserNotifications

extension UNNotificationSetting {
    var humanReadableDescription: String {
        switch self {
        case .notSupported: return "-"
        case .disabled: return "disabled"
        case .enabled: return "enabled"
        }
    }
}

extension UNNotificationSetting {
    var hrd: String {
        return self.humanReadableDescription
    }
}
