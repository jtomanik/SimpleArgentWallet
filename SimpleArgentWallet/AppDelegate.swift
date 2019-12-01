//
//  AppDelegate.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import UIKit
import Swinject

let container = Assembler()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: RootWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        WalletTheme().apply()
        
        container.apply(assembly: self)
        container.apply(assembly: Modules.Root())
        container.apply(assembly: Modules.Lock())
        container.apply(assembly: Modules.Wallet())

        window = Modules.Root.makeWindow()
        window?.viewModel.start()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        window?.viewModel.lock()
    }
}

