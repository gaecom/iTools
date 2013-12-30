//
//  DeviceItemNode.m
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "DeviceItemNode.h"

@implementation DeviceItemNode
-(id)initWithTitle:(NSString*)title controller:(BaseViewController*)ctr{
    self=[super init];
    if (self) {
        _title=title;
        _controller=ctr;
    }
    return self;
}
@end
