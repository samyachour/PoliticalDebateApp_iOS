//
//  LinkResponsiveTextView.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 10/13/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

/// UITextView that allows touches to be passed to next receiver if it's not on a hyperlink
class LinkResponsiveTextView: UITextView {

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        delaysContentTouches = false
        // required for tap to pass through on to superview & for links to work
        isScrollEnabled = false
        isEditable = false
        isUserInteractionEnabled = true
        isSelectable = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // location of the tap
        var location = point
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        // find the character that's been tapped
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < textStorage.length - 1 {
            // if the character is a link, handle the tap as UITextView normally would
            if (textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                return self
            }
        }

        // otherwise return nil so the tap goes on to the next receiver
        return nil
    }

}
