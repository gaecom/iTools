//
//  BaseViewController.m
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController
@synthesize device=_device;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)loadView{
    [super loadView];
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:[NSColor whiteColor].CGColor]; //RGB plus Alpha Channel
    [self.view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [self.view setLayer:viewLayer];
}

-(void)viewWillAppear{
    NSLog(@"need imp");
}
-(void)viewWillDisAppear{
    NSLog(@"need imp");
}
@end
