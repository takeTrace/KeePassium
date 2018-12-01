//
//  ProgressEx.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-06-14.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

import UIKit

public class ProgressEx: Progress {
    public var status: String {
        get { return localizedDescription }
        set { localizedDescription = newValue }
    }
    
    override public init(parent parentProgressOrNil: Progress?,
                  userInfo userInfoOrNil: [ProgressUserInfoKey : Any]? = nil)
    {
        super.init(parent: parentProgressOrNil, userInfo: userInfoOrNil)
    }
}

