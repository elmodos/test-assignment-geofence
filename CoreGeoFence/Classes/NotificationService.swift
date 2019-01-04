//
//  NotificationService.swift
//  CoreGeoFence
//
//  Created by Modo Ltunzher on 1/4/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import Foundation
import RxSwift
import UserNotifications

public protocol NotificationService {
    func requestNotificationsAuthorization()
    func sendNotification(_ message: String, identifier: String)

    var authorizationStatusObservable: Observable<UNNotificationSettings> { get }

}
