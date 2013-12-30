//
//  AppDelegate.m
//  iTools
//
//  Created by Jolin He on 12-11-9.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "AppDelegate.h"
#import "MobileDeviceAccess.h"
#import "DeviceNode.h"
#import "DeviceItemNode.h"
#import "MBProgressHUD.h"

@interface AppDelegate()<MobileDeviceAccessListener>
@end

@implementation AppDelegate{
    NSMutableArray* _tabItems;
    __weak DeviceItemNode* _curSelectedItem;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _tabItems=[[NSMutableArray alloc] init];
    [[MobileDeviceAccess singleton] setListener:self];
}

- (void)deviceConnected:(AMDevice*)device{
    NSString* udid=device.udid;
    NSInteger idx=NSNotFound;
    for (int i=0;i<_tabItems.count;i++) {
        DeviceNode *node=[_tabItems objectAtIndex:i];
        if ([node.device.udid isEqualToString:udid]) {
            idx=i;
            break;
        }
    }
    if (idx==NSNotFound) {
        [_tabItems addObject:[[DeviceNode alloc] initWithDevice:device]];
        [_outlineView reloadData];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceAddedNotify object:device];
}

- (void)deviceDisconnected:(AMDevice*)device{
    NSString* udid=device.udid;
    NSInteger idx=NSNotFound;
    for (int i=0;i<_tabItems.count;i++) {
        DeviceNode *node=[_tabItems objectAtIndex:i];
        if ([node.device.udid isEqualToString:udid]) {
            idx=i;
            break;
        }
    }
    if (idx!=NSNotFound) {
        DeviceNode* node=[_tabItems objectAtIndex:idx];
        for (DeviceItemNode* nodeItem in node.tabs) {
            [nodeItem.controller.view removeFromSuperview];
        }
        [_tabItems removeObjectAtIndex:idx];
        [_outlineView reloadData];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceRemovedNotify object:device];
}

#pragma mark NSOutlineViewDatasource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return _tabItems.count;
    } else if ([item isKindOfClass:[DeviceNode class]]) {
        return ((DeviceNode *)item).tabs.count;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [_tabItems objectAtIndex:index];
    } else {
        return [((DeviceNode *)item).tabs objectAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[DeviceNode class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[DeviceNode class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[DeviceNode class]]) {
        // Everything is setup in bindings
        return [outlineView makeViewWithIdentifier:@"deviceCell" owner:self];
    } else {
        NSView *result = [outlineView makeViewWithIdentifier:@"deviceItemCell" owner:self];
        return result;
    }
    return nil;
}

#pragma mark NSOutlineViewDelegate
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	// don't allow special group nodes (Devices and Places) to be selected
    if ([item isKindOfClass:[DeviceItemNode class]]) {
        [_curSelectedItem.controller viewWillDisAppear];
        [_curSelectedItem.controller.view removeFromSuperview];

        _curSelectedItem=(DeviceItemNode*)item;
        NSView* selectedView=_curSelectedItem.controller.view;
        [_curSelectedItem.controller viewWillAppear];
        [_welcomeView addSubview:selectedView];
        
        selectedView.translatesAutoresizingMaskIntoConstraints=NO;
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(selectedView,_welcomeView);
        NSArray* constraints=[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[selectedView]-0-|" options:0 metrics:nil views:viewsDictionary];
        NSArray* constraints1=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[selectedView]-0-|" options:0 metrics:nil views:viewsDictionary];
        [_welcomeView addConstraints:constraints];
        [_welcomeView addConstraints:constraints1];
        
        return YES;
    }
	return NO;
}

#pragma mark NSSplitViewDelegate
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex{
    if (dividerIndex==1) {
        return 0;
    }else{
        return 170;
    }
}

#pragma mark NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender{
    [[NSApplication sharedApplication] terminate:self];
    return YES;
}

@end
