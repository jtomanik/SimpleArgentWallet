//
//  WalletViewModel.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt
import RxSwift

protocol WalletViewModel {
    var displayModel: Observable<Modules.Wallet.DisplayModel> { get }
}

protocol WalletProvider: class {
    func fetch() -> Observable<Ethereum.Wallet>
}

protocol PriceFeedProvider: class {
    func fetch() -> Observable<Double>
}
protocol BalanceInformationProvider: class {
    func fetch(for address: Ethereum.Address) -> Observable<BigUInt>
}

extension Modules.Wallet {

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
            case error
        }

        struct Context: Equatable {
            let wallet: Ethereum.Wallet?
            let balance: BigUInt?
            let price: Double?
        }
    }
}

extension Modules.Wallet.State.Context {

    init() {
        wallet = nil
        balance = nil
        price = nil
    }

    func with(wallet: Ethereum.Wallet) -> Modules.Wallet.State.Context {
        return Modules.Wallet.State.Context(wallet: wallet, balance: self.balance, price: self.price)
    }

    func with(balance: BigUInt) -> Modules.Wallet.State.Context {
        return Modules.Wallet.State.Context(wallet: self.wallet, balance: balance, price: self.price)
    }

    func with(price: Double) -> Modules.Wallet.State.Context {
        return Modules.Wallet.State.Context(wallet: self.wallet, balance: self.balance, price: price)
    }
}

extension Modules.Wallet.State: ReducableState {
    typealias State = Modules.Wallet.State

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
            let context = Modules.Wallet.State.Context().with(wallet: wallet)
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

extension Modules.Wallet.State: StatechartType, ActionableState {
    typealias Actions = Modules.Wallet.State
}

extension Modules.Wallet.State.Events: InterpretableCommand {
    typealias State = Modules.Wallet.State
}

class ArgentWallet: Automata<Modules.Wallet.State, Modules.Wallet.State.Events> {

    convenience init(walletInfo: WalletProvider,
         balanceInfo: BalanceInformationProvider,
         priceFeed: PriceFeedProvider
    ) {

        let middleware = ArgentWallet.parallelMiddlewares(from: [
            ArgentWallet.passthroughMiddleware(),

            ArgentWallet.makeMiddleware(when: { (event) -> Ethereum.Wallet? in
                if case .fetchedWallet(let wallet) = event { return wallet } else { return nil } },
                                        then: { (_, wallet) -> Observable<Modules.Wallet.State.Events> in
                let balance = balanceInfo
                    .fetch(for: wallet.address)
                    .map {
                        Modules.Wallet.State.Events.fetchedBalance($0) }
                let price = priceFeed
                    .fetch()
                    .map {
                        Modules.Wallet.State.Events.fetchedPrice($0) }

                return Observable.merge(balance, price)
            })
        ])

        let request = ArgentWallet.makeRequest(when: { (state) -> Bool? in
            if case .initial = state { return true } else { return nil } },
                                              then: { (_, _) -> Observable<Modules.Wallet.State.Events> in
                                                return walletInfo
                                                    .fetch()
                                                    .map {
                                                        Modules.Wallet.State.Events.fetchedWallet($0) }
        })

        self.init(
            middleware: middleware,
            request: request)
    }
}

extension ArgentWallet: WalletViewModel {

    var displayModel: Observable<Modules.Wallet.DisplayModel> {
        return self.output
            .asObservable()
            .map { ArgentWallet.transform($0) }
            .filterNil()
    }

    private static func transform(_ state: Statechart) -> Modules.Wallet.DisplayModel? {

        func convertToETH(balance: BigUInt?) -> Double? {
            guard let balance = balance else {
                return nil
            }

            let base: BigUInt = 1000000000000000000
            let base2 = 1000
            let (quotient, remainder) = balance.quotientAndRemainder(dividingBy: base)
            let (quotient2, remainder2) = remainder.quotientAndRemainder(dividingBy: base/BigUInt(base2))

            var etherValue: Double = 0
            etherValue += Double(quotient)
            etherValue += Double(quotient2)/Double(base2)

            return etherValue
        }

        func format(_ double: Double) -> String {
            return String(format: "%.2f", double)
        }

        func format(_ value: Double?, rate: Double?, symbol: String) -> String {
            guard let value = value,
            let rate = rate else {
                return "- \(symbol)"
            }
            return "\(format(Double(value * rate))) \(symbol)"
        }

        func buildModel(from context: Modules.Wallet.State.Context) -> Modules.Wallet.DisplayModel {
            let accountModel = Modules.Wallet.AccountCardModel(name: context.wallet?.address.hexString ?? "-",
                                                               balance: format(convertToETH(balance: context.balance), rate: 1.0, symbol: "ETH"),
                                                               value: format(convertToETH(balance: context.balance), rate: context.price, symbol: "USD"))
            let model = Modules.Wallet.DisplayModel(account: accountModel)
            return model
        }

        switch state {
        case .loading(let context):
            return buildModel(from: context)
        case .loaded(let context):
            return buildModel(from: context)
        default:
            return nil
        }


    }

}
