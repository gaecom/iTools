//
//  AppViewController.m
//  iTools
//
//  Created by Jolin He on 13-12-26.
//  Copyright (c) 2013年 Jolin He. All rights reserved.
//

#import "AppFileManagerController.h"
#import "FileSystemBrowserCell.h"
#import "MBProgressHUD.h"

@implementation AppFileManagerController{
    AMApplication* _application;
    AMDevice* _device;
    AFCApplicationDirectory* _afcHander;
    
    NSViewController* _previewController;
    FileSystemNode *_rootNode;
    NSInteger _draggedColumnIndex;
    NSIndexSet *_draggedIndexSet;
    
    dispatch_queue_t _gcdQueue;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(instancetype)initWithApplication:(AMApplication*)app device:(AMDevice*)device{
    self=[super initWithWindowNibName:@"AppFileManagerController"];
    if (self) {
        _gcdQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _application=app;
        _device=device;
        _afcHander=[device newAFCApplicationDirectory:[app bundleid]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRemoved:) name:kDeviceRemovedNotify object:nil];
    }
    return self;
}

- (void)awakeFromNib {
    [_browser setColumnResizingType:NSBrowserUserColumnResizing];
    [_browser setMinColumnWidth:180];
    [_browser setTarget:self];
    [_browser setCellClass:[FileSystemBrowserCell class]];
    // Drag and drop support
    [_browser registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,NSFilenamesPboardType,nil]];
    [_browser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [_browser setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    // Double click support
    [_browser setTarget:self];
    [_browser setAction:@selector(browserCellSelected:)];
    [_browser setDoubleAction:@selector(browserDoubleClick:)];
}

- (id)rootItemForBrowser:(NSBrowser *)browser {
    if (_rootNode == nil) {
        _rootNode = [[FileSystemNode alloc] initWithPath:@"" afcHander:_afcHander];
    }
    return _rootNode;
}

// Required delegate methods
- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return [node children].count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return [[node children] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return ![node isDirectory];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item {
    FileSystemNode *node = (FileSystemNode *)item;
    return node.displayName;
}

- (void)browser:(NSBrowser *)browser willDisplayCell:(FileSystemBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column {
    // Find the item and set the image.
    NSIndexPath *indexPath = [browser indexPathForColumn:column];
    indexPath = [indexPath indexPathByAddingIndex:row];
    FileSystemNode *node = [browser itemAtIndexPath:indexPath];
    cell.image = [node icon];
}

- (NSViewController *)browser:(NSBrowser *)browser previewViewControllerForLeafItem:(id)item {
    if (_previewController == nil) {
        _previewController = [[NSViewController alloc] initWithNibName:@"PreviewView" bundle:[NSBundle bundleForClass:[self class]]];
    }
    return _previewController; // NSBrowser will set the representedObject for us
}

- (NSViewController *)browser:(NSBrowser *)browser headerViewControllerForItem:(id)item {
    // Add a header for the first column, just as an example
    if (_rootNode == item) {
        return [[NSViewController alloc] initWithNibName:@"HeaderView" bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return nil;
    }
}

- (CGFloat)browser:(NSBrowser *)browser shouldSizeColumn:(NSInteger)columnIndex forUserResize:(BOOL)forUserResize toWidth:(CGFloat)suggestedWidth  {
    if (!forUserResize) {
        id item = [browser parentForItemsInColumn:columnIndex];
        if ([self browser:browser isLeafItem:item]) {
            suggestedWidth = 200;
        }
    }
    return suggestedWidth;
}

#pragma mark ** Dragging Source Methods **

- (BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard {
    NSLog(@"writeRowsWithIndexes");
    NSInteger i;
    NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    NSIndexPath *baseIndexPath = [browser indexPathForColumn:column];
    for (i = [rowIndexes firstIndex]; i <= [rowIndexes lastIndex]; i = [rowIndexes indexGreaterThanIndex:i]) {
        FileSystemNode *fileSystemNode = [browser itemAtIndexPath:[baseIndexPath indexPathByAddingIndex:i]];
        [filenames addObject:[NSString stringWithFormat:@"%@",fileSystemNode.path]];
    }
    [pasteboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,nil] owner:self];
    [pasteboard setPropertyList:filenames forType:NSFilesPromisePboardType];
    _draggedColumnIndex = column;
    _draggedIndexSet=rowIndexes;
    return YES;
}

- (BOOL)browser:(NSBrowser *)browser canDragRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event {
    // We will allow dragging any cell -- even disabled ones. By default, NSBrowser will not let you drag a disabled cell
    return YES;
}


- (NSImage *)browser:(NSBrowser *)browser draggingImageForRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
    NSImage *result = [browser draggingImageForRowsWithIndexes:rowIndexes inColumn:column withEvent:event offset:dragImageOffset];
    // Create a custom drag image "badge" that displays the number of items being dragged
    if ([rowIndexes count] > 1) {
        NSString *str = [NSString stringWithFormat:@"%ld items being dragged", (long)[rowIndexes count]];
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0.5, 0.5)];
        [shadow setShadowBlurRadius:5.0];
        [shadow setShadowColor:[NSColor blackColor]];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               shadow, NSShadowAttributeName,
                               [NSColor whiteColor], NSForegroundColorAttributeName,
                               nil];
        
        NSAttributedString *countString = [[NSAttributedString alloc] initWithString:str attributes:attrs];
        NSSize stringSize = [countString size];
        NSSize imageSize = [result size];
        imageSize.height += stringSize.height;
        imageSize.width = MAX(stringSize.width + 3, imageSize.width);
        
        NSImage *newResult = [[NSImage alloc] initWithSize:imageSize];
        [newResult lockFocus];
        
        [result drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [countString drawAtPoint:NSMakePoint(0, imageSize.height - stringSize.height)];
        [newResult unlockFocus];
        
        dragImageOffset->y += (stringSize.height / 2.0);
        result = newResult;
    }
    return result;
}

#pragma mark ** Dragging Destination Methods **

- (FileSystemNode *)_fileSystemNodeAtRow:(NSInteger)row column:(NSInteger)column {
    if (column >= 0) {
        NSIndexPath *indexPath = [_browser indexPathForColumn:column];
        if (row >= 0) {
            indexPath = [indexPath indexPathByAddingIndex:row];
        }
        id result = [_browser itemAtIndexPath:indexPath];
        return (FileSystemNode *)result;
    } else {
        return nil;
    }
}

- (NSDragOperation)browser:(NSBrowser *)browser validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger *)row column:(NSInteger *)column  dropOperation:(NSBrowserDropOperation *)dropOperation {
    NSDragOperation result = NSDragOperationNone;
    // We only accept file types
    if ([[[info draggingPasteboard] types] indexOfObject:NSFilesPromisePboardType] != -1) {
        // For a between drop, we let the user drop "on" the parent item
        if (*dropOperation == NSBrowserDropAbove) {
            *row = -1;
        }
        // Only allow dropping in folders, but don't allow dragging from the same folder into itself, if we are the source
        if (*column != -1) {
            BOOL droppingFromSameFolder = ([info draggingSource] == browser) && (*column == _draggedColumnIndex);
            if (*row != -1) {
                // If we are dropping on a folder, then we will accept the drop at that row
                FileSystemNode *fileSystemNode = [self _fileSystemNodeAtRow:*row column:*column];
                if ([fileSystemNode isDirectory]) {
                    // Yup, a good drop
                    result = NSDragOperationEvery;
                } else {
                    // Nope, we can't drop onto a file! We will retarget to the column, if it isn't the same folder.
                    if (!droppingFromSameFolder) {
                        result = NSDragOperationEvery;
                        *row = -1;
                        *dropOperation = NSBrowserDropOn;
                    }
                }
            } else if (!droppingFromSameFolder) {
                result = NSDragOperationEvery;
                *row = -1;
                *dropOperation = NSBrowserDropOn;
            }
        }
    }
    return result;
}

