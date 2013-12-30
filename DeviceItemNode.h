//
//  DeviceItemNode.h
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewController.h"

@interface DeviceItemNode : NSObject
@property(nonatomic,readonly)NSString* title;
@property(nonatomic,readonly)BaseViewController* controller;
-(id)initWithTitle:(NSString*)title controller:(NSViewController*)ctr;
@end
