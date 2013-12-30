/*
     File: FileSystemNode.m
 Abstract: An abstract wrapper node around the file system.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */



#import "FileSystemNode.h"

@implementation FileSystemNode{
    NSArray* _sorttedChildren;
    AFCDirectoryAccess* _afcHander;
}

- (id)initWithPath:(NSString *)path afcHander:(AFCDirectoryAccess*)hander{
    if (self = [super init]) {
        _path = path;
        _afcHander=hander;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@", super.description, _path];
}


- (NSString *)displayName {
    return [_path lastPathComponent];
}

- (NSImage*)icon{
    NSImage* ret=nil;
    if ([self isDirectory]) {
        ret=[NSImage imageNamed:@"folder.png"];
    }else{
        ret=[[NSWorkspace sharedWorkspace] iconForFile:_path];
    }
    return ret;
}

- (BOOL)isDirectory{
    NSDictionary* dic=[_afcHander getFileInfo:_path];
    return [[dic objectForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"];
}

- (NSArray*)children{
    if (_sorttedChildren == nil || _childrenDirty) {
        // This logic keeps the same pointers around, if possible.
        NSMutableDictionary *newChildren = [NSMutableDictionary new];
        NSArray *contentsAtPath = [_afcHander directoryContents:_path];
	
        if (contentsAtPath) {	// We don't deal with the error
            for (NSString *filename in contentsAtPath) {
                // Use the filename as a key and see if it was around and reuse it, if possible
                if (_children != nil) {
                    FileSystemNode *oldChild = [_children objectForKey:filename];
                    if (oldChild != nil) {
                        [newChildren setObject:oldChild forKey:filename];
                        continue;
                    }
                }
                // We didn't find it, add a new one
                NSString *fullPath = [_path stringByAppendingFormat:@"/%@", filename];
                if (fullPath != nil) {
                    // Wrap the child url with our node
                    FileSystemNode *node = [[FileSystemNode alloc] initWithPath:fullPath afcHander:_afcHander];
                    [newChildren setObject:node forKey:filename];
                }
            }
        }else{
            NSLog(@"%@",[_afcHander lasterror]);
        }
        _children = newChildren;
        _childrenDirty = NO;
        
        NSArray *arr = [_children allValues];
        // Sort the children by the display name and return it
        _sorttedChildren = [arr sortedArrayUsingComparator:^(id obj1, id obj2) {
            NSString *objName = [obj1 displayName];
            NSString *obj2Name = [obj2 displayName];
            NSComparisonResult res = [objName compare:obj2Name options:NSNumericSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch range:NSMakeRange(0, [objName length]) locale:[NSLocale currentLocale]];
            return res;
        }];
        NSLog(@"sort!!!");
    }
    return _sorttedChildren;
}

- (void)invalidateChildren {
    _childrenDirty = YES;
    for (FileSystemNode *child in [_children allValues]) {
        [child invalidateChildren];
    }
}

@end
