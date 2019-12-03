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

protocol WalletViewModel: class {
    var displayModel: Observable<Modules.Wallet.DisplayModel> { get }

    func showTransactions()
    func hideStransactions()
}

extension Modules.Wallet {

    struct State: FiniteStateType {

        static var initialState: State {
            return State(account: Account.State.initialState,
                         transfers: ERC20.State.initialState)
        }

        let account: Account.State
        let erc20Transfers: ERC20.State
        let erc20TransfersHistory: ERC20.State

        enum Events {
            case account(Account.State.Events)
            case erc20(ERC20.State.Events)
            case error
        }
    }
}

extension Modules.Wallet.State {

    init(account: Modules.Wallet.Account.State,
         transfers: Modules.Wallet.ERC20.State) {
        self.account = account
        self.erc20Transfers = transfers
        self.erc20TransfersHistory = transfers
    }

    func update(account: Modules.Wallet.Account.State) -> State {
        return Modules.Wallet.State(account: account, erc20Transfers: self.erc20TransfersHistory, erc20TransfersHistory: self.erc20Transfers)
    }

    func update(transfers: Modules.Wallet.ERC20.State) -> State {
        return Modules.Wallet.State(account: self.account, erc20Transfers: transfers, erc20TransfersHistory: self.erc20Transfers)
    }
}

extension Modules.Wallet.State: ReducableState {
    typealias State = Modules.Wallet.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (event) {
        case let .account(unwrapped):
            let newAccount = Modules.Wallet.Account.State.reduce(state.account, unwrapped)
            return state.update(account: newAccount)

        case let .erc20(unwrapped):
            let newTransfer = Modules.Wallet.ERC20.State.reduce(state.erc20Transfers, unwrapped)
            return state.update(transfers: newTransfer)

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
         priceFeed: PriceFeedProvider,
         transferInfo: ERC20TransferProvider,
         symbolInfo: ERC20SymbolProvider,
         nameInfo: ERC20NameProvider
    ) {

        let accountMiddleware = Modules.Wallet.Account.State.makeMiddleware(balanceInfo: balanceInfo, priceFeed: priceFeed)
        let accountRequest = Modules.Wallet.Account.State.makeRequest(walletInfo: walletInfo)
        let transferMiddleware = Modules.Wallet.ERC20.State.makeMiddleware(symbolInfo: symbolInfo, nameInfo: nameInfo)
        let transferRequest = Modules.Wallet.ERC20.State.makeRequest(transferInfo: transferInfo)

        let middleware = Modules.Wallet.State.parallelMiddlewares(from: [
            Modules.Wallet.State.makeMiddleware(when: { (event) -> Modules.Wallet.Account.State.Events? in
                guard case let .account(unwrapped) = event else { return nil }; return unwrapped }
            ) { event in
                return accountMiddleware(event).map { Modules.Wallet.State.Events.account($0) }
            },

            Modules.Wallet.State.makeMiddleware(when: { (event) -> Modules.Wallet.ERC20.State.Events? in
                guard case let .erc20(unwrapped) = event else { return nil }; return unwrapped }
            ) { event in
                return transferMiddleware(event).map { Modules.Wallet.State.Events.erc20($0) }
            }
            ])

        let request = Modules.Wallet.State.requests(from: [
            Modules.Wallet.State.makeRequest(when: { (state) -> Ethereum.Wallet? in
                guard case let .loading(context) = state.account, let wallet = context.wallet else { return nil }; return wallet }
            ) { wallet in
                return Modules.Wallet.State.Events.erc20(Modules.Wallet.ERC20.State.Events.load(for: wallet.address))
            },
            
            Modules.Wallet.State.makeRequest(when: { return $0.account }
            ) { (accountState) -> Observable<Modules.Wallet.State.Events> in
                return accountRequest(accountState).map { Modules.Wallet.State.Events.account($0) }
            },

            Modules.Wallet.State.makeRequest(when: { return $0.erc20Transfers }
            ) { (walletState, transfersState) -> Observable<Modules.Wallet.State.Events> in
                guard walletState.erc20TransfersHistory != transfersState || Modules.Wallet.ERC20.State.initialState == transfersState else {
                    return Observable.empty()
                }
                return transferRequest(transfersState).map { Modules.Wallet.State.Events.erc20($0) }
            }
        ])

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

    func showTransactions() {
        self.handle(.erc20(.expand))
    }

    func hideStransactions() {
        self.handle(.erc20(.collapse))
    }


    private static func transform(_ state: Modules.Wallet.State) -> Modules.Wallet.DisplayModel? {

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

        func buildModel(withTransactions transactions: [Ethereum.ERC20Transaction]?) -> [Modules.Wallet.TransferCardModel]? {
            guard let transactions = transactions else {
                return nil
            }
            return transactions.map { Modules.Wallet.TransferCardModel(from: $0.transaction.from.hexString,
                                                                       contract: $0.token.contract.hexString,
                                                                       symbol: $0.token.symbol,
                                                                       value: $0.transaction.amount.description) }
        }

        func buildModel(fromState state: Modules.Wallet.ERC20.State) -> Modules.Wallet.TransactionsCardModel? {
            switch state {
            case .short:
                return Modules.Wallet.TransactionsCardModel(isTransactionListExpanded: false,
                                                            transfers: buildModel(withTransactions: state.transactions))
            case .full:
                return Modules.Wallet.TransactionsCardModel(isTransactionListExpanded: true,
                                                            transfers: buildModel(withTransactions: state.transactions))
            default:
                return nil
            }
        }

        func buildModel(fromContext context: Modules.Wallet.Account.State.Context) -> Modules.Wallet.AccountCardModel {
            return Modules.Wallet.AccountCardModel(imageSeed: context.wallet?.address.hexString ?? "",
                                                               name: context.wallet?.address.hexString ?? "-",
                                                               balance: format(convertToETH(balance: context.balance), rate: 1.0, symbol: "ETH"),
                                                               value: format(convertToETH(balance: context.balance), rate: context.price, symbol: "USD"))
        }

        switch state.account {
        case .loading(let context):
            return Modules.Wallet.DisplayModel(account: buildModel(fromContext: context),
                                               transactions: nil)
        case .loaded(let context):
            return Modules.Wallet.DisplayModel(account: buildModel(fromContext: context),
                                               transactions: buildModel(fromState: state.erc20Transfers))
        default:
            return nil
        }
    }
}
