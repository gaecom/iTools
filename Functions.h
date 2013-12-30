//
//  Functions.h
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zip.h"

static char *base64encode(const unsigned char *buf, size_t size);
int zip_f_get_contents(struct zip *zf, const char *filename, int locate_flags, char **buffer, uint32_t *len);