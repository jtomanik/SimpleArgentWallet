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
                                        observer.onError(EthereumError.responseError)
                                        return
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
                    observer.onError(EthereumError.responseError)
                    return
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
        return Observable<String>.create { [weak self, requester] observer -> Disposable in
            guard let tx = try? ERC20Functions.symbol(contract: contract.toWeb3()).transaction() else {
                observer.onError(EthereumError.clientError)
                observer.onCompleted()
                return Disposables.create()
            }

            requester.client.eth_call(tx, block: .Latest) { (error, value) in
                if let error = error {
                    observer.onError(EthereumError.clientError)
                    return
                }
                guard let value = self?.convert(hexString: value) else {
                    observer.onError(EthereumError.responseError)
                    return
                }

                observer.onNext(value)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func convert(hexString: String?) -> String? {
        guard let hexString = hexString else {
            return nil
        }
        let stringResultPrefix = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000"
        if hexString.hasPrefix(stringResultPrefix) {
            let rawHexString = String(hexString.dropFirst(stringResultPrefix.count))
            let charsArray = Array(rawHexString)
            let numbersArray = stride(from: 0, to: charsArray.count, by: 2).map() {
                strtoul(String(charsArray[$0 ..< min($0 + 2, charsArray.count)]), nil, 16)
            }
            if let resultLength = numbersArray.first {
                let resultArray = numbersArray.dropFirst().prefix(Int(resultLength)).map { Character(UnicodeScalar(UInt8($0))) }
                return String(resultArray)
            }
        } else {
            let rawHexString = String(hexString.replacingOccurrences(of: "00", with: "").dropFirst(2))
            let charsArray = Array(rawHexString)
            let numbersArray = stride(from: 0, to: charsArray.count, by: 2).map() {
                strtoul(String(charsArray[$0 ..< min($0 + 2, charsArray.count)]), nil, 16)
            }
            let resultArray = numbersArray.map { Character(UnicodeScalar(UInt8($0))) }
            return String(resultArray)
        }
        return nil
    }
}

class ERC20TransferInformation: BaseEthereumRequest, ERC20TransferProvider {

    func fetch(for address: Ethereum.Address) -> Observable<[Ethereum.Transaction]> {
        return Observable<[Ethereum.Transaction]>.create { [requester] observer -> Disposable in
            ERC20(client: requester.client)
                .transferEventsTo(recipient: address.toWeb3(),
                                  fromBlock: .Earliest,
                                  toBlock: .Latest) { (error, value) in
                                    if let error = error {
                                        observer.onError(EthereumError.clientError)
                                        return
                                    }
                                    guard let transfers = value else {
                                        observer.onError(EthereumError.responseError)
                                        return
                                    }
                                    
                                    let parsed = transfers.map { Ethereum.Transaction(from: $0.from.toDomain(),
                                                                                      to: $0.to.toDomain(),
                                                                                      contract: $0.log.address.toDomain(),
                                                                                      amount: $0.value,
                                                                                      block: BigUInt(hexString: $0.log.blockNumber.stringValue)) }
                                    observer.onNext(parsed)
                                    observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
