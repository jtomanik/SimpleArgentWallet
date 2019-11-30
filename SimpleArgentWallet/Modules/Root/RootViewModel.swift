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
    var route: Observable<Modules.Root.Routes> { get }

    func start()
    func lock()
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

extension AppSessionState: StatechartType, ActionableState {
    typealias Actions = Modules.Root.Routes

    static func transform(_ state: AppSessionState) -> Modules.Root.Routes? {
        switch state {
        case .unlocked(let isFromLock):
            return .mainUI(fromLock: isFromLock)
        case .locked:
            return .lockedUI
        default:
            return nil
        }
    }
}

extension AppSessionState.Events: InterpretableCommand {
    typealias State = AppSessionState
}

class AppSession: Automata<AppSessionState, AppSessionState.Events>, RootViewModel {

    var route: Observable<Modules.Root.Routes> {
        return self.output
    }

    func start() {
        self.handle(.start)
    }

    func lock() {
        self.handle(.lock)
    }
}