- (BOOL)browser:(NSBrowser *)browser acceptDrop:(id <NSDraggingInfo>)info atRow:(NSInteger)row column:(NSInteger)column dropOperation:(NSBrowserDropOperation)dropOperation {
    NSArray *filenames1 = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSArray *filenames2 = [[info draggingPasteboard] propertyListForType:NSFilesPromisePboardType];
    // Find the target folder
    FileSystemNode *targetFileSystemNode = nil;
    if ((column != -1) && (filenames1!=nil || filenames2!=nil)) {
        if (row != -1) {
            FileSystemNode *fileSystemNode = [self _fileSystemNodeAtRow:row column:column];
            if ([fileSystemNode isDirectory]) {
                targetFileSystemNode = fileSystemNode;
            }
        } else {
            // Grab the parent for the column, which should be a directory
            targetFileSystemNode = (FileSystemNode *)[browser parentForItemsInColumn:column];
        }
    }
    //防止递归复制
    NSIndexPath *baseIndexPath = [browser indexPathForColumn:_draggedColumnIndex];
    for (NSUInteger idx = [_draggedIndexSet firstIndex]; idx <= [_draggedIndexSet lastIndex]; idx = [_draggedIndexSet indexGreaterThanIndex:idx]) {
        FileSystemNode *draggedNode = [browser itemAtIndexPath:[baseIndexPath indexPathByAddingIndex:idx]];
        FileSystemNode *node=targetFileSystemNode;
        NSInteger tmpIndex=column;
        BOOL founded=NO;
        while(tmpIndex>=0){
            if (draggedNode==node) {
                targetFileSystemNode=nil;
                founded=YES;
                break;
            }
            tmpIndex--;
            if(tmpIndex>0)node=[browser parentForItemsInColumn:tmpIndex];
        }
        if (founded)break;
    }
    
    // We now have the target folder, so move things around
    if (targetFileSystemNode != nil) {
        // Ask the user if they really want to move thos files.
        MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
        HUD.text=@"正在复制...";
        dispatch_async(_gcdQueue, ^{
            if (filenames1) {
                for (int i = 0; i < [filenames1 count]; i++) {
                    NSString *filename = [filenames1 objectAtIndex:i];
                    if (![self copyFromDisk:filename toDevice:targetFileSystemNode.path]) {
                        NSLog(@"copy file error");
                    }
                }
            }else if(filenames2){
                for (int i = 0; i < [filenames2 count]; i++) {
                    NSString *filename = [filenames2 objectAtIndex:i];
                    if (![self copyFromDevice:filename toDevice:targetFileSystemNode.path]) {
                        NSLog(@"copy file error");
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [HUD hide:YES];
                // It would be more efficient to invalidate the children of the "from" and "to" nodes and then call -reloadColumn: on each of the corresponding columns. However, we just reload every column
                [_rootNode invalidateChildren];
                for (NSInteger col = [_browser lastColumn]; col >= 0; col--) {
                    [_browser reloadColumn:col];
                }
            });
        });
        return YES;
    }
    return NO;
}

- (NSArray *)browser:(NSBrowser *)browser namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column{
    // return of the array of file names
    NSIndexPath *baseIndexPath = [browser indexPathForColumn:column];
    NSMutableArray *sourceItems=[NSMutableArray array];
    for (NSUInteger i = [rowIndexes firstIndex]; i <= [rowIndexes lastIndex]; i = [rowIndexes indexGreaterThanIndex:i]) {
        FileSystemNode *fileSystemNode = [browser itemAtIndexPath:[baseIndexPath indexPathByAddingIndex:i]];
        [sourceItems addObject:fileSystemNode];
    }
    
    NSMutableArray *draggedFilenames = [NSMutableArray array];
    for (FileSystemNode *srcNode in sourceItems){
        NSString *destPath = [self checkDiskFileName:[srcNode.path lastPathComponent] diskPath:dropDestination];
        NSString *filename=[destPath lastPathComponent];
        [draggedFilenames addObject:filename];
    }
    
    MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
    HUD.text=@"正在复制...";
    dispatch_async(_gcdQueue, ^{
        for (FileSystemNode *srcNode in sourceItems){
            if (![self copyFromDevice:srcNode toDisk:dropDestination]) {
                NSLog(@"copy file error");
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hide:YES];
        });
    });
    
    return draggedFilenames;
}

