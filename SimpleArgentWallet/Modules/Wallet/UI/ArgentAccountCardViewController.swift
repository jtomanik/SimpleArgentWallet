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
import BlockiesSwift

extension Modules.Wallet {

    struct AccountCardModel {
        let imageSeed: String?
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
        headerView.leftTitleText = "Argent Wallet"
        headerView.leftTitleFont = theme.headerTextFont
        parts.append(headerView)

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

}

