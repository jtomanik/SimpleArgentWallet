//
//  Ethereum.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt

enum EthereumError: Error {
    case clientError
    case responseError
    case requestParsingError
}

struct Ethereum {}

extension Ethereum {

    struct Wallet {
        let address: Address
        let privateKey: BigUInt
    }

    struct Address {
        let value: BigUInt

        var hexString: String {
            return String(value, radix: 16, uppercase: false)
        }
     }

    struct Transaction {
        let from: Address
        let to: Address
        let amount: BigUInt
    }

    struct ERC20 {
        let contract: Address
        let name: String
    }

    struct ERC20Transaction {
        let token: ERC20
        let transaction: Transaction
        let block: BigUInt
    }
}

extension Ethereum.Wallet {

    init?(hexAddress: String, hexPrivateKey: String) {
        guard let address = Ethereum.Address(hexString: hexAddress),
            let key = BigUInt(hexString: hexPrivateKey) else {
            return nil
        }
        self.address = address
        self.privateKey = key
    }

    var keyData: Data {
        var data = Data.init(count: 32)
        let test = self.privateKey.serialize()
        return data
    }
}

extension Ethereum.Address {

    init?(hexString: String) {
        guard let address = BigUInt(hexString: hexString) else {
            return nil
        }
        self.value = address
    }
}


fileprivate extension String {

    func filterHex() -> String {
        let raw = self.lowercased()
        if raw.hasPrefix("0x") {
            return String(raw.dropFirst(2))
        } else {
            return raw
        }
    }
}

fileprivate extension BigUInt {

    init?(hexString: String) {
        guard let value = BigUInt(hexString.filterHex(), radix: 16) else {
            return nil
        }
        self = value
    }
}