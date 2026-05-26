//
//  Font+.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/11/25.
//

import SwiftUI

private enum FontFamily {
    static let main = "Pretendard"
}

private enum FontWeight {
    static let bold = "Bold"
    static let semibold = "SemiBold"
    static let medium = "Medium"
    static let regular = "Regular"
}

public extension Font {
    private static func custom(_ family: String, _ weight: String, size: CGFloat) -> Font {
        Font.custom("\(family)-\(weight)", size: size)
    }

    //TODO: - 안쓰는 폰트 점진적 삭제
    static let head_bold_26 = custom(FontFamily.main, FontWeight.bold, size: 26)
    static let head_bold_20 = custom(FontFamily.main, FontWeight.bold, size: 20)

    static let title_semibold_22 = custom(FontFamily.main, FontWeight.semibold, size: 22)
    static let title_semibold_20 = custom(FontFamily.main, FontWeight.semibold, size: 20)
    static let title_semibold_18 = custom(FontFamily.main, FontWeight.semibold, size: 18)
    static let title_semibold_16 = custom(FontFamily.main, FontWeight.semibold, size: 16)

    static let body1_medium_18 = custom(FontFamily.main, FontWeight.medium, size: 18)
    static let body1_medium_14 = custom(FontFamily.main, FontWeight.medium, size: 14)

    static let body2_regular_16 = custom(FontFamily.main, FontWeight.regular, size: 16)
    static let body2_regular_14 = custom(FontFamily.main, FontWeight.regular, size: 14)

    static let caption_regular_12 = custom(FontFamily.main, FontWeight.regular, size: 12)

    // title
    static let t_bold_24 = custom(FontFamily.main, FontWeight.bold, size: 24)
    static let t_bold_22 = custom(FontFamily.main, FontWeight.bold, size: 22)
    static let t_bold_20 = custom(FontFamily.main, FontWeight.bold, size: 20)

    // subtitle
    static let st_semibold_20 = custom(FontFamily.main, FontWeight.semibold, size: 20)
    static let st_semibold_18 = custom(FontFamily.main, FontWeight.semibold, size: 18)
    static let st_semibold_16 = custom(FontFamily.main, FontWeight.semibold, size: 16)

    // body
    static let bd_medium_16 = custom(FontFamily.main, FontWeight.medium, size: 16)
    static let bd_medium_14 = custom(FontFamily.main, FontWeight.medium, size: 14)

    // caption
    static let c_regular_14 = custom(FontFamily.main, FontWeight.regular, size: 14)
    static let c_regular_12 = custom(FontFamily.main, FontWeight.regular, size: 12)

    // button
    static let bt_bold_20 = custom(FontFamily.main, FontWeight.bold, size: 20)
    static let bt_semibold_20 = custom(FontFamily.main, FontWeight.semibold, size: 20)
    static let bt_medium_20 = custom(FontFamily.main, FontWeight.medium, size: 20)
    static let bt_bold_18 = custom(FontFamily.main, FontWeight.bold, size: 18)
    static let bt_semibold_18 = custom(FontFamily.main, FontWeight.semibold, size: 18)
    static let bt_medium_18 = custom(FontFamily.main, FontWeight.medium, size: 18)
}

public struct TypographyStyle {
    public let font: Font
    public let fontSize: CGFloat
    public let weight: UIFont.Weight
    public let letterSpacingPercent: CGFloat
    public let lineHeightPercent: CGFloat

    public init(font: Font, fontSize: CGFloat, weight: UIFont.Weight, letterSpacingPercent: CGFloat, lineHeightPercent: CGFloat) {
        self.font = font
        self.fontSize = fontSize
        self.weight = weight
        self.letterSpacingPercent = letterSpacingPercent
        self.lineHeightPercent = lineHeightPercent
    }

     public static let headBold26 = TypographyStyle(
         font: .head_bold_26,
         fontSize: 26,
         weight: .bold,
         letterSpacingPercent: -2,
         lineHeightPercent: 130
     )
     
