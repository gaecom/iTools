//
//  AppManagerController.m
//  iTools
//
//  Created by Jolin He on 12-11-13.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "AppManagerController.h"
#import "MBProgressHUD.h"
#include "zip.h"
#include <sys/stat.h>
#include <libgen.h>
#include <stdio.h>
#import "AppFileManagerController.h"

const char G_PKG_PATH[] = "PublicStaging";
const char G_APPARCH_PATH[] = "ApplicationArchives";

@interface AppManagerController ()<NSTableViewDataSource,NSTableViewDelegate,NSTabViewDelegate,AMInstallationProxyDelegate>
@property(nonatomic,strong)NSArray* applications;
@property(nonatomic,strong)NSArray* archives;
@end

@implementation AppManagerController{
    BOOL _isLoading;
    dispatch_queue_t _gcdQueue;
    NSArray* _installedApps;
    AMInstallationProxy* _instProxy;
    AMSpringboardServices* _sbService;
    AFCMediaDirectory *_afcMediaDir;
    AMNotificationProxy *_notifyPtoxy;
    
    AppFileManagerController* _appManagerCtr;
}

-(void)dealloc{
    [_notifyPtoxy removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        _gcdQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    return self;
}

-(void)loadView{
    [super loadView];
    [_appListView setAllowsEmptySelection:NO];
    [_archiveListView setAllowsEmptySelection:NO];
    
    if(_applications!=nil)return;
    [self loadApplications];
}

-(void)setDevice:(AMDevice *)device{
    if (_device!=device) {
        _device=device;
        _instProxy=[device newAMInstallationProxyWithDelegate:self];
        _sbService=[device newAMSpringboardServices];
        _afcMediaDir=[device newAFCMediaDirectory];
        
        [_notifyPtoxy removeObserver:self];
        _notifyPtoxy=[device newAMNotificationProxy];
        [_notifyPtoxy addObserver:self selector:@selector(appInstalled:) name:@"com.apple.mobile.application_installed"];
        [_notifyPtoxy addObserver:self selector:@selector(appUninstalled:) name:@"com.apple.mobile.application_uninstalled"];
    }
}

-(void)appInstalled:(NSString*)notify{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        NSLog(@"%@",notify);
        [self loadApplications];
    });
}
-(void)appUninstalled:(NSString*)notify{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        NSLog(@"%@",notify);
        [self loadApplications];
    });
}

/// A new current operation is beginning.
-(void)operationStarted:(NSDictionary*)info{
    NSString* command=[info objectForKey:@"Command"];
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD* HUD=[MBProgressHUD HUDForView:self.view];
        HUD.text=[NSString stringWithFormat:@"%@",command];
    });
    NSLog(@"operationStarted:%@",info);
}
/// The current operation is continuing.
-(void)operationContinues:(NSDictionary*)info{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD* HUD=[MBProgressHUD HUDForView:self.view];
        NSString* error=[info objectForKey:@"Error"];
        if (error) {
            _isLoading=NO;
            HUD.text=error;
            [HUD hide:YES afterDelay:1];
        }else{
            id per=[info objectForKey:@"PercentComplete"];
            HUD.text=[NSString stringWithFormat:@"%@%@",[info objectForKey:@"Status"],per?[NSString stringWithFormat:@":%@%%",per]:@""];
        }
    });
    NSLog(@"operationContinues:%@",info);
}
/// The current operation finished (one way or the other)
-(void)operationCompleted:(NSDictionary*)info{
    NSString* command=[info objectForKey:@"Command"];
    dispatch_async(dispatch_get_main_queue(), ^{
        _isLoading=NO;
        MBProgressHUD* HUD=[MBProgressHUD HUDForView:self.view];
        HUD.text=[NSString stringWithFormat:@"%@ finished",command];
        [HUD hide:YES afterDelay:1];
    });
    NSLog(@"operationCompleted:%@",info);
}

-(void)loadApplications{
    if (_isLoading) {
        return;
    }
    _isLoading=YES;
    
    MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.text=@"正在加载应用列表...";
    
    dispatch_async(_gcdQueue, ^{
        _installedApps=[_instProxy browse:@"User"];
        NSArray* formattedApps=[self buildApplications:_installedApps];
        dispatch_async(dispatch_get_main_queue(), ^{
            _isLoading=NO;
            if (_installedApps){
                [HUD hide:YES];
                self.applications=formattedApps;
                [_appListView reloadData];
            }else{
                HUD.text=[_device lasterror];
                [HUD hide:YES afterDelay:1];
            }
        });
    });
}

