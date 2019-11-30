//
//  Root.swift
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

    struct Root {

        enum Routes: Equatable {
            case mainUI(fromLock: Bool)
            case lockedUI
        }
    }
}

extension Modules.Root {

    static func makeWindow() -> RootWindow {

        let vm = container.resolver.fetch(RootViewModel.self)
        let bounds = UIScreen.main.bounds
        let window = RootWindow(frame: bounds,
                                viewModel: vm)

        window.viewModel.route
            .observeOn(MainScheduler.instance)
            .bind(onNext: Modules.Root.navigate)
            .disposed(by: window.disposeBag)

        return window
    }
}

extension Modules.Root {

    static func navigate(_ flow: Modules.Root.Routes) {
        let parentFlow = container.resolver.fetch(RootViewPresenting.self)

        switch flow {
        case .mainUI(let isFromLock):
            if isFromLock {
                parentFlow.dismiss()
            } else {
                parentFlow.show(Modules.Wallet.make())
            }
        case .lockedUI:
            parentFlow.present(Modules.Lock.make())
        }
    }
}

extension Modules.Root: Assembly {

    func assemble(container: Container) {
        container.register(RootViewModel.self) { _ in
            AppSession()
        }.inObjectScope(.weak)
    }
}
