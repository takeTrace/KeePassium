//
//  Clipboard.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-05-27.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit
import MobileCoreServices

public class Clipboard {

    public static let general = Clipboard()
    
    private var insertedString: String?
    
    private init() {
        // left empty
    }
    
    /// Puts given string to the pasteboard, and removes it after `timeout` seconds.
    public func insert(_ string: String, timeout: Double) {
        print("Copied something")
        
        let items: [[String: Any]]
        if let url = URL(string: string) {
            items = [[(kUTTypeURL as String) : url]]
        } else {
            items = [[(kUTTypeUTF8PlainText as String) : string]]
        }
        
        if timeout < 0 {
            // no timeout
            UIPasteboard.general.setItems(items, options: [.localOnly: true])
        } else {
            UIPasteboard.general.setItems(
                items,
                options: [
                    .localOnly: true,
                    .expirationDate: Date(timeIntervalSinceNow: timeout)
                ]
            )
        }
        insertedString = string
    }
    
    /// Removes previously inserted strings from the pastebord.
    public func clear() {
        guard let insertedString = insertedString else { return }
        // Before cleanup, make sure it is *our* stuff in Pasteboard
        if UIPasteboard.general.string == insertedString {
            UIPasteboard.general.setItems([[:]], options: [.localOnly: true])
            self.insertedString = nil
            print("Clipboard string cleared")
        }
    }
}
