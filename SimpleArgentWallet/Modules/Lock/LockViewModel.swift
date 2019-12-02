//
//  LockViewModel.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

protocol RoutableLock {
    var route: Observable<Modules.Root.Routes> { get }
}

protocol LockViewModel: class, RoutableLock {
    var pinLength: Int { get }

    var displayModel: Observable<Modules.Lock.DisplayModel> { get }

    func tapped(_ digit: Int)
    func tappedClearLastDigit()
    func finishedShake()
}

protocol PinValidation {
    func validate(pin: [Int]) -> Observable<Bool>
}

extension Modules.Lock {

    enum State: FiniteStateType {

        static var pinLength: Int {
            return 4
        }

        static var initialState: State {
            return .initial(pinLength: pinLength)
        }

        case initial(pinLength: Int)
        case pin([Int])
        case invalid
        case valid

        enum Events {
            case digit(Int)
            case validating([Int])
            case back
            case reset
            case pinValid
            case pinInvalid
        }
    }
}

extension Modules.Lock.State: ReducableState {
    typealias State = Modules.Lock.State

    static func reduce(_ state: State, _ event: State.Events) -> State {
        switch (state, event) {
        case (.initial, .digit(let i)):
            return .pin([i])

        case (.pin(let digits), .digit(let i)):
            var newDigits = digits
            newDigits.append(i)
            return .pin(newDigits)

        case (.pin(let digits), .back):
            if digits.count > 0 {
                var newDigits = digits
                newDigits.removeLast()
                return .pin(newDigits)
            } else {
                return state
            }

        case (.pin, .pinValid):
            return .valid

        case (.pin, .pinInvalid):
            return .invalid

        case (_, .reset):
            return .pin([])

        default:
            return state
        }
    }
}

extension Modules.Lock.State: StatechartType, ActionableState {
    typealias Actions = Modules.Lock.State
}

extension Modules.Lock.State.Events: InterpretableCommand {
    typealias State = Modules.Lock.State
}

class PinLock: Automata<Modules.Lock.State, Modules.Lock.State.Events> {

    convenience init(validator: PinValidation) {

        let middleware = Statechart.makeMiddleware(when: { (event) -> [Int]? in
            guard case let .validating(input) = event else { return nil }; return input }
        ) { (input) -> Observable<Modules.Lock.State.Events> in

            return validator
                .validate(pin: input)
                .map { return $0 ? Statechart.Events.pinValid : Statechart.Events.pinInvalid }
        }

        let request = Statechart.makeRequest(when: { (state) -> [Int]? in
            guard case let .pin(input) = state, input.count == Statechart.pinLength else { return nil }; return input }
        ) { (input) -> Modules.Lock.State.Events in
                
            return Modules.Lock.State.Events.validating(input)
        }

        self.init(
            middleware: middleware,
            request: request)
    }
}

extension PinLock: LockViewModel {

    var pinLength: Int {
        return Statechart.State.pinLength
    }

    var displayModel: Observable<Modules.Lock.DisplayModel> {
        return self.output
            .map { PinLock.transform($0) }
            .filterNil()
    }

    func tapped(_ digit: Int) {
        self.handle(.digit(digit))
    }

    func tappedClearLastDigit() {
        self.handle(.back)
    }

    func finishedShake() {
        self.handle(.reset)
    }

    private static func transform(_ state: Statechart) -> Modules.Lock.DisplayModel? {
        switch state {
        case .initial:
            return Modules.Lock.DisplayModel(currentPINlength: 0, isWrongPIN: false)
        case .pin(let digits):
            return Modules.Lock.DisplayModel(currentPINlength: digits.count, isWrongPIN: false)
        case .invalid:
            return Modules.Lock.DisplayModel(currentPINlength: Modules.Lock.State.pinLength, isWrongPIN: true)
        default:
            return nil
        }
    }
}

extension PinLock: RoutableLock {

    var route: Observable<Modules.Root.Routes> {
        return self.output
            .map { PinLock.transform($0) }
            .filterNil()
    }

    private static func transform(_ state: Statechart) -> Modules.Root.Routes? {
        guard case .valid = state else {
            return nil
        }

        return .mainUI(fromLock: true)
    }
}
