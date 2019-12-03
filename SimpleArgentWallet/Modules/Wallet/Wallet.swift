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
        let vm = ArgentWallet(walletInfo: container.resolver.fetch(WalletProvider.self),
                              balanceInfo: container.resolver.fetch(BalanceInformationProvider.self),
                              priceFeed: container.resolver.fetch(PriceFeedProvider.self),
                              transferInfo: container.resolver.fetch(ERC20TransferProvider.self),
                              symbolInfo: container.resolver.fetch(ERC20SymbolProvider.self),
                              nameInfo: container.resolver.fetch(ERC20NameProvider.self))
        let vc = WalletViewController(viewModel: vm)
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

        container.register(ERC20TransferProvider.self) { r in
            ERC20TransferInformation(requester: r.fetch(EthereumRequester.self))
        }.inObjectScope(.container)

        container.register(ERC20SymbolProvider.self) { r in
            ERC20SymbolInformation(requester: r.fetch(EthereumRequester.self))
        }.inObjectScope(.container)

        container.register(ERC20NameProvider.self) { r in
            ERC20NameInformation(requester: r.fetch(EthereumRequester.self))
        }.inObjectScope(.container)

        container.register(WalletProvider.self) { _ in
            Keystore()
        }.inObjectScope(.container)
    }
}
