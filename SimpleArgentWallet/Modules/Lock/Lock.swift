//
//  Lock.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import Swinject

extension Modules {

    struct Lock {
    }
}

extension Modules.Lock {

    static func make() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.red
        return vc
    }
}

extension Modules.Lock: Assembly {

    func assemble(container: Container) {
    }
}
