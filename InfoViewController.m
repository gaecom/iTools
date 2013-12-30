//
//  InfoViewController.m
//  iTools
//
//  Created by Jolin He on 12-11-12.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()
@end

@implementation InfoViewController{
    NSMutableDictionary* _deviceInfo;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        _deviceInfo=[NSMutableDictionary dictionary];
    }
    return self;
}

-(void)loadView{
    [super loadView];
}

-(void)setDevice:(AMDevice *)device{
    if (![_device.udid isEqualToString:device.udid]) {
        _device=device;
        
        [_deviceInfo setObject:@([_device newAFCRootDirectory]!=nil) forKey:@"isJailbreak"];
        
        id value=[_device deviceValueForKey:@"BatteryCurrentCapacity" inDomain:@"com.apple.mobile.battery"];
        if(value)[_deviceInfo setObject:value forKey:@"BatteryCurrentCapacity"];
        
        float total=[[_device deviceValueForKey:@"TotalDiskCapacity" inDomain:@"com.apple.disk_usage"] longLongValue]/1048576.f;
        float dataA=[[_device deviceValueForKey:@"TotalDataAvailable" inDomain:@"com.apple.disk_usage"] longLongValue]/1048576.f;
        float systemA=[[_device deviceValueForKey:@"TotalSystemAvailable" inDomain:@"com.apple.disk_usage"] longLongValue]/1048576.f;
        value=[NSString stringWithFormat:@"%.1fGB/%.1fGB",(dataA+systemA)/1024.f,total/1024.f];
        if(value)[_deviceInfo setObject:value forKey:@"DiskUsage"];
    }
}

-(id)valueForKey:(NSString *)key{
    if([key isEqualToString:@"_deviceInfo"]){
        return [super valueForKey:key];
    }else{
        return [_device deviceValueForKey:key];
    }
}
@end


@interface IsJailBreakTransformaer : NSValueTransformer
@end

@implementation IsJailBreakTransformaer
+ (BOOL)allowsReverseTransformation{
    return NO;
}
+ (Class)transformedValueClass{
    return [NSString class];
}
- (id)transformedValue:(id)value{
    return [value boolValue]?@"已越狱":@"未越狱";
}
@end
