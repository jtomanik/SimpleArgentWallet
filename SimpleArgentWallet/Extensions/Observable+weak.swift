//
//  Observable+weak.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {

    fileprivate func weakify<Object: AnyObject, Input>(_ obj: Object, method: ((Object) -> (Input) -> Void)?) -> ((Input) -> Void) {
        return { [weak obj] value in
            guard let obj = obj else { return }
            method?(obj)(value)
        }
    }

    fileprivate func weakify<Object: AnyObject>(_ obj: Object, method: ((Object) -> () -> Void)?) -> (() -> Void) {
        return { [weak obj] in
            guard let obj = obj else { return }
            method?(obj)()
        }
    }

    public func subscribe<Object: AnyObject>(weak obj: Object, _ on: @escaping (Object) -> (Event<E>) -> Void) -> Disposable {
        return self.subscribe(weakify(obj, method: on))
    }

    public func subscribe<Object: AnyObject>(
        weak obj: Object,
        onNext: ((Object) -> (E) -> Void)? = nil,
        onError: ((Object) -> (Error) -> Void)? = nil,
        onCompleted: ((Object) -> () -> Void)? = nil,
        onDisposed: ((Object) -> () -> Void)? = nil
    ) -> Disposable {
        let disposable: Disposable

        if let disposed = onDisposed {
            disposable = Disposables.create(with: weakify(obj, method: disposed))
        } else {
            disposable = Disposables.create()
        }

        let observer = AnyObserver { [weak obj] (e: Event<E>) in
            guard let obj = obj else { return }
            switch e {
            case .next(let value):
                onNext?(obj)(value)
            case .error(let e):
                onError?(obj)(e)
                disposable.dispose()
            case .completed:
                onCompleted?(obj)()
                disposable.dispose()
            }
        }

        return Disposables.create(self.asObservable().subscribe(observer), disposable)
    }

    public func subscribeNext<Object: AnyObject>(weak obj: Object, _ onNext: @escaping (Object) -> (E) -> Void) -> Disposable {
        return self.subscribe(onNext: weakify(obj, method: onNext))
    }

    public func subscribeError<Object: AnyObject>(weak obj: Object, _ onError: @escaping (Object) -> (Error) -> Void) -> Disposable {
        return self.subscribe(onError: weakify(obj, method: onError))
    }

    public func subscribeCompleted<Object: AnyObject>(weak obj: Object, _ onCompleted: @escaping (Object) -> () -> Void) -> Disposable {
        return self.subscribe(onCompleted: weakify(obj, method: onCompleted))
    }
}

