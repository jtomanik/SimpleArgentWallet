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
        container.register(NetworkRequestProvider.self) { _ in
            NetworkRequester()
        }.inObjectScope(.container)

        container.register(PriceFeedProvider.self) { r in
            PriceFeed(network: r.fetch(NetworkRequestProvider.self))
        }.inObjectScope(.container)

        container.register(EthereumRequester.self) { _ in
            EthereumRequester()
        }.inObjectScope(.container)

        container.register(BalanceInformationProvider.self) { r in
            BalanceInformation(requester: r.fetch(EthereumRequester.self))
        }.inObjectScope(.container)

        container.register(WalletProvider.self) { _ in
            Keystore()
        }.inObjectScope(.container)
    }
}
