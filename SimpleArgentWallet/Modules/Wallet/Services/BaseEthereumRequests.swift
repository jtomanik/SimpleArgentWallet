//
//  BaseEthereumRequests.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift
import BigInt
import web3

class BaseEthereumRequest {

    let requester: EthereumRequester

    init(requester: EthereumRequester) {
        self.requester = requester
    }
}

class BalanceInformation: BaseEthereumRequest, BalanceInformationProvider {

    func fetch(for address: Ethereum.Address) -> Observable<BigUInt> {
        return Observable<BigUInt>.create { [requester] observer -> Disposable in
            requester
                .client
                .eth_getBalance(address: address.hexString,
                                block: EthereumBlock.Latest) { (error, value) in
                                    if let error = error {
                                        observer.onError(EthereumError.clientError)
                                        return
                                    }
                                    guard let value = value else {
                                        return observer.onError(EthereumError.responseError)
                                    }
                                    observer.onNext(value)
                                    observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}

class ERC20NameInformation: BaseEthereumRequest, ERC20NameProvider {

    func fetch(for contract: Ethereum.Address) -> Observable<String> {
        return Observable<String>.create { [requester] observer -> Disposable in
            ERC20(client: requester.client).name(tokenContract: contract.toWeb3()) { (error, value) in
                if let error = error {
                    observer.onError(EthereumError.clientError)
                    return
                }
                guard let value = value else {
                    return observer.onError(EthereumError.responseError)
                }
                observer.onNext(value)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

class ERC20SymbolInformation: BaseEthereumRequest, ERC20SymbolProvider {

    func fetch(for contract: Ethereum.Address) -> Observable<String> {
        return Observable<String>.create { [requester] observer -> Disposable in
            ERC20(client: requester.client).symbol(tokenContract: contract.toWeb3()) { (error, value) in
                if let error = error {
                    observer.onError(EthereumError.clientError)
                    return
                }
                guard let value = value else {
                    return observer.onError(EthereumError.responseError)
                }
                observer.onNext(value)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

class ERC20TransferInformation: BaseEthereumRequest, ERC20TransferProvider {

    func fetch(for address: Ethereum.Address) -> Observable<[Ethereum.Transaction]> {
        return Observable<[Ethereum.Transaction]>.create { [requester] observer -> Disposable in
            ERC20(client: requester.client).transferEventsTo(recipient: address.toWeb3(),
                                                             fromBlock: .Earliest,
                                                             toBlock: .Latest) { (error, value) in
                                                                if let error = error {
                                                                    observer.onError(EthereumError.clientError)
                                                                    return
                                                                }
                                                                guard let transfers = value else {
                                                                    return observer.onError(EthereumError.responseError)
                                                                }
                                                                let parsed = transfers.map { Ethereum.Transaction(from: $0.from.toDomain(),
                                                                                                                  to: $0.to.toDomain(),
                                                                                                                  amount: $0.value) }
                                                                observer.onNext(parsed)
                                                                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
