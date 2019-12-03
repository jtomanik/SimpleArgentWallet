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
        case short([Ethereum.ERC20Transaction])
        case full([Ethereum.ERC20Transaction])

        enum Events {
            case load(for: Ethereum.Address)
            case fetchedTransactions([Ethereum.Transaction])
            case fetchedTransactionDetails([Ethereum.ERC20Transaction])
            case expand
            case collapse
            case error
        }
    }
}

extension Modules.Wallet.ERC20.State {

    var transactions: [Ethereum.ERC20Transaction]? {
        switch self {
        case .full(let transactions):
            return transactions

        case .short(let transactions):
            return transactions

        default:
            return nil
        }
    }
}

extension Modules.Wallet.ERC20.State: ReducableState {
    typealias State = Modules.Wallet.ERC20.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (state, event) {
        case (.initial, .load(let address)):
            return .loading(address)

        case (.loading, .fetchedTransactionDetails(let transactions)):
            return .short(transactions)

        case (.short(let transactions), .expand):
            return .full(transactions)

        case (.full(let transactions), .collapse):
            return .short(transactions)

        default:
            return state
        }
    }
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

    static func makeMiddleware(symbolInfo: ERC20SymbolProvider, nameInfo: ERC20NameProvider) -> Middleware {
        return Modules.Wallet.ERC20.State.parallelMiddlewares(from: [
            Modules.Wallet.ERC20.State.passthroughMiddleware(),

            Modules.Wallet.ERC20.State.makeMiddleware(when: { (event) -> [Ethereum.Transaction]? in
                guard case let .fetchedTransactions(transactions) = event else { return nil }; return transactions }
            ) { (transactions) -> Observable<Modules.Wallet.ERC20.State.Events> in
                return Observable
                    .from(transactions)
                    .observeOn(MainScheduler.asyncInstance)
                    .flatMap { transaction in
                        symbolInfo
                            .fetch(for: transaction.contract)
                            .observeOn(MainScheduler.asyncInstance)
                            .catchErrorJustReturn("ERR")
                            .map { Ethereum.ERC20(contract: transaction.contract, symbol: $0) }
                            .map { Ethereum.ERC20Transaction(token: $0, transaction: transaction) }
                }
                    .reduce(Array<Ethereum.ERC20Transaction>()) { (acc, tx) -> [Ethereum.ERC20Transaction] in
                        return acc + [tx] }
                    .map { Modules.Wallet.ERC20.State.Events.fetchedTransactionDetails($0)}
            }
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
