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
    func tappedSendETH()
}

extension Modules.Wallet {

    struct State: FiniteStateType {

        static var initialState: State {
            return State(account: Account.State.initialState,
                         transfers: Transfers.State.initialState,
                         transactions: ERC20.State.initialState)
        }

        let account: Account.State
        let transfers: Transfers.State
        let erc20Transactions: ERC20.State
        let erc20TransactionsHistory: ERC20.State

        enum Events {
            case account(Account.State.Events)
            case transfers(Transfers.State.Events)
            case erc20(ERC20.State.Events)
            case error
        }
    }
}

extension Modules.Wallet.State {

    init(account: Modules.Wallet.Account.State,
         transfers: Modules.Wallet.Transfers.State,
         transactions: Modules.Wallet.ERC20.State) {
        self.account = account
        self.transfers = transfers
        self.erc20Transactions = transactions
        self.erc20TransactionsHistory = transactions
    }

    func update(account: Modules.Wallet.Account.State) -> State {
        return Modules.Wallet.State(account: account,
                                    transfers: self.transfers,
                                    erc20Transactions: self.erc20TransactionsHistory,
                                    erc20TransactionsHistory: self.erc20Transactions)
    }

    func update(transfers: Modules.Wallet.Transfers.State) -> State {
        return Modules.Wallet.State(account: self.account,
                                    transfers: transfers,
                                    erc20Transactions: self.erc20TransactionsHistory,
                                    erc20TransactionsHistory: self.erc20Transactions)
    }

    func update(transactions: Modules.Wallet.ERC20.State) -> State {
        return Modules.Wallet.State(account: self.account,
                                    transfers: self.transfers,
                                    erc20Transactions: transactions,
                                    erc20TransactionsHistory: self.erc20Transactions)
    }
}

