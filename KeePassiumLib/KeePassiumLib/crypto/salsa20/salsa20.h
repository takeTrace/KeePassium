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

#ifndef salsa20_h
#define salsa20_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * Salsa 20 implementation adopted from the reference
 * implementation by D. J. Bernstein (version 20080912).
 * Taken from http://code.metager.de/source/xref/lib/nacl/20110221/crypto_core/salsa20/ref/core.c
 * Public domain.
 */
//int salsa20_core(unsigned char *out, const unsigned char *in, const unsigned char *k, const unsigned char *c);
int salsa20_core(unsigned char *out, const unsigned char *iv, const unsigned char *counter, const unsigned char *k, const unsigned char *c);

#ifdef __cplusplus
}
#endif

#endif /* salsa20_h */
