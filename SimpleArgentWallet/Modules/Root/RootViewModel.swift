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

extension Modules.Root {

    enum State: FiniteStateType {

        static var initialState: State {
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
}

extension Modules.Root.State: ReducableState {
    typealias State = Modules.Root.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
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

extension Modules.Root.State: StatechartType, ActionableState {
    typealias Actions = Modules.Root.Routes

    static func transform(_ state: State) -> Modules.Root.Routes? {
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

extension Modules.Root.State.Events: InterpretableCommand {
    typealias State = Modules.Root.State
}

class AppSession: Automata<Modules.Root.State, Modules.Root.State.Events>, RootViewModel {

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
