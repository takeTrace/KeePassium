//  KeePassium Password Manager
//  Copyright © 2018 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>

//! Project version number for KeePassiumLib.
FOUNDATION_EXPORT double KeePassiumLibVersionNumber;

//! Project version string for KeePassiumLib.
FOUNDATION_EXPORT const unsigned char KeePassiumLibVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <KeePassiumLib/PublicHeader.h>

#import <CommonCrypto/CommonCrypto.h>
#import "salsa20.h"
#import "chacha20.h"
#import "argon2.h"
#import "twofish.h"
#import "aeskdf.h"

