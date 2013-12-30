//
//  FileManagerController.h
//  iTools
//
//  Created by Jolin He on 13-12-30.
//  Copyright (c) 2013年 Jolin He. All rights reserved.
//

#import "BaseViewController.h"

@interface MediaFileManagerController : BaseViewController{
    __weak IBOutlet NSBrowser *_browser;
}
-(instancetype)initWithDevice:(AFCDirectoryAccess*)fileHander device:(AMDevice*)device;
@end
