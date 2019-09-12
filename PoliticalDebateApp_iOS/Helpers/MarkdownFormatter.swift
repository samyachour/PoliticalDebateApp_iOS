//
//  MarkdownFormatter.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/8/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

class MarkDownFormatter {

    static func format(_ sourceString: String?,
                       with regularAttributes: [NSAttributedString.Key: Any],
                       hyperlinks: [PointHyperlink]? = nil) -> NSMutableAttributedString? {
        guard let sourceString = sourceString,
            let regularFontSize = (regularAttributes[.font] as? UIFont)?.pointSize else {
            return nil
        }

        var attributedString = NSMutableAttributedString(string: sourceString, attributes: regularAttributes)
        attributedString = format(attributedString, between: MarkDownFormatter.boldKey,
                                  formattedAttributes: [NSAttributedString.Key.font: UIFont.primaryBold(regularFontSize)])
        attributedString = format(attributedString, between: MarkDownFormatter.italicsKey,
                                  formattedAttributes: [NSAttributedString.Key.font: UIFont.primaryItalic(regularFontSize)])
        if let hyperlinks = hyperlinks {
            attributedString = format(attributedString, with: hyperlinks)
        }
        return attributedString
    }

    private static let boldKey = "**"
    private static let italicsKey = "*"

    private static func format(_ attributedString: NSMutableAttributedString,
                               between key: String,
                               formattedAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let compatibleSourceString = NSString(string: attributedString.string) // NSAttributedString requires NSRange which only comes from NSString

        var range1: NSRange
        var newStartIndex1: Int
        var range2: NSRange
        var newStartIndex2 = 0

        while true {
            range1 = compatibleSourceString.range(of: MarkDownFormatter.boldKey,
                                                  range: NSRange(location: newStartIndex2,
                                                                 length: compatibleSourceString.length - newStartIndex2))
            newStartIndex1 = range1.location + range1.length
            guard range1.location != NSNotFound else { break }

            range2 = compatibleSourceString.range(of: MarkDownFormatter.boldKey,
                                                  range: NSRange(location: newStartIndex1,
                                                                 length: compatibleSourceString.length - newStartIndex1))
            newStartIndex2 = range2.location + range2.length
            guard range2.location != NSNotFound else { break }

            attributedString.addAttributes(formattedAttributes,
                                           range: NSRange(location: newStartIndex1,
                                                          length: range2.location - newStartIndex1))

            attributedString.replaceCharacters(in: range1, with: "")
            attributedString.replaceCharacters(in: NSRange(location: range2.location - range1.length,
                                                           length: range2.length),
                                               with: "")
            compatibleSourceString.replacingCharacters(in: range1, with: "")
            compatibleSourceString.replacingCharacters(in: NSRange(location: range2.location - range1.length,
                                                                   length: range2.length),
                                                       with: "")

        }

        return attributedString
    }

    private static func format(_ attributedString: NSMutableAttributedString, with hyperlinks: [PointHyperlink]) -> NSMutableAttributedString {
       let compatibleSourceString = NSString(string: attributedString.string) // NSAttributedString requires NSRange which only comes from NSString

        hyperlinks.forEach { (pointHyperlink) in
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
