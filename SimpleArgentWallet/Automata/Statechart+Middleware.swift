//
//  Statechart+Middleware.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 03/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

//MARK: Middleware helpers
extension StatechartType {

    public typealias Middleware = (State.Events) -> Observable<State.Events>
    public typealias Request = (State) -> Observable<State.Events>

    typealias EventFilter<P>                            = (State.Events) -> P?
    typealias MiddlewareClosure<P>                      = (State.Events, P) -> Observable<State.Events>
    typealias SimpleMiddlewareClosure<P>                = (P) -> Observable<State.Events>
    typealias MiddlewareFunction<P>                     = (State.Events, P) -> State.Events?
    typealias SimpleMiddlewareFunction<P>               = (P) -> State.Events?
    typealias NonOptionalMiddlewareFunction<P>          = (State.Events, P) -> State.Events
    typealias SimpleNonOptionalMiddlewareFunction<P>    = (P) -> State.Events

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
        return { event -> Observable<State.Events> in
            guard let p = filter(event) else {
                return Observable.just(event)
            }
            return execute(event, p)
        }
    }

    static func serialMiddlewares(from input: [Middleware]) -> Middleware {
        return { event -> Observable<State.Events> in
            return input.reduce(Observable.just(event)) { (acc, middleware) -> Observable<State.Events> in
                return acc.flatMap(middleware)
            }
        }
    }

    static func parallelMiddlewares(from input: [Middleware]) -> Middleware {
        return { event -> Observable<State.Events> in
            let sanitized = Self.sanitize(middlewares: input)
            return Observable.from(sanitized)
                .map { $0(event) }
                .merge()
        }
    }

    private static func sanitize(middlewares array: [Middleware]) -> [Middleware] {
        guard !array.isEmpty else {
            return [Self.passthroughMiddleware()]
        }

        return array
    }

    private static func convertMiddleware<T>(function: @escaping NonOptionalMiddlewareFunction<T>) -> MiddlewareClosure<T> {
        let converted: MiddlewareFunction<T> = { (event, value) -> State.Events? in
            return Optional.some(function(event, value))
        }
        return convertMiddleware(function: converted)
    }

    private static func convertMiddleware<T>(function: @escaping MiddlewareFunction<T>) -> MiddlewareClosure<T> {
        return { (event, value) -> Observable<State.Events> in
            guard let e = function(event, value) else {
                return Observable.empty()
            }
            return Observable.just(e)
        }
    }

    private static func expandMiddleware<T>(closure: @escaping SimpleMiddlewareClosure<T>) -> MiddlewareClosure<T> {
        return {(event, value) -> Observable<State.Events> in
            return closure(value)
        }
    }

    private static func expandMiddleware<T>(function: @escaping SimpleMiddlewareFunction<T>) -> MiddlewareFunction<T> {
        return {(event, value) -> State.Events? in
            return function(value)
        }
    }

    private static func expandMiddleware<T>(function: @escaping SimpleNonOptionalMiddlewareFunction<T>) -> NonOptionalMiddlewareFunction<T> {
        return {(event, value) -> State.Events in
            return function(value)
        }
    }
}
