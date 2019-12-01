//
//  NetworkRequester.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//


import RxSwift

protocol NetworkRequestProvider {
    func request(_ urlRequest: URLRequest) -> Observable<Data>
    func parse(json data: Data) -> Any?
}

class NetworkRequester: NetworkRequestProvider {

    func request(_ request: URLRequest) -> Observable<Data> {
        let observable =  Observable<Data>.create { observer -> Disposable in
            let dataTask: URLSessionDataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    observer.onError(error)
                    return
                }
                guard let data = data else {
                   return observer.onError(NSError(domain: "dataNilError", code: -10001, userInfo: nil))
                }
                observer.onNext(data)
                observer.onCompleted()
            }
            dataTask.resume()
            return Disposables.create {
                dataTask.cancel()
            }
        }

        return observable.observeOn(MainScheduler.instance)
    }

    func parse(json data: Data) -> Any? {
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
}
