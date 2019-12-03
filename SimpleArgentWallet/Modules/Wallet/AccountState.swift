//
//  AccountState.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 02/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt
import RxSwift

extension Modules.Wallet {

    struct Account {
    }
}

extension Modules.Wallet.Account {

    enum State: FiniteStateType {

        static var initialState: State {
            return .initial
        }

        case initial
        case loading(Context)
        case loaded(Context)

        enum Events {
            case load
            case fetchedWallet(Ethereum.Wallet)
            case fetchedBalance(BigUInt)
            case fetchedPrice(Double)
            case test(String)
            case error
        }

        struct Context: Equatable {
            let wallet: Ethereum.Wallet?
            let balance: BigUInt?
            let price: Double?
        }
    }
}

protocol WalletProvider: class {
    func fetch() -> Observable<Ethereum.Wallet>
}

extension Modules.Wallet.Account.State: ReducableState {
    typealias State = Modules.Wallet.Account.State

    static func reduce(_ state: State, _ event: State.Events) -> State {

        func hasFinishedLoading(with context: Context) -> State {
            guard let _ = context.wallet,
                let _ = context.balance,
                let _ = context.price else {
                    return .loading(context)
            }

            return .loaded(context)
        }

        switch (state, event) {
        case (.initial, .fetchedWallet(let wallet)):
            let context = State.Context().with(wallet: wallet)
            return .loading(context)

        case (.loading(let context), .fetchedPrice(let price)):
            return hasFinishedLoading(with: context.with(price: price))

        case (.loading(let context), .fetchedBalance(let balance)):
            return hasFinishedLoading(with: context.with(balance: balance))
            
        default:
            return state
        }
    }
}

protocol PriceFeedProvider: class {
    func fetch() -> Observable<Double>
}
protocol BalanceInformationProvider: class {
    func fetch(for address: Ethereum.Address) -> Observable<BigUInt>
}

extension Modules.Wallet.Account.State {

    static func makeMiddleware(balanceInfo: BalanceInformationProvider, priceFeed: PriceFeedProvider) -> Middleware {
        return Modules.Wallet.Account.State.parallelMiddlewares(from: [
            Modules.Wallet.Account.State.passthroughMiddleware(),

            Modules.Wallet.Account.State.makeMiddleware(when: { (event) -> Ethereum.Wallet? in
                guard case let .fetchedWallet(wallet) = event else { return nil }; return wallet }
            ) { (wallet) -> Observable<Modules.Wallet.Account.State.Events> in

                let balance = balanceInfo
                    .fetch(for: wallet.address)
                    .observeOn(MainScheduler.asyncInstance)
                    .catchErrorJustReturn(0)
                    .map { Modules.Wallet.Account.State.Events.fetchedBalance($0) }

                let price = priceFeed
                    .fetch()
                    .observeOn(MainScheduler.asyncInstance)
                    .catchErrorJustReturn(0.0)
                    .map {
                        Modules.Wallet.Account.State.Events.fetchedPrice($0) }

                return Observable
                    .merge(balance, price)
                    .observeOn(MainScheduler.asyncInstance)
            }
        ])
    }

    static func makeRequest(walletInfo: WalletProvider, tokenTransfer: ArgentTokenTransfer) -> Request {
        return Modules.Wallet.Account.State.requests(from: [
            Modules.Wallet.Account.State.makeRequest(when: { (state) -> Bool? in
                guard case .initial = state else { return nil }; return true }
            ) { (_) -> Observable<Modules.Wallet.Account.State.Events> in
                return walletInfo
                    .fetch()
                    .observeOn(MainScheduler.asyncInstance)
                    .map { Modules.Wallet.Account.State.Events.fetchedWallet($0) }
            }
        ])
    }
}

extension Modules.Wallet.Account.State: StatechartType, ActionableState {
    typealias Actions = Modules.Wallet.Account.State
}

extension Modules.Wallet.Account.State.Context {

    init() {
        wallet = nil
        balance = nil
        price = nil
    }

    func with(wallet: Ethereum.Wallet) -> Modules.Wallet.Account.State.Context {
        return Modules.Wallet.Account.State.Context(wallet: wallet,
                                                    balance: self.balance,
                                                    price: self.price)
    }

    func with(balance: BigUInt) -> Modules.Wallet.Account.State.Context {
        return Modules.Wallet.Account.State.Context(wallet: self.wallet,
                                                    balance: balance,
                                                    price: self.price)
    }

    func with(price: Double) -> Modules.Wallet.Account.State.Context {
        return Modules.Wallet.Account.State.Context(wallet: self.wallet,
                                                    balance: self.balance,
                                                    price: price)
    }
}