#pragma mark -
-(NSString*)checkDiskFileName:(NSString*)filename diskPath:(NSURL*)url{
    NSString *destPath = [[url path] stringByAppendingPathComponent:filename];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destPath];
    if (fileExists){
        if ([filename pathExtension]) {
            filename = [NSString stringWithFormat:@"%@ - Copy.%@", [filename stringByDeletingPathExtension],[filename pathExtension]];
        }else{
            filename = [NSString stringWithFormat:@"%@ - Copy", filename];
        }
        destPath=[[destPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
    }
    return destPath;
}

-(BOOL)copyFromDevice:(FileSystemNode*)node toDisk:(NSURL*)url{
    BOOL ret=NO;
    NSString *destPath = [self checkDiskFileName:[node.path lastPathComponent] diskPath:url];
    if ([node isDirectory]) {
        NSError* error=nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%@",[error localizedDescription]);
        }else{
            NSArray* arr=[node children];
            for (FileSystemNode* child in arr) {
                [self copyFromDevice:child toDisk:[NSURL fileURLWithPath:destPath]];
            }
        }
    }else{
        AFCFileReference* afcFile=[_afcHander openForRead:node.path];
        unsigned long long fsize=[[[_afcHander getFileInfo:node.path] objectForKey:@"st_size"] unsignedLongLongValue];
        uint32_t amount = 0;
        uint32_t total = 0;
        char buf[8192];
        FILE *f = NULL;
        f = fopen([destPath UTF8String], "w");
        if (f) {
            do{
                amount=[afcFile readN:sizeof(buf) bytes:buf];
                if (amount>0) {
                    size_t written = fwrite(buf, 1, amount, f);
                    if (written != amount) {
                        fprintf(stderr, "Error when writing %d bytes to local file!\n", amount);
                        break;
                    }
                    total += written;
                }
            }while (amount > 0);
        }
        if (fsize!=total) {
            NSLog(@"%@",[afcFile lasterror]);
        }else{
            ret=YES;
        }
    }
    return ret;
}

