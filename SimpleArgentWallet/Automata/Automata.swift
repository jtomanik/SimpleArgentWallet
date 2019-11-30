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

public typealias AutomataState = ImperativeStatechartController

public protocol ReactiveStateController {
    associatedtype Controller: ImperativeStatechartController
    associatedtype Commands: InterpretableCommand

    typealias Middleware = (Controller.State.Events) -> Observable<Controller.State.Events>
    typealias Request = (Controller.State) -> Observable<Controller.State.Events>

    var commands: PublishSubject<Commands> { get }
    var output: Observable<Controller.State.Actions> { get }

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

extension ReactiveStateController where Self.Commands == Self.Controller.State.Events {

    func interpret(_ command: Self.Commands) -> Self.Controller.State.Events {
        return command
    }
}

// MARK: Implementations
public class Automata<Controller: ImperativeStatechartController, Commands: InterpretableCommand>: ReactiveStateController where Commands.State == Controller.State {

    public let commands: PublishSubject<Commands>

    public var output: Observable<Controller.State.Actions> {
        return state
            .asObservable()
            .map { $0.action }
            .filterNil()
    }

    public let events: PublishSubject<Controller.State.Events>
    private let state = BehaviorSubject(value: Controller())

    private let middleware: Middleware
    private let request: Request
    private let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)

    private let disposeBag = DisposeBag()

    init(middleware: Middleware? = nil,
        request: Request? = nil,
        scheduler: ImmediateSchedulerType = MainScheduler.instance) {

        self.commands = PublishSubject()
        self.events = PublishSubject()

        self.middleware = middleware ?? { event in return Observable.just(event) }
        self.request = request ?? { _ in return Observable.empty() }

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
            .do(onNext: { [weak self] controller in
                self?.executeRequests(for: controller.state)
            })
            .subscribe(state)
            .disposed(by: disposeBag)
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
}

extension Automata {

    typealias EventFilter<P> = (Controller.State.Events) -> P?
    typealias MiddlewareClosure<P> = (Controller.State.Events, P) -> Observable<Controller.State.Events>
    typealias StateFilter<P> = (Controller.State) -> P?
    typealias RequestClosure<P> = (Controller.State, P) -> Observable<Controller.State.Events>

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping ((T) -> (Controller.State.Events?))) -> Middleware {
        let closure: MiddlewareClosure<T> = { (event, value) -> Observable<Controller.State.Events> in
            guard let e = execute(value) else {
                return Observable.just(event)
            }
            return Observable.just(e)
        }
        return makeMiddleware(predicate: filter, closure)
    }

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping MiddlewareClosure<T>) -> Middleware {
        return makeMiddleware(predicate: filter, execute)
    }

    static func makeMiddleware<T>(predicate filter: @escaping EventFilter<T>, _ execute: @escaping MiddlewareClosure<T>) -> Middleware {
        return { event -> Observable<Controller.State.Events> in
            guard let p = filter(event) else {
                return Observable.just(event)
            }
            return execute(event, p)
        }
    }

    static func serialMiddlewares(from input: [Middleware]) -> Middleware {
        return { event -> Observable<Controller.State.Events> in
            return input.reduce(Observable.just(event)) { (acc, middleware) -> Observable<Controller.State.Events> in
                return acc.flatMap(middleware)
            }
        }
    }

    static func parallelMiddlewares(from input: [Middleware]) -> Middleware {
        return { event -> Observable<Controller.State.Events> in
            let sanitized = Automata.sanitize(middlewares: input)
            return Observable.from(sanitized)
                .map { $0(event) }
                .merge()
        }
    }

    private static func sanitize(middlewares array: [Middleware]) -> [Middleware] {
        guard !array.isEmpty else {
            func passthru(_ event: Controller.State.Events) -> Observable<Controller.State.Events> {
                return Observable.just(event)
            }

            return [passthru]
        }

        return array
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping ((T) -> (Controller.State.Events?))) -> Request {
        let closure: RequestClosure<T> = { (state, value) -> Observable<Controller.State.Events> in
            guard let e = execute(value) else {
                return Observable.empty()
            }
            return Observable.just(e)
        }
        return makeRequest(predicate: filter, closure)
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping RequestClosure<T>) -> Request {
        return makeRequest(predicate: filter, execute)
    }

    static func makeRequest<T>(predicate filter: @escaping StateFilter<T>, _ execute: @escaping RequestClosure<T>) -> Request {
        return { state -> Observable<Controller.State.Events> in
            guard let p = filter(state) else {
                return Observable.empty()
            }
            return execute(state, p)
        }
    }

    static func requests(from input: [Request]) -> Request {
        return { state -> Observable<Controller.State.Events> in
            let sanitized = Automata.sanitize(requests: input)
            return Observable.from(sanitized)
                .map { $0(state) }
                .merge()
        }
    }

    private static func sanitize(requests array: [Request]) -> [Request] {
        guard !array.isEmpty else {
            func passthru(_ state: Controller.State) -> Observable<Controller.State.Events> {
                return Observable.empty()
            }

            return [passthru]
        }

        return array
    }
}

