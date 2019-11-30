//
//  RootWindow.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class RootWindow: UIWindow {

    let viewModel: RootViewModel
    let disposeBag = DisposeBag()

    init(frame: CGRect, viewModel: RootViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        self.backgroundColor = UIColor.systemPink
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
