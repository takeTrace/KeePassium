//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import KeePassiumLib

extension Attachment {
    
    /// Returns system-provided icon for the attachment.
    /// Due to system limitations, currently returns a generic icon, regardless of file type.
    public func getSystemIcon() -> UIImage? {
        let url = URL(fileURLWithPath: name, isDirectory: false)
        let interactionController = UIDocumentInteractionController(url: url)
        // To get specific icons, the file must exist and be accessible
        return interactionController.icons.first
    }
}