-(NSString*)checkDeviceFileName:(NSString*)filename devicePath:(NSString*)path{
    NSString *destPath = [path stringByAppendingPathComponent:filename];
    BOOL fileExists = [_afcHander fileExistsAtPath:destPath];
    if (fileExists){
        if ([filename pathExtension]) {
            filename = [NSString stringWithFormat:@"%@ - Copy.%@", [filename stringByDeletingPathExtension],[filename pathExtension]];
        }else{
            filename = [NSString stringWithFormat:@"%@ - Copy", filename];
        }
        destPath=[[destPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
    }
    return destPath;
}

-(BOOL)copyFromDisk:(NSString*)localPath toDevice:(NSString*)devicePath{
    BOOL ret=NO;
    NSString *destPath = [self checkDeviceFileName:[localPath lastPathComponent] devicePath:devicePath];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDir]) {
        if (isDir) {
            if ([_afcHander mkdir:destPath]) {
                NSError* error;
                NSArray* arr=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:localPath error:&error];
                if (!error) {
                    for (NSString *fname in arr) {
                        NSString* newSrcPath=[localPath stringByAppendingPathComponent:fname];
                        [self copyFromDisk:newSrcPath toDevice:destPath];
                    }
                }
            }else{
                NSLog(@"%@",[_afcHander lasterror]);
            }
        }else{
            AFCFileReference *afcFile=[_afcHander openForWrite:destPath];
            size_t amount = 0;
            char buf[8192];
            FILE *f = NULL;
            f = fopen([localPath UTF8String], "r");
            if (f) {
                BOOL hasErr=NO;
                do {
                    amount = fread(buf, 1, sizeof(buf), f);
                    if (amount > 0) {
                        if (![afcFile writeN:(uint32_t)amount bytes:buf]) {
                            NSLog(@"%@",[afcFile lasterror]);
                            hasErr=YES;
                            break;
                        }
                    }
                }while (amount > 0);
                ret=!hasErr;
            }
        }
    }
    return ret;
}

