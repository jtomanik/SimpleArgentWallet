//
//  EthereumRequester.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import RxSwift
import web3
import BigInt

class EthereumRequester {

    static let defaultGatewayURL = URL(string: "https://ropsten.infura.io/v3/735489d9f846491faae7a31e1862d24b")!

    let gatewayURL: URL
    let client: EthereumClient

    init(gateway: URL? = nil) {
        self.gatewayURL = gateway ?? EthereumRequester.defaultGatewayURL
        self.client = EthereumClient(url: gatewayURL)
    }
}

extension Ethereum.Address {

    func toWeb3() -> EthereumAddress {
        return EthereumAddress(self.hexString)
    }
}

extension EthereumAddress {

    func toDomain() -> Ethereum.Address {
        return Ethereum.Address(hexString: self.value)!
    }
}
