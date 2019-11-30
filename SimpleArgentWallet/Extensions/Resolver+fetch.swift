//
//  Resolver+fetch.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import Swinject


extension Resolver {

    public func fetch<Service>(_ service: Service.Type, name: String? = nil) -> Service {
        guard let service = resolve(service, name: name) else {
            fatalError("Could not resolve dependency")
        }
        return service
    }
}
