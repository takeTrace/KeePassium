//
//  chacha20.h
//  KeePassium
//
//  Created by Andrei Popleteev on 2018-03-26.
//  Copyright © 2018 Andrei Popleteev. All rights reserved.
//

#ifndef chacha20_h
#define chacha20_h

#ifdef __cplusplus
extern "C" {
#endif
    
#include <stdint.h>

void chacha20_make_block(const uint8_t *key, const uint8_t *iv, const uint8_t *counter, uint8_t *output);
    
#ifdef __cplusplus
}
#endif

#endif /* chacha20_h */
