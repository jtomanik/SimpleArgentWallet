//
//  ArgentAccountCardViewController.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CardParts
import BlockiesSwift

extension Modules.Wallet {

    struct AccountCardModel: Equatable {
        let imageSeed: String?
        let name: String
        let balance: String
        let value: String
    }

    struct TransfersCardModel: Equatable {
        let isSendButtonEnabled: Bool
        let transactionHashes: [String]
    }

    struct TransactionsCardModel: Equatable {
        let isTransactionListExpanded: Bool
        let transactions: [TransactionCardModel]?
    }

    struct TransactionCardModel: Equatable {
        let from: String
        let contract: String
        let symbol: String
        let value: String
    }
}

class ArgentAccountCardController: CardPartsViewController {

    weak var viewModel: WalletViewModel!
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
        setupCallbacks()
    }

    func setupView() {
        let newState: CardState = .loading
        setupCardParts(ArgentAccountCardController.makeCardTitle(), forState: newState)
        state = .loading
        invalidateLayout()
    }

    func bindViewModel() {
        self.viewModel
            .displayModel
            .observeOn(MainScheduler.instance)
            .subscribeNext(weak: self, ArgentAccountCardController.update)
            .disposed(by: disposeBag)
    }

    func setupCallbacks() {
        self.cardTapped(forState: .empty) { [viewModel] in
            viewModel?.showTransactions()
        }

        self.cardTapped(forState: .hasData) { [viewModel] in
            viewModel?.hideStransactions()
        }
    }

    private func update(_ displayModel: Modules.Wallet.DisplayModel) {
        guard let account = displayModel.account else {
            setupView()
            return
        }

        let isExpanded = displayModel.transactions?.isTransactionListExpanded ?? false
        let newState: CardState = isExpanded ? .hasData : .empty

        var parts: [CardPartView] = []

        parts.append(contentsOf: ArgentAccountCardController.makeCardParts(from: account))

        if let transactions = displayModel.transactions {
            parts.append(contentsOf: ArgentAccountCardController.makeCardParts(from: transactions))
        }

        setupCardParts(parts, forState: newState)
        state = newState
        invalidateLayout()
    }
}

extension ArgentAccountCardController {

    private static let theme = WalletTheme()

    static func makeCardTitle() -> [CardPartView] {
        var parts: [CardPartView] = []

        let headerView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .right)
        headerView.leftTitleText = "Argent Wallet"
        headerView.leftTitleFont = theme.headerTextFont
        parts.append(headerView)

        return parts
    }

    static func makeCardParts(from model: Modules.Wallet.AccountCardModel) -> [CardPartView] {
        var parts: [CardPartView] = []

        parts.append(contentsOf: makeCardTitle())

        if let seed = model.imageSeed {
            let blockies = Blockies(seed: seed)

            let accountView = CardPartIconLabel()
            accountView.verticalPadding = 10
            accountView.padding = 0
            accountView.text = model.name
            accountView.textAlignment = .left
            accountView.font = theme.smallTextFont
            accountView.numberOfLines = 0
            accountView.iconPadding = 5
            accountView.icon = blockies.createImage()
            accountView.iconPosition = ( .left, .center )
            parts.append(accountView)
        }

        let ethBalanceView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 0))
        ethBalanceView.leftTitleText = "balance"
        ethBalanceView.leftTitleFont = theme.titleFont
        ethBalanceView.rightTitleText = model.balance
        ethBalanceView.rightTitleFont = theme.titleFont
        parts.append(ethBalanceView)

        let usdBalanceView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 0))
        usdBalanceView.leftTitleText = "value"
        usdBalanceView.leftTitleFont = theme.normalTextFont
        usdBalanceView.rightTitleText = model.value
        usdBalanceView.rightTitleFont = theme.normalTextFont
        parts.append(usdBalanceView)

        return parts
    }

    static func makeCardParts(from model: Modules.Wallet.TransactionsCardModel) -> [CardPartView] {
        var parts: [CardPartView] = []

        if let transactions = model.transfers {
            if model.isTransactionListExpanded {
                parts.append(contentsOf: makeTransfersList(from: transactions))
            } else {
                parts.append(CardPartSeparatorView())
                parts.append(makeTransactionsSummary(with: transactions.count))
            }
        }

        return parts
    }

    private static func makeTransactionsSummary(with count: Int) -> CardPartView {
        let transactionsSummaryView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 0))
        transactionsSummaryView.leftTitleText = "ERC20 transactions:"
        transactionsSummaryView.leftTitleFont = theme.normalTextFont
        transactionsSummaryView.rightTitleText = "\(count)"
        transactionsSummaryView.rightTitleFont = theme.normalTextFont
        return transactionsSummaryView
    }

    private static func makeTransfersList(from model: [Modules.Wallet.TransferCardModel]) -> [CardPartView] {
        var parts: [CardPartView] = []
        model.forEach { parts.append(contentsOf: makeTransferRow(from: $0)) }
        return parts
    }

    static private func makeTransferRow(from model: Modules.Wallet.TransferCardModel) -> [CardPartView] {
        var parts: [CardPartView] = []

        parts.append(CardPartSeparatorView())

        let blockies = Blockies(seed: model.from)
        let accountView = CardPartIconLabel()
        accountView.verticalPadding = 10
        accountView.padding = 0
        accountView.text = "from: \(model.from)"
        accountView.textAlignment = .left
        accountView.font = theme.smallTextFont
        accountView.numberOfLines = 0
        accountView.iconPadding = 5
        accountView.icon = blockies.createImage()
        accountView.iconPosition = ( .left, .center )
        parts.append(accountView)

        let tokenValueView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 70))
        tokenValueView.leftTitleText = "amount: \(model.value)"
        tokenValueView.leftTitleFont = theme.normalTextFont
        tokenValueView.rightTitleText = "token: \(model.symbol)"
        tokenValueView.rightTitleFont = theme.normalTextFont
        parts.append(tokenValueView)

        return parts
    }
}

extension ArgentAccountCardController: ShadowCardTrait {
    func shadowOffset() -> CGSize {
        return CGSize(width: 1.0, height: 1.0)
    }

    func shadowColor() -> CGColor {
        return UIColor.lightGray.cgColor
    }

    func shadowRadius() -> CGFloat {
        return 10.0
    }

    func shadowOpacity() -> Float {
        return 0.8
    }
}

extension ArgentAccountCardController: RoundedCardTrait {
    func cornerRadius() -> CGFloat {
        return 10.0
    }
}