-(BOOL)copyFromDevice:(NSString*)devicePath1 toDevice:(NSString*)devicePath2{
    BOOL ret=NO;
    NSString *destPath = [self checkDeviceFileName:[devicePath1 lastPathComponent] devicePath:devicePath2];
    if ([_afcHander fileExistsAtPath:devicePath1]) {
        NSDictionary* dic=[_afcHander getFileInfo:devicePath1];
        BOOL isDir = [[dic objectForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"];
        if (isDir) {
            if ([_afcHander mkdir:destPath]) {
                NSArray* arr=[_afcHander directoryContents:devicePath1];
                if (arr) {
                    for (NSString *fname in arr) {
                        NSString* newSrcPath=[devicePath1 stringByAppendingPathComponent:fname];
                        [self copyFromDevice:newSrcPath toDevice:destPath];
                    }
                }
            }else{
                NSLog(@"%@",[_afcHander lasterror]);
            }
        }else{
            AFCFileReference *afcFile1=[_afcHander openForWrite:destPath];
            AFCFileReference *afcFile2=[_afcHander openForRead:devicePath1];
            size_t amount = 0;
            char buf[8192];
            if (afcFile1&&afcFile2) {
                BOOL hasErr=NO;
                do {
                    amount = [afcFile2 readN:sizeof(buf) bytes:buf];
                    if (amount > 0) {
                        if (![afcFile1 writeN:(uint32_t)amount bytes:buf]) {
                            NSLog(@"%@",[afcFile1 lasterror]);
                            hasErr=YES;
                            break;
                        }
                    }
                }while (amount > 0);
                ret=!hasErr;
            }
        }
    }
    return ret;
}

- (void)browserDoubleClick:(id)sender {
    // Find the clicked item and open it in Finder
    FileSystemNode *clickedNode = [self _fileSystemNodeAtRow:_browser.clickedRow column:_browser.clickedColumn];
    if (clickedNode) {
        NSLog(@"%@",clickedNode.path);
    }
}

- (void)browserCellSelected:(id)sender{
    NSLog(@"browserCellSelected");
}

-(void)showErrorTip:(NSString*)msg{
    MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
    HUD.text=msg;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        [HUD hide:YES];
    });
}

#pragma mark -
#pragma mark menu
-(void)removeAction:(id)sender{
    NSArray* nodes=[sender representedObject];
    if (nodes.count>0) {
        if ([[NSAlert alertWithMessageText:@"Verify file delete!" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"Would you like to delete these %lu files?", nodes.count] runModal] == NSAlertDefaultReturn) {
            for (FileSystemNode* node in nodes) {
                [self removeDeviceFile:node.path];
            }
            [_rootNode invalidateChildren];
            NSInteger selectCol=[_browser selectedColumn];
            [_browser reloadColumn:selectCol];
        }
    }
}

