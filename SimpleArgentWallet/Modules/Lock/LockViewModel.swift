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

enum LockState: FiniteStateType {

    static var pinLength: Int {
        return 4
    }

    static var initialState: LockState {
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
//        case biometrics
    }
}

extension LockState: ReducableState {
    typealias State = LockState

    static func reduce(_ state: LockState, _ event: LockState.Events) -> LockState {
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

extension LockState: StatechartType, ActionableState {
    typealias Actions = LockState
}

extension LockState.Events: InterpretableCommand {
    typealias State = LockState
}

class PinLock: Automata<LockState, LockState.Events> {

    convenience init(validator: PinValidation) {
        self.init(
            middleware: PinLock.middlewarePinValidation(with: validator),
            request: PinLock.requestPinValidation(digits: Statechart.pinLength))
    }

    static func middlewarePinValidation(with validator: PinValidation) -> Middleware {
        return { event -> Observable<LockState.Events> in
            guard case let .validating(input) = event else {
                return Observable.just(event)
            }
            return validator
                .validate(pin: input)
                .map { return $0 ? LockState.Events.pinValid : LockState.Events.pinInvalid }
        }
    }

    static func requestPinValidation(digits: Int) -> Request {
        return { state -> Observable<LockState.Events> in
            guard case let .pin(input) = state,
                input.count == digits else {
                return Observable.empty()
            }
            return Observable.just(LockState.Events.validating(input))
        }
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

    private static func transform(_ state: LockState) -> Modules.Lock.DisplayModel? {
        switch state {
        case .initial:
            return Modules.Lock.DisplayModel(currentPINlength: 0, isWrongPIN: false)
        case .pin(let digits):
            return Modules.Lock.DisplayModel(currentPINlength: digits.count, isWrongPIN: false)
        case .invalid:
            return Modules.Lock.DisplayModel(currentPINlength: LockState.pinLength, isWrongPIN: true)
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

    private static func transform(_ state: LockState) -> Modules.Root.Routes? {
        guard case .valid = state else {
            return nil
        }

        return .mainUI(fromLock: true)
    }
}