-(NSArray*)buildApplications:(NSArray *)applications{
    NSMutableArray* formattedItems=[NSMutableArray arrayWithCapacity:applications.count];
    @autoreleasepool {
        NSMutableArray* iconStateArr=[NSMutableArray array];
        NSArray* tmpArr=[_sbService getIconState];
        for (NSArray *arr1 in tmpArr) {
            for (NSArray* arr2 in arr1) {
                for (NSDictionary* dic in arr2) {
                    if([dic isKindOfClass:[NSDictionary class]])[iconStateArr addObject:dic];
                }
            }
        }
        for (AMApplication* app in applications) {
            @autoreleasepool {
                NSMutableDictionary *dic=[NSMutableDictionary dictionaryWithDictionary:[app info]];
                NSString* appName=[app appname];
                [dic setObject:appName forKey:@"CFBundleDisplayName"];
                [dic setObject:[NSString stringWithFormat:@"iOS%@以上",[dic objectForKey:@"MinimumOSVersion"]] forKey:@"MinimumOSVersion"];
                NSArray* platforms=[dic objectForKey:@"CFBundleSupportedPlatforms"];
                if (platforms) {
                    [dic setObject:[platforms componentsJoinedByString:@"/"] forKey:@"CFBundleSupportedPlatforms"];
                }else{
                    BOOL isNesstand=[[dic objectForKey:@"UINewsstandApp"] boolValue];
                    [dic setObject:(isNesstand?@"Newsstand":@"iOS") forKey:@"CFBundleSupportedPlatforms"];
                }
                //CFBundleIconData
                NSPredicate* pre=[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    return [[evaluatedObject objectForKey:@"bundleIdentifier"] isEqualToString:app.bundleid];
                }];
                NSArray* iconArr=[iconStateArr filteredArrayUsingPredicate:pre];
                if (iconArr.count>0) {
                    NSImage *pngData=[_sbService getIcon:[[iconArr objectAtIndex:0] objectForKey:@"displayIdentifier"]];
                    if(pngData)[dic setObject:pngData forKey:@"CFBundleIconData"];
                }
                [formattedItems addObject:dic];
            }
        }
    }
    return formattedItems;
}

-(void)loadArchives{
    if (_isLoading) {
        return;
    }
    _isLoading=YES;
    
    MBProgressHUD *HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(_gcdQueue, ^{
        NSDictionary* archInfo=[_instProxy archivedAppInfo];
        NSArray* archs=[self buildArchives:archInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
            _isLoading=NO;
            if (archInfo){
                [HUD hide:YES];
                self.archives=archs;
                [_archiveListView reloadData];
            }else{
                HUD.text=[_instProxy lasterror];
                [HUD hide:YES afterDelay:1];
            }
        });
    });
}

-(NSArray*)buildArchives:(NSDictionary *)archives_{
    NSArray* bundles=[archives_ allKeys];
    NSMutableArray* formattedItems=[NSMutableArray arrayWithCapacity:archives_.count];
    @autoreleasepool {
        for (NSString* bundleid in bundles) {
            @autoreleasepool {
                NSMutableDictionary* dic=[NSMutableDictionary dictionaryWithDictionary:[archives_ objectForKey:bundleid]];
                NSString* appName=[dic objectForKey:@"CFBundleDisplayName"];
                if(appName==nil)appName=[dic objectForKey:@"CFBundleName"];
                [dic setObject:appName forKey:@"CFBundleDisplayName"];
                [dic setObject:[NSString stringWithFormat:@"iOS%@以上",[dic objectForKey:@"MinimumOSVersion"]] forKey:@"MinimumOSVersion"];
                NSArray* platforms=[dic objectForKey:@"CFBundleSupportedPlatforms"];
                if (platforms) {
                    [dic setObject:[platforms componentsJoinedByString:@"/"] forKey:@"CFBundleSupportedPlatforms"];
                }else{
                    BOOL isNesstand=[[dic objectForKey:@"UINewsstandApp"] boolValue];
                    [dic setObject:(isNesstand?@"Newsstand":@"iOS") forKey:@"CFBundleSupportedPlatforms"];
                }
                
                [formattedItems addObject:dic];
            }
        }
    }
    return formattedItems;
}

- (IBAction)segmentChanged:(NSSegmentedControl*)sender {
    if (sender.selectedSegment==0) {
        [_tabView selectTabViewItem:[_tabView.tabViewItems objectAtIndex:0]];
        if (_applications.count==0) {
            [self loadApplications];
        }
    }else if(sender.selectedSegment==1){
        [_tabView selectTabViewItem:[_tabView.tabViewItems objectAtIndex:1]];
        if (_archives.count==0) {
            [self loadArchives];
        }
    }
}

