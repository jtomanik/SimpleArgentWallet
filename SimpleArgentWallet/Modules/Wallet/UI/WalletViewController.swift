//
//  WalletViewController.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import UIKit
import CardParts

import RxSwift
import RxCocoa

extension Modules.Wallet {

    struct DisplayModel {
        let account: AccountCardModel?
        let transactions: TransactionsCardModel?
    }
}

class WalletViewController: CardsViewController {

    let viewModel: WalletViewModel
    let disposeBag = DisposeBag()

    init(viewModel: WalletViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        bindViewModel()
    }

    func setupView() {
        loadCards(cards: [])
    }

    func bindViewModel() {
        self.viewModel
            .displayModel
            .observeOn(MainScheduler.instance)
            .subscribeNext(weak: self, WalletViewController.update)
            .disposed(by: disposeBag)
    }

    private func update(_ displayModel: Modules.Wallet.DisplayModel) {
        if let _ = displayModel.account {
            var cards: [CardPartsViewController] = []
            let accountCard = ArgentAccountCardController(viewModel: viewModel)
            cards.append(accountCard)
            loadCards(cards: cards)
        } else {
            setupView()
        }
    }
}

