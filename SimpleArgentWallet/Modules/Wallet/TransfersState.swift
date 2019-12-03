//
//  TransfersState.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 03/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt
import RxSwift

extension Modules.Wallet {
    struct Transfers {}
}

extension Modules.Wallet.Transfers {

    enum State: FiniteStateType {

        static var initialState: State {
            return .initial
        }

        case initial
        case ready(Context)
        case sending(Context)
        case sent(Context)

        enum Events {
            case enable(Ethereum.Wallet)
            case sendETH
            case transactionSent(hash: String)
            case error
        }

        struct Context: Equatable {
            let wallet: Ethereum.Wallet
            let pendingTransaction: Argent.TransferManager.TransferTokenInputs?
            let hashes: [String]
        }
    }
}

extension Modules.Wallet.Transfers.State: ReducableState {
    typealias State = Modules.Wallet.Transfers.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (state, event) {
        case (.initial, .enable(let wallet)):
            return .ready(Context(wallet: wallet))

        case (.ready(let context), .sendETH):
            let pending = makeTransferInputs(with: context.wallet)
            return .sending(context.with(pendingTransaction: pending))

        case (.sent(let context), .sendETH):
            let pending = makeTransferInputs(with: context.wallet)
            return .sending(context.with(pendingTransaction: pending))

        case (.sending(let context), .transactionSent(let hash)):
            print(hash)
            return .sent(context.with(newHash: hash))

        case (_, .transactionSent(let hash)):
            print(hash)
            return state

        default:
            return state
        }
    }

    private static func makeTransferInputs(with wallet: Ethereum.Wallet) -> Argent.TransferManager.TransferTokenInputs {
        let recipientAddress = Ethereum.Address.init(hexString: "0xbaCB43a86FD15F5069E938A2F60A9856C4fBC544")!
        let tokenAmount: BigUInt = 10000000000000000
        return Argent.TransferManager.TransferTokenInputs(wallet: wallet.address,
                                                          token: Argent.TransferManager.ethTokenAddress,
                                                          to: recipientAddress,
                                                          amount: tokenAmount)
    }
}

extension Modules.Wallet.Transfers.State.Context {

    init(wallet: Ethereum.Wallet) {
        self.wallet = wallet
        self.pendingTransaction = nil
        self.hashes = []
    }

    func with(newHash: String) -> Modules.Wallet.Transfers.State.Context {
        return Modules.Wallet.Transfers.State.Context(wallet: self.wallet,
                                                      pendingTransaction: self.pendingTransaction,
                                                      hashes: (self.hashes + [newHash]))
    }

    func with(pendingTransaction: Argent.TransferManager.TransferTokenInputs) -> Modules.Wallet.Transfers.State.Context {
        return Modules.Wallet.Transfers.State.Context(wallet: self.wallet,
                                                      pendingTransaction: pendingTransaction,
                                                      hashes: self.hashes)
    }
}

protocol ArgentTokenTransfer: class {
    func execute(_ functionModel: Argent.TransferManager.TransferTokenInputs, signedBy wallet: Ethereum.Wallet ) -> Observable<String>
}

extension Modules.Wallet.Transfers.State {

    static func makeRequest(tokenTransfer: ArgentTokenTransfer) -> Request {
        return Modules.Wallet.Transfers.State.makeRequest(when: { (state) -> Context? in
                guard case .sending(let context) = state else { return nil }; return context }
            ) { (context) -> Observable<Modules.Wallet.Transfers.State.Events> in
                guard let pending = context.pendingTransaction else {
                    return Observable.empty()
                }

                print("tokenTransfer")
                return tokenTransfer
                    .execute(pending, signedBy: context.wallet)
                    .observeOn(MainScheduler.asyncInstance)
                    .catchErrorJustReturn("ERR")
                    .map {
                        Modules.Wallet.Transfers.State.Events.transactionSent(hash: $0) }
            }
    }
}

extension Modules.Wallet.Transfers.State: StatechartType, ActionableState {
    typealias Actions = Modules.Wallet.Transfers.State
}
