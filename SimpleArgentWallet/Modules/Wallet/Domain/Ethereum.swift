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

    struct Wallet: Equatable {
        let address: Address
        let privateKey: BigUInt
    }

    struct Address: Equatable {
        let value: BigUInt

        var hexString: String {
            return "0x\(String(value, radix: 16, uppercase: false))"
        }
     }

    struct Transaction: Equatable {
        let from: Address
        let to: Address
        let contract: Address
        let amount: BigUInt
        let block: BigUInt?
    }

    struct ERC20: Equatable {
        let contract: Address
        let symbol: String
    }

    struct ERC20Transaction: Equatable {
        let token: ERC20
        let transaction: Transaction
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
        return self.privateKey.serialize()
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

extension BigUInt {

    init?(hexString: String) {
        guard let value = BigUInt(hexString.filterHex(), radix: 16) else {
            return nil
        }
        self = value
    }
}
