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

    private static let boldKey = "**"
    static func formatBold(in sourceString: String?, regularAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString? {
        guard let sourceString = sourceString else { return nil }

        let attributedString = NSMutableAttributedString(string: sourceString, attributes: regularAttributes)
        guard let regularFont = regularAttributes[NSAttributedString.Key.font] as? UIFont else { return attributedString }

        let boldAttributes = [NSAttributedString.Key.font: UIFont.primaryBold(regularFont.pointSize)]
        let compatibleSourceString = NSString(string: sourceString) // NSAttributedString requires NSRange which only comes from NSString

        var range1: NSRange
        var newStartIndex1: Int
        var range2: NSRange
        var newStartIndex2 = 0

        while true {
            range1 = compatibleSourceString.range(of: MarkDownFormatter.boldKey,
                                                  range: NSRange(location: newStartIndex2,
                                                                 length: sourceString.count - newStartIndex2))
            newStartIndex1 = range1.location + range1.length
            guard range1.location != NSNotFound else { break }

            range2 = compatibleSourceString.range(of: MarkDownFormatter.boldKey,
                                                  range: NSRange(location: newStartIndex1,
                                                                 length: sourceString.count - newStartIndex1))
            newStartIndex2 = range2.location + range2.length
            guard range2.location != NSNotFound else { break }

            attributedString.addAttributes(boldAttributes,
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
}
