//
//  AppDelegate.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import CoreGeoFence
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let locationManager = LocationManager()
        let notificationManager = NotificationManager(notificationCenter: UNUserNotificationCenter.current())
        let rootController = MainViewController(locationService: locationManager, notificationService: notificationManager)
        
        self.window?.rootViewController = UINavigationController(rootViewController: rootController)
        window?.makeKeyAndVisible()
        
        return true
    }

}
