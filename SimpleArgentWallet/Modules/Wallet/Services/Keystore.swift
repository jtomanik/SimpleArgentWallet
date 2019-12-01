//
//  Keystore.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift
import web3

class Keystore {

    fileprivate let wallet: Ethereum.Wallet

    init() {
        self.wallet = Ethereum.Wallet(hexAddress: "0x70ABd7F0c9Bdc109b579180B272525880Fb7E0cB",
                                 hexPrivateKey: "0xec983791a21bea916170ee0aead71ab95c13280656e93ea4124c447bbd9a24a2")!
    }
}

extension Keystore: WalletProvider {

    func fetch() -> Observable<Ethereum.Wallet> {
        return Observable.just(wallet)
    }
}

extension Keystore: EthereumKeyStorageProtocol {

    func storePrivateKey(key: Data) throws {
        return
    }

    func loadPrivateKey() throws -> Data {
        return wallet.keyData
    }
}
