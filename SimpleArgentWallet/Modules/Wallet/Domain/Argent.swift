//
//  Argent.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import BigInt

struct Argent {}

extension Argent {

    struct TransferManager {
        static let contractAddress = Ethereum.Address(hexString: "0xcdAd167a8A9EAd2DECEdA7c8cC908108b0Cc06D1")!
        static let ethTokenAddress = Ethereum.Address(hexString: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE")!

        struct TransferTokenInputs: Equatable {
            static let name = "transferToken"
            
            let wallet: Ethereum.Address
            let token: Ethereum.Address
            let to: Ethereum.Address
            let amount: BigUInt
        }
    }
}
