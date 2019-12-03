//
//  Statechart+Request.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 03/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

//MARK: Request helpers
extension StatechartType {

    typealias StateFilter<P>                        = (State) -> P?
    typealias RequestClosure<P>                     = (State, P) -> Observable<State.Events>
    typealias SimpleRequestClosure<P>               = (P) -> Observable<State.Events>
    typealias RequestFunction<P>                    = (State, P) -> State.Events?
    typealias SimpleRequestFunction<P>              = (P) -> State.Events?
    typealias NonOptionalRequestFunction<P>         = (State, P) -> State.Events
    typealias SimpleNonOptionalRequestFunction<P>   = (P) -> State.Events

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
        return { state -> Observable<State.Events> in
            guard let p = filter(state) else {
                return Observable.empty()
            }
            return execute(state, p)
        }
    }

    static func requests(from input: [Request]) -> Request {
        return { state -> Observable<State.Events> in
            let sanitized = Self.sanitize(requests: input)
            return Observable.from(sanitized)
                .map { $0(state) }
                .merge()
        }
    }

    private static func sanitize(requests array: [Request]) -> [Request] {
        guard !array.isEmpty else {
            return [Self.passthroughRequest()]
        }

        return array
    }

    private static func convertRequest<T>(function: @escaping NonOptionalRequestFunction<T>) -> RequestClosure<T> {
        let converted: RequestFunction<T> = { (state, value) -> State.Events? in
            return Optional.some(function(state, value))
        }
        return convertRequest(function: converted)
    }

    private static func convertRequest<T>(function: @escaping RequestFunction<T>) -> RequestClosure<T> {
        return { (state, value) -> Observable<State.Events> in
            guard let e = function(state, value) else {
                return Observable.empty()
            }
            return Observable.just(e)
        }
    }

    private static func expandRequest<T>(closure: @escaping SimpleRequestClosure<T>) -> RequestClosure<T> {
        return {(state, value) -> Observable<State.Events> in
            return closure(value)
        }
    }

    private static func expandRequest<T>(function: @escaping SimpleRequestFunction<T>) -> RequestFunction<T> {
        return {(state, value) -> State.Events? in
            return function(value)
        }
    }

    private static func expandRequest<T>(function: @escaping SimpleNonOptionalRequestFunction<T>) -> NonOptionalRequestFunction<T> {
        return {(state, value) -> State.Events in
            return function(value)
        }
    }
}
