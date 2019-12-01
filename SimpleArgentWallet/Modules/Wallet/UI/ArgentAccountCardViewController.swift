//
//  ArgentAccountCardViewController.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import RxSwift
import CardParts

extension Modules.Wallet {

    struct AccountCardModel {
        let name: String
        let balance: String
        let value: String
    }
}

class ArgentAccountCardController: CardPartsViewController {

    private let cardModel: Modules.Wallet.AccountCardModel

    init(cardModel: Modules.Wallet.AccountCardModel) {
        self.cardModel = cardModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    func setupView() {
        setupCardParts(ArgentAccountCardController.build(from: cardModel))
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

extension ArgentAccountCardController {

    static func build(from model: Modules.Wallet.AccountCardModel) -> [CardPartView] {
        let theme = WalletTheme()
        var parts: [CardPartView] = []

        let headerView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .right)
        headerView.leftTitleText = "Wallet Balance"
        headerView.leftTitleFont = theme.headerTextFont
        parts.append(headerView)

        let accountLabelView = CardPartTextView(type: .normal)
        accountLabelView.text = model.name
        parts.append(accountLabelView)

        let ethBalanceView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 0))
        ethBalanceView.leftTitleText = model.balance
        ethBalanceView.leftTitleFont = theme.titleFont
        ethBalanceView.rightTitleText = "ETH"
        ethBalanceView.rightTitleFont = theme.titleFont
        parts.append(ethBalanceView)

        let usdBalanceView = CardPartTitleDescriptionView(titlePosition: .top, secondaryPosition: .center(amount: 0))
        usdBalanceView.leftTitleText = model.value
        usdBalanceView.leftTitleFont = theme.normalTextFont
        usdBalanceView.rightTitleText = "USD"
        usdBalanceView.rightTitleFont = theme.normalTextFont
        parts.append(usdBalanceView)

        return parts
    }

}

