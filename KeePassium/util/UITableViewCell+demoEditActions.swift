//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

extension UITableViewCell {
    
    /// Shows animation hinting about left-swipe actions.
    ///
    /// - Parameter lastActionColor: color of the rightmost action.
    public func demoShowEditActions(lastActionColor: UIColor) {
        guard let cellView = contentView.superview else { return }
        
        let shiftBy: CGFloat = 22 // by how many points to shift the cell
        
        let wasClippingToBounds = cellView.clipsToBounds
        cellView.clipsToBounds = false
        let fakeActionView = UIView(frame: self.contentView.bounds)
        fakeActionView.backgroundColor = .destructiveTint
        contentView.addSubview(fakeActionView)
        fakeActionView.translatesAutoresizingMaskIntoConstraints = false
        fakeActionView.topAnchor.constraint(equalTo: cellView.topAnchor).isActive = true
        fakeActionView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor).isActive = true
        fakeActionView.leadingAnchor.constraint(equalTo: cellView.trailingAnchor).isActive = true
        fakeActionView.widthAnchor.constraint(equalToConstant: shiftBy).isActive = true
        fakeActionView.isOpaque = true
        fakeActionView.layoutIfNeeded()
        
        let originalFrame = cellView.frame
        let shiftedFrame = cellView.frame.offsetBy(dx: -shiftBy, dy: 0)
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: [.curveEaseOut],
            animations: {
                cellView.frame = shiftedFrame
            },
            completion: { (finished) in
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveEaseIn],
                    animations: {
                        cellView.frame = originalFrame
                    },
                    completion: { (finished) in
                        fakeActionView.removeFromSuperview()
                        cellView.clipsToBounds = wasClippingToBounds
                    }
                )
            }
        )
    }
}