- (IBAction)installAction:(id)sender {
    __block NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    NSArray *fileTypesArray=@[@"ipa", @"zip"];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:NO];
    
    [openDlg beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSArray *files = [openDlg URLs];
            if (files.count>0) {
                NSURL *url=(NSURL*)[files objectAtIndex:0];
                NSString* path=[[[url pathComponents] componentsJoinedByString:@"/"] substringFromIndex:1];
                //install
                if (_isLoading) {
                    return;
                }
                _isLoading=YES;
                MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                HUD.text=@"数据读取中...";
                dispatch_async(_gcdQueue, ^{
                    const char* chPath=[path UTF8String];
                    struct stat fst;
                    int errp = 0;
                    NSString* bundleid=nil;
                    if (stat(chPath, &fst) == 0) {
                        struct zip *zf=NULL;
                        zf = zip_open(chPath, 0, &errp);
                        if (zf) {
                            char *zbuf = NULL;
                            uint32_t len = 0;
                            if (zip_f_get_contents(zf, "Info.plist", ZIP_FL_NODIR, &zbuf, &len) == 0) {
                                NSData* data=[NSData dataWithBytes:zbuf length:len];
                                free(zbuf);
                                
                                NSString *error;
                                NSPropertyListFormat format;
                                NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
                                if(plist){
                                    bundleid=[plist objectForKey:@"CFBundleIdentifier"];
                                }
                            }
                        }
                    }
                    BOOL uploaded=NO;
                    char pkgname[1024];
                    if (bundleid) {
                        if (snprintf( pkgname, sizeof(pkgname), "%s/%s", G_PKG_PATH, basename((char*)chPath)) >=0) {
                            NSString* tmpPath=[NSString stringWithUTF8String:G_PKG_PATH];
                            if (![_afcMediaDir fileExistsAtPath:tmpPath]) {
                                [_afcMediaDir mkdir:tmpPath];
                            }
                            AFCFileReference *afcFile=[_afcMediaDir openForWrite:[NSString stringWithUTF8String:pkgname]];
                            if (!afcFile) {
                                NSLog(@"%@",[_afcMediaDir lasterror]);
                            }
                            size_t amount = 0;
                            char buf[8192];
                            FILE *f = NULL;
                            f = fopen(chPath, "r");
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
                                uploaded=!hasErr;
                            }
                        }
                    }
                    if (uploaded) {
                        if ([_device installedApplicationWithId:bundleid]) {
                            [_instProxy upgrade:bundleid from:[NSString stringWithUTF8String:pkgname]];
                        }else{
                            [_instProxy install:[NSString stringWithUTF8String:pkgname]];
                        }
                    }else{
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            _isLoading=NO;
                            HUD.text=@"文件读取失败!";
                            [HUD hide:YES afterDelay:1];
                        });
                    }
                });
            }
        }//OK button clicked
        openDlg = nil;
    }];
}

- (void)uninstallAction:(id)sender {
    AMApplication* app=[sender representedObject];
    if (app) {
        NSString* appid=app.bundleid;
        //uninstall
        if (_isLoading) {
            return;
        }
        _isLoading=YES;
        MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.text=@"";
        dispatch_async(_gcdQueue, ^{
            [_instProxy uninstall:appid];
        });
    }
}

- (void)archiveAction:(id)sender {
    NSString* appid=nil;
    AMApplication* app=[sender representedObject];
    if (app) {
        appid=app.bundleid;
    }
    if(appid==nil)return;
    
    __block NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    NSArray *fileTypesArray=@[@"ipa", @"zip"];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowedFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:NO];
    
    [openDlg beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSArray *files = [openDlg URLs];
            if (files.count>0) {
                NSURL *url=(NSURL*)[files objectAtIndex:0];
                NSString* path=[[url pathComponents] componentsJoinedByString:@"/"];
                //install
                if (_isLoading) {
                    return;
                }
                _isLoading=YES;
                MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                HUD.text=@"";
                dispatch_async(_gcdQueue, ^{
                    [_instProxy archive:appid container:YES payload:YES uninstall:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _isLoading=YES;
                        HUD.text=@"正在复制文件到本地...";
                    });
                    
                    NSString* remotePath=[NSString stringWithFormat:@"%s/%@.zip", G_APPARCH_PATH, appid];
                    NSString* localPath=[NSString stringWithFormat:@"%@/%@.ipa",path,appid];
                    AFCFileReference* afcFile=[_afcMediaDir openForRead:remotePath];
                    
                    unsigned long long fsize=[[[_afcMediaDir getFileInfo:remotePath] objectForKey:@"st_size"] unsignedLongLongValue];
                    uint32_t amount = 0;
                    uint32_t total = 0;
                    char buf[8192];
                    FILE *f = NULL;
                    f = fopen([localPath UTF8String], "w");
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
                    //remove from device
                    [_instProxy removeArchive:appid];
                    //show result
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _isLoading=NO;
                        if (fsize==total) {
                            [HUD hide:YES];
                        }else{
                            HUD.text=@"文件无法复制到本地";
                            [HUD hide:YES afterDelay:1];
                        }
                    });
                });
            }
        }//OK button clicked
        openDlg=nil;
    }];
}

