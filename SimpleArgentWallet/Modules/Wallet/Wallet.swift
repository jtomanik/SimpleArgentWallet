//
//  Wallet.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import Swinject

extension Modules {

    struct Wallet {
    }
}

extension Modules.Wallet {

    static func make() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.blue
        return vc
    }
}

extension Modules.Wallet: Assembly {

    func assemble(container: Container) {
    }
}
