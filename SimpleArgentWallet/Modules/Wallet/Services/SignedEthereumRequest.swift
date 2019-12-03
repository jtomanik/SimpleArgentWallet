//
//  SignedEthereumRequest.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift
import BigInt
import web3

class SignedEthereumRequest: BaseEthereumRequest {

    let account: EthereumAccount

    init(requester: EthereumRequester,
         keyProvider: EthereumKeyStorageProtocol) {
        let account = try! EthereumAccount(keyStorage: keyProvider)
        self.account = account
        super.init(requester: requester)
    }
}

class ArgentTransferTokenOperation: SignedEthereumRequest, ArgentTokenTransfer {

    func execute(_ functionModel: Argent.TransferManager.TransferTokenInputs, signedBy wallet: Ethereum.Wallet ) -> Observable<String> {
        return Observable<String>.create { [requester, account] observer -> Disposable in
            guard let transaction = try? TransferFunction(model: functionModel).transaction() else {
                observer.onError(EthereumError.requestParsingError)
                observer.onCompleted()
                return Disposables.create()
            }

            requester.client.eth_sendRawTransaction(transaction, withAccount: account) { (error, value) in
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

    private struct TransferFunction: ABIFunction {
        static var name: String {
            return Argent.TransferManager.TransferTokenInputs.name
        }

        let gasPrice: BigUInt? = 250000
        let gasLimit: BigUInt? = 12
        let contract: EthereumAddress = Argent.TransferManager.contractAddress.toWeb3()
        var from: EthereumAddress? {
            return domainModel.wallet.toWeb3()
        }

        private let domainModel: Argent.TransferManager.TransferTokenInputs

        init(model: Argent.TransferManager.TransferTokenInputs) {
            domainModel = model
        }

        func encode(to encoder: ABIFunctionEncoder) throws {
            try encoder.encode(domainModel.wallet.toWeb3())
            try encoder.encode(domainModel.token.toWeb3())
            try encoder.encode(domainModel.to.toWeb3())
            try encoder.encode(domainModel.amount)
            try encoder.encode(Data())
        }
    }
}
