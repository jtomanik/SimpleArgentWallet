//
//  Lock.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Swinject

extension Modules {

    struct Lock {
    }
}

extension Modules.Lock {

    static func make() -> UIViewController {
        let vm = PinLock(validator: container.resolver.fetch(PinValidation.self))
        let vc = LockViewController(viewModel: vm)

        vc.viewModel.route
            .observeOn(MainScheduler.instance)
            .bind(onNext: Modules.Root.navigate)
            .disposed(by: vc.disposeBag)

        return vc
    }
}

extension Modules.Lock: Assembly {

    func assemble(container: Container) {
        container.register(PinValidation.self) { _ in
            PinValidator()
        }.inObjectScope(.container)
    }
}
