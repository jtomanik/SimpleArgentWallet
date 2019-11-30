//
//  AppDelegate.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setupWindow()

        return true
    }

    private func setupWindow() {
        let bounds = UIScreen.main.bounds
        window = UIWindow(frame: bounds)
        window?.backgroundColor = UIColor.white
        window?.rootViewController = UIViewController()
        self.window?.makeKeyAndVisible()
    }
}