-(void)renameAction:(id)sender{
    FileSystemNode* node=[[sender representedObject] objectAtIndex:0];
    NSInteger col=[[[sender representedObject] objectAtIndex:1] integerValue];
    NSString* oldName=[node.path lastPathComponent];
    NSAlert *alert = [NSAlert alertWithMessageText: @"请输入文件名"
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:oldName];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        NSString* name=[input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length>0) {
            NSString* newPath=[[node.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
            
            if(![_afcHander rename:node.path to:newPath]){
                [self showErrorTip:[_afcHander lasterror]];
            }else{
                [_rootNode invalidateChildren];
                [_browser reloadColumn:col];
            }
        }
    }
}

-(void)newDirAction:(id)sender{
    FileSystemNode* node=[[sender representedObject] objectAtIndex:0];
    NSInteger col=[[[sender representedObject] objectAtIndex:1] integerValue];
    NSAlert *alert = [NSAlert alertWithMessageText: @"请输入文件名"
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:@"新建文件夹"];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        NSString* name=[input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length>0) {
            NSString* path=[node.path stringByAppendingPathComponent:name];
            if ([_afcHander fileExistsAtPath:path]) {
                [self showErrorTip:@"文件已经存在"];
            }else{
                if(![_afcHander mkdir:path]){
                    [self showErrorTip:[_afcHander lasterror]];
                }else{
                    [_rootNode invalidateChildren];
                    [_browser reloadColumn:col];
                }
            }
        }
    }
}

-(void)uploadAction:(id)sender{
    FileSystemNode* node=[[sender representedObject] objectAtIndex:0];
    NSInteger col=[[[sender representedObject] objectAtIndex:1] integerValue];

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:nil];
    [openDlg setAllowsMultipleSelection:YES];
    
    if ( [openDlg runModal] == NSOKButton ) {
        NSArray *files = [openDlg URLs];
        if (files.count>0) {
            MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
            HUD.text=@"正在复制...";
            dispatch_async(_gcdQueue, ^{
                for (int i = 0; i < [files count]; i++) {
                    NSString *filename = [(NSURL*)[files objectAtIndex:i] path];
                    if (![self copyFromDisk:filename toDevice:node.path]) {
                        NSLog(@"copy file error");
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD hide:YES];
                    [_rootNode invalidateChildren];
                    [_browser reloadColumn:col];
                });
            });
        }
    }
}

-(void)downloadAction:(id)sender{
    NSArray* nodes=[sender representedObject];
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowedFileTypes:nil];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSOKButton ) {
        NSArray *files = [openDlg URLs];
        if (files.count>0) {
            NSURL *url=(NSURL*)[files objectAtIndex:0];
            MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
            HUD.text=@"正在复制...";
            dispatch_async(_gcdQueue, ^{
                for (FileSystemNode *srcNode in nodes){
                    if (![self copyFromDevice:srcNode toDisk:url]) {
                        NSLog(@"copy file error");
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD hide:YES];
                });
            });
        }
    }
}

