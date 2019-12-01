//
//  WalletTheme.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 01/12/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import CardParts

class WalletTheme: CardPartsTheme {

    var cardsViewContentInsetTop: CGFloat = 0.0
    var cardsLineSpacing: CGFloat = 12

    var cardShadow: Bool = true
    var cardCellMargins: UIEdgeInsets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 12.0, right: 12.0)
    var cardPartMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)

    // CardPartSeparatorView
    var separatorColor: UIColor = UIColor.color(221, green: 221, blue: 221)
    var horizontalSeparatorMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)

    // CardPartTextView
    var smallTextFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(10))!
    var smallTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    var normalTextFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(14))!
    var normalTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    var titleTextFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: CGFloat(16))!
    var titleTextColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    var headerTextFont: UIFont = UIFont.turboGenericFontBlack(.header)
    var headerTextColor: UIColor = UIColor.turboCardPartTitleColor
    var detailTextFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(12))!
    var detailTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)

    // CardPartTitleView
    var titleFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: CGFloat(16))!
    var titleColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    var titleViewMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 10.0, right: 15.0)

    // CardPartButtonView
    var buttonTitleFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(17))!
    var buttonTitleColor: UIColor = UIColor(red: 69.0/255.0, green: 202.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    var buttonCornerRadius: CGFloat = CGFloat(0.0)

    // CardPartBarView
    var barBackgroundColor: UIColor = UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)
    var barColor: UIColor = UIColor.turboHeaderBlueColor
    var todayLineColor: UIColor = UIColor.Gray8
    var barHeight: CGFloat = 13.5
    var roundedCorners: Bool = true
    var showTodayLine: Bool = false

    // CardPartTableView
    var tableViewMargins: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 14.0, bottom: 0.0, right: 14.0)

    // CardPartTableViewCell and CardPartTitleDescriptionView
    var leftTitleFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(17))!
    var leftDescriptionFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(12))!
    var rightTitleFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(17))!
    var rightDescriptionFont: UIFont = UIFont(name: "HelveticaNeue", size: CGFloat(12))!
    var leftTitleColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    var leftDescriptionColor: UIColor = UIColor.color(169, green: 169, blue: 169)
    var rightTitleColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    var rightDescriptionColor: UIColor = UIColor.color(169, green: 169, blue: 169)
    var secondaryTitlePosition: CardPartSecondaryTitleDescPosition = .right

    public init() {

    }
}

extension UIColor {
    static var turboGenericGreyTextColor: UIColor { get { return UIColor.color(169, green: 169, blue: 169) } }
    static var turboCardPartTitleColor: UIColor { get { return UIColor.color(17, green: 17, blue: 17) } }
    static var turboCardPartTextColor: UIColor { get { return UIColor.color(136, green: 136, blue: 136) } }
    static var turboSeperatorColor: UIColor { get { return UIColor.color(221, green: 221, blue: 221) } }
    static var turboBlueColor: UIColor { get { return UIColor(red: 69.0/255.0, green: 202.0/255.0, blue: 230.0/255.0, alpha: 1.0) } }
    static var turboHeaderBlueColor: UIColor { get { return UIColor.colorFromHex(0x05A4B5) }}
    static var turboGreenColor: UIColor { get { return UIColor(red: 10.0/255.0, green: 199.0/255.0, blue: 117.0/255.0, alpha: 1.0) } }
    static var turboSeperatorGray: UIColor { get { return UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0) } }
    static var Black: UIColor { get { return UIColor.colorFromHex(0x000000) } }
    static var Gray0: UIColor { get { return UIColor.colorFromHex(0x333333) } }
    static var Gray1: UIColor { get { return UIColor.colorFromHex(0x666666) } }
    static var Gray2: UIColor { get { return UIColor.colorFromHex(0x999999) } }
    static var Gray3: UIColor { get { return UIColor.colorFromHex(0xCCCCCC) } }
    static var Gray4: UIColor { get { return UIColor.colorFromHex(0xDDDDDD) } }
    static var Gray5: UIColor { get { return UIColor.colorFromHex(0xF0F0F0) } }
    static var Gray6: UIColor { get { return UIColor.colorFromHex(0xF5F5F5) } }
    static var Gray7: UIColor { get { return UIColor.colorFromHex(0xE7E7E7) } }
    static var Gray8: UIColor { get { return UIColor.colorFromHex(0xB2B2B2) } }

    class func color(_ red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }

    static func colorFromHex(_ rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
}

enum FontSize: Int {
    case ultrabig = 48, header = 36, xx_Large = 28, x_Large = 24, large = 17, medium = 16, normal = 14, small = 12, x_Small = 10
}

extension UIFont {

    class func turboGenericFont(_ fontSize: FontSize) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize.rawValue), weight: UIFont.Weight.regular)
    }

    class func turboGenericFontBlack(_ fontSize: FontSize) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize.rawValue), weight: UIFont.Weight.black)
    }

    class func turboGenericFontBold(_ fontSize: FontSize) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize.rawValue), weight: UIFont.Weight.bold)
    }

    class func turboGenericMediumFont(_ fontSize: FontSize) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize.rawValue), weight: UIFont.Weight.medium)
    }

    class func turboGenericLightFont(_ fontSize: FontSize) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize.rawValue), weight: UIFont.Weight.light)
    }

    class func turboGenericFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.regular)
    }

    class func turboGenericMediumFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.medium)
    }

    class func turboGenericLightFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
    }

    static var titleTextMedium: UIFont { get { return UIFont.systemFont(ofSize: CGFloat(FontSize.x_Large.rawValue), weight: UIFont.Weight.medium) } }
}