extension Modules.Wallet.State: ReducableState {
    typealias State = Modules.Wallet.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (event) {
        case let .account(unwrapped):
            let newAccount = Modules.Wallet.Account.State.reduce(state.account, unwrapped)
            return state.update(account: newAccount)

        case let .transfers(unwrapped):
            let newTransfer = Modules.Wallet.Transfers.State.reduce(state.transfers, unwrapped)
            return state.update(transfers: newTransfer)

        case let .erc20(unwrapped):
            let newTransaction = Modules.Wallet.ERC20.State.reduce(state.erc20Transactions, unwrapped)
            return state.update(transactions: newTransaction)

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
         nameInfo: ERC20NameProvider,
         tokenTransfer: ArgentTokenTransfer
    ) {

        let accountMiddleware = Modules.Wallet.Account.State.makeMiddleware(balanceInfo: balanceInfo, priceFeed: priceFeed)
        let accountRequest = Modules.Wallet.Account.State.makeRequest(walletInfo: walletInfo, tokenTransfer: tokenTransfer)
        let transactionsMiddleware = Modules.Wallet.ERC20.State.makeMiddleware(symbolInfo: symbolInfo, nameInfo: nameInfo)
        let transactionsRequest = Modules.Wallet.ERC20.State.makeRequest(transferInfo: transferInfo)
        let transferRequest = Modules.Wallet.Transfers.State.makeRequest(tokenTransfer: tokenTransfer)

        let middleware = Modules.Wallet.State.parallelMiddlewares(from: [
            Modules.Wallet.State.makeMiddleware(when: { (event) -> Modules.Wallet.Account.State.Events? in
                guard case let .account(unwrapped) = event else { return nil }; return unwrapped }
            ) { event in
                return accountMiddleware(event).map { Modules.Wallet.State.Events.account($0) }
            },

            Modules.Wallet.State.makeMiddleware(when: { (event) -> Modules.Wallet.ERC20.State.Events? in
                guard case let .erc20(unwrapped) = event else { return nil }; return unwrapped }
            ) { event in
                return transactionsMiddleware(event).map { Modules.Wallet.State.Events.erc20($0) }
            }
            ])

        let request = Modules.Wallet.State.requests(from: [
            Modules.Wallet.State.makeRequest(when: { (state) -> Ethereum.Wallet? in
                guard case let .loading(context) = state.account, let wallet = context.wallet else { return nil }; return wallet }
            ) { wallet in
                return Modules.Wallet.State.Events.erc20(Modules.Wallet.ERC20.State.Events.load(for: wallet.address))
            },

            Modules.Wallet.State.makeRequest(when: { (state) -> Ethereum.Wallet? in
                guard case let .loaded(context) = state.account, let wallet = context.wallet else { return nil }; return wallet }
            ) { wallet in
                return Modules.Wallet.State.Events.transfers(Modules.Wallet.Transfers.State.Events.enable(wallet))
            },
            
            Modules.Wallet.State.makeRequest(when: { return $0.account }
            ) { (accountState) -> Observable<Modules.Wallet.State.Events> in
                return accountRequest(accountState).map { Modules.Wallet.State.Events.account($0) }
            },

            Modules.Wallet.State.makeRequest(when: { return $0.transfers }
            ) { (transferState) -> Observable<Modules.Wallet.State.Events> in
                return transferRequest(transferState).map { Modules.Wallet.State.Events.transfers($0) }
            },

            Modules.Wallet.State.makeRequest(when: { return $0.erc20Transactions }
            ) { (walletState, transfersState) -> Observable<Modules.Wallet.State.Events> in
                guard walletState.erc20TransactionsHistory != transfersState || Modules.Wallet.ERC20.State.initialState == transfersState else {
                    return Observable.empty()
                }
                return transactionsRequest(transfersState).map { Modules.Wallet.State.Events.erc20($0) }
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
            .distinctUntilChanged()
            .map { ArgentWallet.transform($0) }
            .filterNil()
            .distinctUntilChanged()
    }

    func showTransactions() {
        self.handle(.erc20(.expand))
    }

    func hideStransactions() {
        self.handle(.erc20(.collapse))
    }

    func tappedSendETH() {
        self.handle(.transfers(.sendETH))
    }

    private static func transform(_ state: Modules.Wallet.State) -> Modules.Wallet.DisplayModel? {

        switch (state.account, state.transfers, state.erc20Transactions) {
        case (.loading(let context), _, _):
            return Modules.Wallet.DisplayModel(account: buildDisplayModel(fromContext: context),
                                               transfers: nil,
                                               transactions: nil)
        case (.loaded(let context), _, .short(let transactions)):
            return Modules.Wallet.DisplayModel(account: buildDisplayModel(fromContext: context),
                                               transfers: buildDisplayModel(with: state.transfers),
                                               transactions: Modules.Wallet.TransactionsCardModel(isTransactionListExpanded: false,
                                                                                                  transactions: buildDisplayModel(withTransactions: transactions))
            )
        case (.loaded(let context), _, .full(let transactions)):
            return Modules.Wallet.DisplayModel(account: buildDisplayModel(fromContext: context),
                                               transfers: buildDisplayModel(with: state.transfers),
                                               transactions: Modules.Wallet.TransactionsCardModel(isTransactionListExpanded: true,
                                                                                                  transactions: buildDisplayModel(withTransactions: transactions))
            )
        default:
            return nil
        }
    }

    private static func convertToETH(balance: BigUInt?) -> Double? {
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

    private static func format(_ double: Double) -> String {
        return String(format: "%.2f", double)
    }

    private static func format(_ value: Double?, rate: Double?, symbol: String) -> String {
        guard let value = value,
        let rate = rate else {
            return "- \(symbol)"
        }
        return "\(format(Double(value * rate))) \(symbol)"
    }

    private static func buildDisplayModel(withTransactions transactions: [Ethereum.ERC20Transaction]?) -> [Modules.Wallet.TransactionCardModel]? {
        guard let transactions = transactions else {
            return nil
        }
        return transactions.map { Modules.Wallet.TransactionCardModel(from: $0.transaction.from.hexString,
                                                                   contract: $0.token.contract.hexString,
                                                                   symbol: $0.token.symbol,
                                                                   value: $0.transaction.amount.description) }
    }

    private static func buildDisplayModel(fromContext context: Modules.Wallet.Account.State.Context) -> Modules.Wallet.AccountCardModel {
        return Modules.Wallet.AccountCardModel(imageSeed: context.wallet?.address.hexString ?? "",
                                                           name: context.wallet?.address.hexString ?? "-",
                                                           balance: format(convertToETH(balance: context.balance), rate: 1.0, symbol: "ETH"),
                                                           value: format(convertToETH(balance: context.balance), rate: context.price, symbol: "USD"))
    }

    private static func buildDisplayModel(with state: Modules.Wallet.Transfers.State) -> Modules.Wallet.TransfersCardModel? {
        switch state {
        case .ready:
            return Modules.Wallet.TransfersCardModel(isSendButtonEnabled: true, transactionHashes: [])
        case .sending(let context):
            return Modules.Wallet.TransfersCardModel(isSendButtonEnabled: false, transactionHashes: context.hashes)
        case .sent(let context):
            return Modules.Wallet.TransfersCardModel(isSendButtonEnabled: true, transactionHashes: context.hashes)
        default:
            return nil
        }
    }
}
