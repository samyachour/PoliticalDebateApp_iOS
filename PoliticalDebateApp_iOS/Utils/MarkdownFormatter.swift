//
//  MarkdownFormatter.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/8/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

struct MarkDownFormatter {

    private init() {}

    private enum Constants {
        static let boldKey = "**"
        static let italicsKey = "*"
    }

    static func format(_ sourceString: String?,
                       with regularAttributes: [NSAttributedString.Key: Any],
                       hyperlinks: [PointHyperlink]? = nil) -> NSMutableAttributedString? {
        guard let sourceString = sourceString,
            let regularFontSize = (regularAttributes[.font] as? UIFont)?.pointSize else {
            return nil
        }

        var attributedString = NSMutableAttributedString(string: sourceString, attributes: regularAttributes)
        attributedString = format(attributedString, between: Constants.boldKey,
                                  formattedAttributes: [NSAttributedString.Key.font: UIFont.primaryBold(regularFontSize)])
        attributedString = format(attributedString, between: Constants.italicsKey,
                                  formattedAttributes: [NSAttributedString.Key.font: UIFont.primaryLightItalic(regularFontSize)])
        if let hyperlinks = hyperlinks {
            attributedString = format(attributedString, with: hyperlinks)
        }
        return attributedString
    }

    private static func format(_ attributedString: NSMutableAttributedString,
                               between key: String,
                               formattedAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        var compatibleSourceString = NSString(string: attributedString.string) // NSAttributedString requires NSRange which only comes from NSString

        var range1: NSRange
        var range2: NSRange
        var newStartIndex: Int

        while true {
            range1 = compatibleSourceString.range(of: key)
            newStartIndex = range1.location + range1.length
            guard range1.location != NSNotFound else { break }

            range2 = compatibleSourceString.range(of: key,
                                                  range: NSRange(location: newStartIndex,
                                                                 length: compatibleSourceString.length - newStartIndex))
            guard range2.location != NSNotFound else { break }

            attributedString.addAttributes(formattedAttributes,
                                           range: NSRange(location: newStartIndex,
                                                          length: range2.location - newStartIndex))

            attributedString.replaceCharacters(in: range1, with: "")
            attributedString.replaceCharacters(in: NSRange(location: range2.location - range1.length,
                                                           length: range2.length),
                                               with: "")
            compatibleSourceString = compatibleSourceString.replacingCharacters(in: range1, with: "") as NSString
            compatibleSourceString = compatibleSourceString.replacingCharacters(in: NSRange(location: range2.location - range1.length,
                                                                                            length: range2.length),
                                                                                with: "") as NSString

        }

        return attributedString
    }

    private static func format(_ attributedString: NSMutableAttributedString, with hyperlinks: [PointHyperlink]) -> NSMutableAttributedString {
       let compatibleSourceString = NSString(string: attributedString.string) // NSAttributedString requires NSRange which only comes from NSString

        hyperlinks.forEach { pointHyperlink in
            let substring = pointHyperlink.substring
            // Only will apply the hyperlink to the first instance of the substring
            let range = compatibleSourceString.range(of: substring, options: .caseInsensitive)
            if range.location != NSNotFound {
                attributedString.addAttribute(.link, value: pointHyperlink.url, range: range)
            }
        }

        return attributedString
    }
}
