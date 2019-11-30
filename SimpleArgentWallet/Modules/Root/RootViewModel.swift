//
//  RootViewModel.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

protocol RootViewModel {
    var output: Observable<Modules.Root.Routes> { get }

    func start()
}

enum AppSessionState: FiniteStateType {

    static var initialState: AppSessionState {
        return .loading
    }

    case loading
    case unlocked(fromLock: Bool)
    case locked

    enum Events {
        case start
        case lock
        case unlock
    }
}

extension AppSessionState: ReducableState {
    typealias State = AppSessionState

    static func reduce(_ state: AppSessionState, _ event: AppSessionState.Events) -> AppSessionState {
        switch (state, event) {
        case (.loading, .start):
            return .unlocked(fromLock: false)
        case (_ , .lock):
            return .locked
        case (_ , .unlock):
            return .unlocked(fromLock: true)
        default:
            return state
        }
    }
}
