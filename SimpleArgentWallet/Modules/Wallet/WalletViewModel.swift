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

extension Modules.Wallet {

    struct State: FiniteStateType {

        static var initialState: State {
            return State(account: Account.State.initialState,
                         transfers: ERC20.State.initialState)
        }

        let account: Account.State
        let transfers: ERC20.State

        enum Events {
            case account(Account.State.Events)
            case erc20(ERC20.State.Events)
            case error
        }
    }
}

extension Modules.Wallet.State: ReducableState {
    typealias State = Modules.Wallet.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (event) {
        case let .account(unwrapped):
            let newAccount = Modules.Wallet.Account.State.reduce(state.account, unwrapped)
            return State(account: newAccount,
                         transfers: state.transfers)
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

        let accountMiddleware = Modules.Wallet.Account.State.makeMiddleware(balanceInfo: balanceInfo, priceFeed: priceFeed)
        let accountRequest = Modules.Wallet.Account.State.makeRequest(walletInfo: walletInfo)

        let middleware = Modules.Wallet.State.parallelMiddlewares(from: [

            Modules.Wallet.State.makeMiddleware(when: { (event) -> Modules.Wallet.Account.State.Events? in
                guard case let .account(unwrapped) = event else { return nil }; return unwrapped }) { event in
                    return accountMiddleware(event).map { Modules.Wallet.State.Events.account($0) }
            }
            ])

        let request = Modules.Wallet.State.makeRequest(when: { return $0.account }) { state in
            return accountRequest(state).map { Modules.Wallet.State.Events.account($0) }
        }

        self.init(
            middleware: middleware,
            request: request)
    }
}

extension ArgentWallet: WalletViewModel {

    var displayModel: Observable<Modules.Wallet.DisplayModel> {
        return self.output
            .asObservable()
            .map { ArgentWallet.transform($0.account) }
            .filterNil()
    }

    private static func transform(_ state: Modules.Wallet.Account.State) -> Modules.Wallet.DisplayModel? {

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

        func buildModel(from context: Modules.Wallet.Account.State.Context) -> Modules.Wallet.DisplayModel {
            let accountModel = Modules.Wallet.AccountCardModel(imageSeed: context.wallet?.address.hexString ?? "",
                                                               name: context.wallet?.address.hexString ?? "-",
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
