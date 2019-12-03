//
//  ERC20State.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 02/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt
import RxSwift

extension Modules.Wallet {
    struct ERC20 {}
}

extension Modules.Wallet.ERC20 {

    enum State: FiniteStateType {

        static var initialState: State {
            return .initial
        }

        case initial
        case loading(Ethereum.Address)
        case short(Context)
        case full(Context)

        enum Events {
            case load(for: Ethereum.Address)
            case fetchedTransactions([Ethereum.Transaction])
            case fetchedTokenDetails(Ethereum.ERC20)
            case error
        }

        struct Context: Equatable {
            let transactions: [Ethereum.Transaction]?
            let tokenInfo: [Ethereum.ERC20]?
            let tokenTransactions: [Ethereum.ERC20Transaction]?
        }
    }
}

extension Modules.Wallet.ERC20.State.Context {

    init() {
        transactions = nil
        tokenInfo = nil
        tokenTransactions = nil
    }
}

extension Modules.Wallet.ERC20.State: ReducableState {
    typealias State = Modules.Wallet.ERC20.State
}

protocol ERC20TransferProvider: class {
    func fetch(for address: Ethereum.Address) -> Observable<[Ethereum.Transaction]>
}

protocol ERC20SymbolProvider: class {
    func fetch(for contract: Ethereum.Address) -> Observable<String>
}
protocol ERC20NameProvider: class {
    func fetch(for contract: Ethereum.Address) -> Observable<String>
}

extension Modules.Wallet.ERC20.State {

    static func makeMiddleware(symblInfo: ERC20SymbolProvider, nameInfo: ERC20NameProvider) -> Middleware {
        return Modules.Wallet.ERC20.State.parallelMiddlewares(from: [
            Modules.Wallet.ERC20.State.passthroughMiddleware()
        ])
    }

    static func makeRequest(transferInfo: ERC20TransferProvider) -> Request {
        return Modules.Wallet.ERC20.State.makeRequest(when: { (state) -> Ethereum.Address? in
            guard case let .loading(address) = state else { return nil }; return address }
        ) { (address) -> Observable<Modules.Wallet.ERC20.State.Events> in
            return transferInfo
                .fetch(for: address)
                .observeOn(MainScheduler.asyncInstance)
                .catchErrorJustReturn([])
                .map { Modules.Wallet.ERC20.State.Events.fetchedTransactions($0) }
        }
    }
}

extension Modules.Wallet.ERC20.State: StatechartType, ActionableState {
    typealias Actions = Modules.Wallet.ERC20.State
}