-(BOOL)removeDeviceFile:(NSString*)path{
    NSDictionary* dic=[_afcHander getFileInfo:path];
    BOOL isDirectory= [[dic objectForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"];
    if (isDirectory) {
        NSArray* children=[_afcHander directoryContents:path];
        if (children.count>0){
            for (NSString* fname in children) {
                NSString* fullPath=[path stringByAppendingPathComponent:fname];
                [self removeDeviceFile:fullPath];
            }
        }
    }
    return [_afcHander unlink:path];
}

- (void)menuNeedsUpdate:(NSMenu *)menu{
    NSInteger selectedCol=[_browser selectedColumn];
    NSIndexPath *baseIndexPath = [_browser indexPathForColumn:selectedCol];
    NSIndexSet *rowIndexes=[_browser selectedRowIndexesInColumn:selectedCol];
    
    NSInteger clickedRow=[_browser clickedRow];
    NSInteger clickedCol=[_browser clickedColumn];
    BOOL clickInSelect=NO;
    if (rowIndexes.count>0){
        for (NSUInteger i = [rowIndexes firstIndex]; i <= [rowIndexes lastIndex]; i = [rowIndexes indexGreaterThanIndex:i]) {
            if (i==clickedRow&&selectedCol==clickedCol) {
                clickInSelect=YES;
            }
        }
    }
    if (clickInSelect==NO) {
        if (clickedRow>=0&&clickedCol>=0) {
            [_browser selectRow:clickedRow inColumn:clickedCol];
            selectedCol=[_browser selectedColumn];
            baseIndexPath = [_browser indexPathForColumn:selectedCol];
            rowIndexes=[_browser selectedRowIndexesInColumn:selectedCol];
        }else if(clickedRow<0&&clickedCol>=0){
            rowIndexes=nil;
        }else if(clickedCol<0&&clickedRow<0){
            rowIndexes=nil;
        }
    }
    
    NSMutableArray *sourceItems=[NSMutableArray array];
    if (rowIndexes.count>0){
        for (NSUInteger i = [rowIndexes firstIndex]; i <= [rowIndexes lastIndex]; i = [rowIndexes indexGreaterThanIndex:i]) {
            FileSystemNode *fileSystemNode = [_browser itemAtIndexPath:[baseIndexPath indexPathByAddingIndex:i]];
            [sourceItems addObject:fileSystemNode];
        }
    }
    //construct a menu based on column and row
    NSArray *items = [self constructMenuItemsForNodes:sourceItems];
    //strip all the existing stuff
    [menu removeAllItems];
    //then repopulate with the menu that you just created
    for(NSMenuItem *item in items){
        [menu addItem:item];
    }
}
-(NSArray *)constructMenuItemsForNodes:(NSArray*)items
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSMenuItem *menuItem = nil;
    NSInteger clickedCol=[_browser clickedColumn];
    if (clickedCol>0) {
        FileSystemNode* node=nil;
        if (clickedCol==0) {
            node=[self rootItemForBrowser:_browser];
        }else{
            //node=[_browser itemAtRow:[_browser selectedRowInColumn:clickedCol-1] inColumn:clickedCol-1];
            node=[_browser parentForItemsInColumn:clickedCol];
        }
        if (node.isDirectory) {
            menuItem = [[NSMenuItem alloc] initWithTitle:@"上传" action:@selector(uploadAction:) keyEquivalent:@""];
            menuItem.target=self;
            [menuItem setRepresentedObject:@[node,@(clickedCol)]];
            [arr addObject:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"新建文件夹" action:@selector(newDirAction:) keyEquivalent:@""];
            menuItem.target=self;
            [menuItem setRepresentedObject:@[node,@(clickedCol)]];
            [arr addObject:menuItem];
        }
    }
    if (items.count>0) {
        menuItem = [[NSMenuItem alloc] initWithTitle:@"删除" action:@selector(removeAction:) keyEquivalent:@""];
        menuItem.target=self;
        [menuItem setRepresentedObject:items];
        [arr addObject:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"下载" action:@selector(downloadAction:) keyEquivalent:@""];
        menuItem.target=self;
        [menuItem setRepresentedObject:items];
        [arr addObject:menuItem];
        
        if (items.count==1) {
            menuItem = [[NSMenuItem alloc] initWithTitle:@"重命名" action:@selector(renameAction:) keyEquivalent:@""];
            menuItem.target=self;
            [menuItem setRepresentedObject:@[[items objectAtIndex:0],@(clickedCol)]];
            [arr addObject:menuItem];
        }
    }
    return arr;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    return YES;
}


#pragma mark -
-(void)deviceRemoved:(NSNotification*)notify{
    AMDevice* dev=[notify object];
    if (dev==_device) {
        [self closeAction:nil];
    }
}

- (IBAction)closeAction:(id)sender {
    [self.window close];
    [NSApp endSheet:self.window];
}

@end
