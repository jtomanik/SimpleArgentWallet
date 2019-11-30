//
//  RootViewPresenting.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import Swinject

protocol RootViewPresenting {
    func show(_ vc: UIViewController)
    func present(_ vc: UIViewController)
    func dismiss()
}

extension AppDelegate: RootViewPresenting {

    func show(_ vc: UIViewController) {
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }

    func present(_ vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        window?.rootViewController?.present(vc, animated: false, completion: nil)
    }

    func dismiss() {
        window?.rootViewController?.dismiss(animated: false, completion: nil)
    }
}

extension AppDelegate: Assembly {

    func assemble(container: Container) {
        container.register(RootViewPresenting.self) { _ in
            return self
        }.inObjectScope(.weak)
    }
}