     public static let headBold20 = TypographyStyle(
         font: .head_bold_20,
         fontSize: 20,
         weight: .bold,
         letterSpacingPercent: -3,
         lineHeightPercent: 130
     )
     
     public static let titleSemibold22 = TypographyStyle(
         font: .title_semibold_22,
         fontSize: 22,
         weight: .semibold,
         letterSpacingPercent: -3,
         lineHeightPercent: 150
     )
     
     public static let titleSemibold20 = TypographyStyle(
         font: .title_semibold_20,
         fontSize: 20,
         weight: .semibold,
         letterSpacingPercent: -3,
         lineHeightPercent: 150
     )
     
     public static let titleSemibold18 = TypographyStyle(
         font: .title_semibold_18,
         fontSize: 18,
         weight: .semibold,
         letterSpacingPercent: -3,
         lineHeightPercent: 150
     )
     
     public static let titleSemibold16 = TypographyStyle(
         font: .title_semibold_16,
         fontSize: 16,
         weight: .semibold,
         letterSpacingPercent: -2,
         lineHeightPercent: 150
     )
     
     public static let bodyMedium18 = TypographyStyle(
         font: .body1_medium_18,
         fontSize: 18,
         weight: .medium,
         letterSpacingPercent: -1,
         lineHeightPercent: 150
     )
     
     public static let bodyMedium14 = TypographyStyle(
         font: .body1_medium_14,
         fontSize: 14,
         weight: .medium,
         letterSpacingPercent: -1,
         lineHeightPercent: 150
     )
     
     public static let bodyRegular16 = TypographyStyle(
         font: .body2_regular_16,
         fontSize: 16,
         weight: .regular,
         letterSpacingPercent: -1,
         lineHeightPercent: 100
     )
     
     public static let bodyRegular14 = TypographyStyle(
         font: .body2_regular_14,
         fontSize: 14,
         weight: .regular,
         letterSpacingPercent: -1,
         lineHeightPercent: 150
     )
     
     public static let captionRegular12 = TypographyStyle(
         font: .caption_regular_12,
         fontSize: 12,
         weight: .regular,
         letterSpacingPercent: -1,
         lineHeightPercent: 130
     )
}

public extension Text {
    private func applyTypography(_ style: TypographyStyle) -> some View {
        self.font(style.font)
            .kerning(TypographyHelper.customLetterSpacing(
                fontSize: style.fontSize,
                percent: style.letterSpacingPercent
            ))
            .lineSpacing(TypographyHelper.customLineHeight(
                fontSize: style.fontSize,
                weight: style.weight,
                targetLineHeightPercent: style.lineHeightPercent
            ))
    }
    
    func headBold26() -> some View {
        applyTypography(.headBold26)
    }
    
    func headBold20() -> some View {
        applyTypography(.headBold20)
    }
    
    func titleSemibold22() -> some View {
        applyTypography(.titleSemibold22)
    }
    
    func titleSemibold20() -> some View {
        applyTypography(.titleSemibold20)
    }
    
    func titleSemibold18() -> some View {
        applyTypography(.titleSemibold18)
    }
    
    func titleSemibold16() -> some View {
        applyTypography(.titleSemibold16)
    }
    
    func bodyMedium18() -> some View {
        applyTypography(.bodyMedium18)
    }
    
    func bodyMedium14() -> some View {
        applyTypography(.bodyMedium14)
    }
    
    func bodyRegular16() -> some View {
        applyTypography(.bodyRegular16)
    }
    
    func bodyRegular14() -> some View {
        applyTypography(.bodyRegular14)
    }
    
    func captionRegular12() -> some View {
        applyTypography(.captionRegular12)
    }
    
    func tBold24() -> some View {
            self.font(.t_bold_24)
        }
    
    func tBold22() -> some View {
            self.font(.t_bold_22)
        }
    
