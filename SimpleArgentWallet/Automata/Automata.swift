//
//  Automata.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Definitions

public protocol FiniteStateType: Equatable {
    associatedtype Events

    static var initialState: Self { get }
}

public protocol ReducableState {
    associatedtype State: FiniteStateType

    static func reduce(_ state: State, _ event: State.Events) -> State
}

public protocol ActionableState {
    associatedtype State: StatechartType

    static func transform(_ state: State) -> State.Actions?
}

public protocol BroadcastableState {
    associatedtype State: FiniteStateType

    static func broadcast(_ state: State) -> State.Events?
}

public protocol StatechartType: ReducableState, ActionableState where State == Self {
    associatedtype Actions: Equatable

}

public protocol ImperativeStatechartController {
    associatedtype State: StatechartType

    typealias Reducer = (State, State.Events) -> State
    typealias Transformer = (State) -> State.Actions?
    typealias Broadcaster = (State) -> State.Events?

    var state: State { get }
    var action: State.Actions? { get }

    init()

    mutating func handle(event: State.Events)
}

public struct GenericStatechart<State: StatechartType>: ImperativeStatechartController {

    public var action: State.Actions? {
        return State.transform(state)
    }

    public var state: State = State.initialState

    public init() {
    }

    mutating public func handle(event: State.Events) {
        state = State.reduce(state, event)
    }
}

public protocol InterpretableCommand {
    associatedtype State: FiniteStateType

    static func interpret(_ command: Self) -> State.Events
}

public protocol ReactiveStateController {
    associatedtype Statechart: StatechartType
    associatedtype Commands: InterpretableCommand

    var commands: PublishSubject<Commands> { get }
    var output: Observable<Statechart.Actions> { get }

    func handle(_ command: Commands)
}

// MARK: Default protocol implementations

extension ReducableState {

    static func reduce(_ state: State, _ event: State.Events) -> State {
        return state
    }
}

extension BroadcastableState {

    static func broadcast(_ state: State) -> State.Events? {
        return nil
    }
}

extension ActionableState {

    static func transform(_ state: State) -> State.Actions? {
        return nil
    }
}

extension StatechartType where Self.Actions == Self {

    static func transform(_ state: Self) -> State.Actions? {
        return state
    }
}

extension InterpretableCommand where Self == State.Events {

    static func interpret(_ command: Self) -> State.Events {
        return command
    }
}

// MARK: Implementations
public class Automata<Statechart: StatechartType, Commands: InterpretableCommand>: ReactiveStateController where Commands.State == Statechart.State {

    typealias Controller = GenericStatechart<Statechart>

    public let commands: PublishSubject<Commands>

    public var output: Observable<Statechart.State.Actions> {
        return state
            .asObservable()
            .map { $0.action }
            .filterNil()
    }

    public let events: PublishSubject<Statechart.State.Events>
    private let state: BehaviorSubject<Controller>

    private let middleware: Statechart.Middleware
    private let request: Statechart.Request
    private let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)

    private let disposeBag = DisposeBag()

    public init(
        stateController: GenericStatechart<Statechart>,
        middleware: Statechart.Middleware? = nil,
        request: Statechart.Request? = nil) {

        self.state = BehaviorSubject(value: stateController)
        self.commands = PublishSubject()
        self.events = PublishSubject()

        self.middleware = middleware ?? Statechart.passthroughMiddleware()
        self.request = request ?? Statechart.passthroughRequest()

        commands
            .asObservable()
            .map { Commands.interpret($0) }
            .subscribe(events)
            .disposed(by: disposeBag)

        events
            .asObservable()
            .flatMap { self.middleware($0) }
            .observeOn(MainScheduler.asyncInstance)
            .withLatestFrom(state) { ($1, $0) }
            .map { self.update($0.0, $0.1)}
            .distinctUntilChanged { $0.state == $1.state }
            .do(onNext: { [weak self] controller in
                self?.executeRequests(for: controller.state)
            })
            .subscribe(state)
            .disposed(by: disposeBag)

        executeRequests(for: stateController.state)
    }

    public func handle(_ command: Commands) {
        commands.onNext(command)
    }

    private func update(_ controller: Controller, _ event: Controller.State.Events) -> Controller {
        var c = controller
        c.handle(event: event)
        return c
    }

    private func executeRequests(for state: Controller.State) {
        request(state)
            .subscribe(onNext: { [events] (event) in
                events.onNext(event)
            })
            .disposed(by: disposeBag)
    }
    
    convenience init() {
        self.init(
        stateController: GenericStatechart<Statechart>(),
        middleware: nil,
        request: nil)
    }

    convenience init(middleware: Statechart.Middleware?, request: Statechart.Request?) {
        self.init(
        stateController: GenericStatechart<Statechart>(),
        middleware: middleware,
        request: request)
    }
}
