//
//  NotificationManager.swift
//  CoreGeoFence
//
//  Created by Modo Ltunzher on 1/4/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import UserNotifications
import RxSwift

public class NotificationManager: NSObject, NotificationService {
    
// MARK: Publics

    public var authorizationStatusObservable: Observable<UNNotificationSettings> {
        return self.subjectAuthorizationStatus.asObservable()
    }

// MARK: Privates

    internal let unNotificationCenter: UNUserNotificationCenter
    internal let subjectAuthorizationStatus = ReplaySubject<UNNotificationSettings>.create(bufferSize: 1)

// MARK: - Memory Management
    
    public init(notificationCenter: UNUserNotificationCenter) {
        self.unNotificationCenter = notificationCenter
        super.init()
        self.getNotificationSettings()
    }

// MARK: - Public

    public func requestNotificationsAuthorization() {
        self.unNotificationCenter.requestAuthorization(options: [.alert, .badge]) { [weak self] (_, _) in
            self?.getNotificationSettings()
        }
    }
    
    public func sendNotification(_ message: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.body = message
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        self.unNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification request add failed: \(error)")
            }
        }
    }

// MARK: - Private

    internal func getNotificationSettings() {
        self.unNotificationCenter.getNotificationSettings { (settings) in
            self.subjectAuthorizationStatus.onNext(settings)
        }
    }
}