- (IBAction)refrechAction:(id)sender {
    [self loadApplications];
}

- (void)restoreAction:(id)sender {
    NSDictionary* app=[sender representedObject];
    if (app) {
        NSString* appid=[app objectForKey:@"CFBundleIdentifier"];
        if (_isLoading) {
            return;
        }
        _isLoading=YES;
        MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.text=@"";
        dispatch_async(_gcdQueue, ^{
            [_instProxy restore:appid];
        });
    }
}

- (void)removeAction:(id)sender {
    NSDictionary* app=[sender representedObject];
    if (app) {
        NSString* appid=[app objectForKey:@"CFBundleIdentifier"];
        if (_isLoading) {
            return;
        }
        _isLoading=YES;
        MBProgressHUD* HUD=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.text=@"";
        dispatch_async(_gcdQueue, ^{
            [_instProxy removeArchive:appid];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadArchives];
            });
        });
    }
}

- (IBAction)refreshArchAction:(id)sender {
    [self loadArchives];
}

-(void)openAction:(id)sender{
    AMApplication* app=[sender representedObject];
    if (app&&nil==_appManagerCtr) {
        _appManagerCtr=[[AppFileManagerController alloc] initWithApplication:app device:_device];
        NSWindow *win=[_appManagerCtr window];
        //[NSApp runModalForWindow:win];
        [NSApp beginSheet:win
           modalForWindow:[NSApp keyWindow]
            modalDelegate:self didEndSelector:@selector(closeAction:) contextInfo:nil];
    }
}
-(void)closeAction:(id)sender{
    _appManagerCtr=nil;
}

#pragma mark tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if (tableView==_appListView) {
        return _applications.count;
    }else if(tableView==_archiveListView){
        return _archives.count;
    }
    return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSDictionary* obj=nil;
    if (tableView==_appListView) {
        obj = [_applications objectAtIndex:row];
    }else if(tableView==_archiveListView){
        obj = [_archives objectAtIndex:row];
    }
    return obj;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    return YES;
}

#pragma mark menu
- (void)menuNeedsUpdate:(NSMenu *)menu{
    NSInteger selectIndex=[_tabView indexOfTabViewItem:[_tabView selectedTabViewItem]];
    NSTableView* mytable;
    if (selectIndex==0) {
        mytable=_appListView;
    }else{
        mytable=_archiveListView;
    }
    NSInteger clickedrow = [mytable clickedRow];
    NSInteger clickedcol = [mytable clickedColumn];
    
    if (clickedrow > -1 && clickedcol > -1) {
        if ([mytable selectedRow]!=clickedrow) {
            [mytable deselectRow:[mytable selectedRow]];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:clickedrow];
            [mytable selectRowIndexes:indexSet byExtendingSelection:clickedrow];
        }

        //construct a menu based on column and row
        NSArray *items = [self constructMenuItemsForRow:clickedrow andColumn:clickedcol tabIndex:selectIndex];
        
        //strip all the existing stuff
        [menu removeAllItems];
        
        //then repopulate with the menu that you just created
        for(NSMenuItem *item in items)
        {
            [menu addItem:item];
        }
    }
}
-(NSArray *)constructMenuItemsForRow:(NSInteger)row andColumn:(NSInteger)col tabIndex:(NSInteger)index
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if (index==0) {
        AMApplication* app=[_installedApps objectAtIndex:row];
        NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:@"卸载" action:@selector(uninstallAction:) keyEquivalent:@""];
        item1.target=self;
        [item1 setRepresentedObject:app];
        [arr addObject:item1];
        
        NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:@"导出" action:@selector(archiveAction:) keyEquivalent:@""];
        item2.target=self;
        [item2 setRepresentedObject:app];
        [arr addObject:item2];
        
        NSMenuItem *item3 = [[NSMenuItem alloc] initWithTitle:@"打开" action:@selector(openAction:) keyEquivalent:@""];
        item3.target=self;
        [item3 setRepresentedObject:app];
        [arr addObject:item3];
    }else{
        NSDictionary* app=[_archives objectAtIndex:row];
        NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:@"恢复" action:@selector(restoreAction:) keyEquivalent:@""];
        item1.target=self;
        [item1 setRepresentedObject:app];
        [arr addObject:item1];
        
        NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:@"删除" action:@selector(removeAction:) keyEquivalent:@""];
        item2.target=self;
        [item2 setRepresentedObject:app];
        [arr addObject:item2];
    }
    return arr;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    return YES;
}


@end
