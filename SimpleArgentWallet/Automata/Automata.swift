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

    typealias Middleware = (Statechart.Events) -> Observable<Statechart.Events>
    typealias Request = (Statechart) -> Observable<Statechart.Events>

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

    private let middleware: Middleware
    private let request: Request
    private let backgroundScheduler = SerialDispatchQueueScheduler(qos: .default)

    private let disposeBag = DisposeBag()

    public init(
        stateController: GenericStatechart<Statechart>,
        middleware: Middleware? = nil,
        request: Request? = nil) {

        self.state = BehaviorSubject(value: stateController)
        self.commands = PublishSubject()
        self.events = PublishSubject()

        self.middleware = middleware ?? Automata.passthroughMiddleware()
        self.request = request ?? Automata.passthroughRequest()

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

    convenience init(middleware: Middleware?, request: Request?) {
        self.init(
        stateController: GenericStatechart<Statechart>(),
        middleware: middleware,
        request: request)
    }
}


//MARK: Middleware helpers
extension Automata {

    typealias EventFilter<P>                            = (Controller.State.Events) -> P?
    typealias MiddlewareClosure<P>                      = (Controller.State.Events, P) -> Observable<Controller.State.Events>
    typealias SimpleMiddlewareClosure<P>                = (P) -> Observable<Controller.State.Events>
    typealias MiddlewareFunction<P>                     = (Controller.State.Events, P) -> Controller.State.Events?
    typealias SimpleMiddlewareFunction<P>               = (P) -> Controller.State.Events?
    typealias NonOptionalMiddlewareFunction<P>          = (Controller.State.Events, P) -> Controller.State.Events
    typealias SimpleNonOptionalMiddlewareFunction<P>    = (P) -> Controller.State.Events

    static func passthroughMiddleware() -> Middleware {
        return { event in return Observable.just(event) }
    }

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping SimpleNonOptionalMiddlewareFunction<T>) -> Middleware {
        let callback = convertMiddleware(function: expandMiddleware(function: execute))
        return makeMiddleware(predicate: filter, callback)
    }

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping NonOptionalMiddlewareFunction<T>) -> Middleware {
        let callback = convertMiddleware(function: execute)
        return makeMiddleware(predicate: filter, callback)
    }

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping SimpleMiddlewareFunction<T>) -> Middleware {
        let callback = convertMiddleware(function: expandMiddleware(function: execute))
        return makeMiddleware(predicate: filter, callback)
    }

    static func makeMiddleware<T>(when filter: @escaping EventFilter<T>, then execute: @escaping SimpleMiddlewareClosure<T>) -> Middleware {
        let callback = expandMiddleware(closure: execute)
        return makeMiddleware(predicate: filter, callback)
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
            return [Automata.passthroughMiddleware()]
        }

        return array
    }

    private static func convertMiddleware<T>(function: @escaping NonOptionalMiddlewareFunction<T>) -> MiddlewareClosure<T> {
        let converted: MiddlewareFunction<T> = { (event, value) -> Controller.State.Events? in
            return Optional.some(function(event, value))
        }
        return convertMiddleware(function: converted)
    }

    private static func convertMiddleware<T>(function: @escaping MiddlewareFunction<T>) -> MiddlewareClosure<T> {
        return { (event, value) -> Observable<Controller.State.Events> in
            guard let e = function(event, value) else {
                return Observable.empty()
            }
            return Observable.just(e)
        }
    }

    private static func expandMiddleware<T>(closure: @escaping SimpleMiddlewareClosure<T>) -> MiddlewareClosure<T> {
        return {(event, value) -> Observable<Controller.State.Events> in
            return closure(value)
        }
    }

    private static func expandMiddleware<T>(function: @escaping SimpleMiddlewareFunction<T>) -> MiddlewareFunction<T> {
        return {(event, value) -> Controller.State.Events? in
            return function(value)
        }
    }

    private static func expandMiddleware<T>(function: @escaping SimpleNonOptionalMiddlewareFunction<T>) -> NonOptionalMiddlewareFunction<T> {
        return {(event, value) -> Controller.State.Events in
            return function(value)
        }
    }
}

//MARK: Request helpers
extension Automata {

    typealias StateFilter<P>                        = (Controller.State) -> P?
    typealias RequestClosure<P>                     = (Controller.State, P) -> Observable<Controller.State.Events>
    typealias SimpleRequestClosure<P>               = (P) -> Observable<Controller.State.Events>
    typealias RequestFunction<P>                    = (Controller.State, P) -> Controller.State.Events?
    typealias SimpleRequestFunction<P>              = (P) -> Controller.State.Events?
    typealias NonOptionalRequestFunction<P>         = (Controller.State, P) -> Controller.State.Events
    typealias SimpleNonOptionalRequestFunction<P>   = (P) -> Controller.State.Events

    static func passthroughRequest() -> Request {
        return { _ in return Observable.empty() }
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping SimpleNonOptionalRequestFunction<T>) -> Request {
        let callback = convertRequest(function: expandRequest(function: execute))
        return makeRequest(predicate: filter, callback)
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping NonOptionalRequestFunction<T>) -> Request {
        let callback = convertRequest(function: execute)
        return makeRequest(predicate: filter, callback)
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping SimpleRequestFunction<T>) -> Request {
        let callback = convertRequest(function: expandRequest(function: execute))
        return makeRequest(predicate: filter, callback)
    }

    static func makeRequest<T>(when filter: @escaping StateFilter<T>, then execute: @escaping SimpleRequestClosure<T>) -> Request {
        let callback = expandRequest(closure: execute)
        return makeRequest(predicate: filter, callback)
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
            return [Automata.passthroughRequest()]
        }

        return array
    }

    private static func convertRequest<T>(function: @escaping NonOptionalRequestFunction<T>) -> RequestClosure<T> {
        let converted: RequestFunction<T> = { (state, value) -> Controller.State.Events? in
            return Optional.some(function(state, value))
        }
        return convertRequest(function: converted)
    }

    private static func convertRequest<T>(function: @escaping RequestFunction<T>) -> RequestClosure<T> {
        return { (state, value) -> Observable<Controller.State.Events> in
            guard let e = function(state, value) else {
                return Observable.empty()
            }
            return Observable.just(e)
        }
    }

    private static func expandRequest<T>(closure: @escaping SimpleRequestClosure<T>) -> RequestClosure<T> {
        return {(state, value) -> Observable<Controller.State.Events> in
            return closure(value)
        }
    }

    private static func expandRequest<T>(function: @escaping SimpleRequestFunction<T>) -> RequestFunction<T> {
        return {(state, value) -> Controller.State.Events? in
            return function(value)
        }
    }

    private static func expandRequest<T>(function: @escaping SimpleNonOptionalRequestFunction<T>) -> NonOptionalRequestFunction<T> {
        return {(state, value) -> Controller.State.Events in
            return function(value)
        }
    }
}