    func tBold20() -> some View {
            self.font(.t_bold_20)
        }
    
    func stSemibold20() -> some View {
        self.font(.st_semibold_20)
    }
    
    func stSemibold18() -> some View {
        self.font(.st_semibold_18)
    }
    
    func stSemibold16() -> some View {
        self.font(.st_semibold_16)
    }
    
    func bdMedium16() -> some View {
        self.font(.bd_medium_16)
    }
    
    func bdMedium16_22() -> some View {
        self.font(.bd_medium_16)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 16,
                weight: .medium,
                targetLineHeight: 22)
            )
    }
    
    func bdMedium14() -> some View {
        self.font(.bd_medium_14)
    }
    
    func bdMedium14_20() -> some View {
        self.font(.bd_medium_14)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 14,
                weight: .medium,
                targetLineHeight: 20)
            )
    }
    
    func cRegular14() -> some View {
        self.font(.c_regular_14)
    }
    
    func cRegular12() -> some View {
        self.font(.c_regular_12)
    }
    
    func btBold20() -> some View {
        self.font(.bt_bold_20)
    }
    
    func btBold20_24() -> some View {
        self.font(.bt_bold_20)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 20,
                weight: .bold,
                targetLineHeight: 24)
            )
    }
    
    func btSemiBold20() -> some View {
        self.font(.bt_semibold_20)
    }
    
    func btSemiBold20_24() -> some View {
        self.font(.bt_semibold_20)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 20,
                weight: .semibold,
                targetLineHeight: 24)
            )
    }
    
    func btMedium20_24() -> some View {
        self.font(.bt_medium_20)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 20,
                weight: .medium,
                targetLineHeight: 24)
            )
    }
    
    func btMedium20_20() -> some View {
        self.font(.bt_medium_20)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 20,
                weight: .medium,
                targetLineHeight: 20)
            )
    }
    
    func btBold18_24() -> some View {
        self.font(.bt_bold_18)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .bold,
                targetLineHeight: 24)
            )
    }
    
    func btBold18_20() -> some View {
        self.font(.bt_bold_18)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .bold,
                targetLineHeight: 20)
            )
    }
    
    func btSemiBold18_24() -> some View {
        self.font(.bt_semibold_20)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .semibold,
                targetLineHeight: 24)
            )
    }
    
    func btSemiBold18_20() -> some View {
        self.font(.bt_semibold_18)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .semibold,
                targetLineHeight: 20)
            )
    }
    
    
    func btMedium18_24() -> some View {
        self.font(.bt_medium_18)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .medium,
                targetLineHeight: 24)
            )
    }
    
    
    func btMedium18_20() -> some View {
        self.font(.bt_medium_18)
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 18,
                weight: .medium,
                targetLineHeight: 20)
            )
    }
    
    
    
}

public struct TypographyHelper {
    public static func customLetterSpacing(fontSize: CGFloat, percent: CGFloat) -> CGFloat {
        return fontSize * (percent / 100)
    }
    
    public static func customLineHeight(
        fontSize: CGFloat,
        weight: UIFont.Weight,
        targetLineHeightPercent: CGFloat
    ) -> CGFloat {
        let UIFont = UIFont.systemFont(ofSize: fontSize, weight: weight)
        let defaultLineHeight = UIFont.lineHeight
        let targetLineHeight = fontSize * (targetLineHeightPercent / 100)
        let additionalSpacing = targetLineHeight - defaultLineHeight
        return max(0, additionalSpacing)
    }
    
    public static func calculateLineSpacing(
        fontSize: CGFloat,
        weight: UIFont.Weight,
        targetLineHeight: CGFloat
    ) -> CGFloat {
        let uiFont = UIFont.systemFont(ofSize: fontSize, weight: weight)
        let defaultLineHeight = uiFont.lineHeight
        let additionalSpacing = targetLineHeight - defaultLineHeight
        return max(0, additionalSpacing)
    }
}
