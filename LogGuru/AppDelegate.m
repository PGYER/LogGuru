//
//  AppDelegate.m
//  FIRForMac
//
//  Created by Travis on 14-9-21.
//  Copyright (c) 2014年 Fly It Remotely International Corporation. All rights reserved.
//

#import "AppDelegate.h"
#import "FIRUSBLoger.h"


@interface AppDelegate ()<NSCollectionViewDelegate>

@property (weak) IBOutlet NSTextField *statView;
@property (unsafe_unretained) IBOutlet NSTextView *logView;
@property (weak) IBOutlet NSWindow *window;

@property (strong) FIRUSBLoger *logger;

@property (strong) NSMutableArray *blockProcesses;

@property (strong) NSMutableArray *lightProcesses;

@property(assign) BOOL showDeviceName;
@property(assign) BOOL showDate;
@property(assign) BOOL paused;

@end

@implementation AppDelegate

- (IBAction)cleanLog:(id)sender {
    if (self.logView.textStorage.length>0) {
        [self.logView.textStorage deleteCharactersInRange:NSMakeRange(0, self.logView.textStorage.length-1)];
    }
}

- (IBAction)pauseLog:(id)sender {
    self.paused=!self.paused;
    
    NSToolbarItem* item=sender;
    if(item){
        if(self.paused){
            item.label=@"Log";
            item.image=[NSImage imageNamed:@"NSPlayTemplate"];
        }else{
            item.label=@"Pause";
            item.image=[NSImage imageNamed:@"NSPauseTemplate"];
        }
    }
    
}



-(void)logMsg:(NSDictionary*)logInfo{
    //printf("%s",[msg UTF8String]);
    
    if(self.paused) {
        return;
    }
    
    if ([self.blockProcesses containsObject:logInfo.process]) {
        return;
    }
    
    if ([logInfo.process isEqualToString:@"syslog_relay"]) {
        if ([logInfo.log rangeOfString:@"Start"].length>0 && self.logView.textStorage.layoutManagers) {
            [self.logView.textStorage appendAttributedString:
             [[NSAttributedString alloc] initWithString:@"────── ✂︎ ────── ✂︎ ────── ✂︎ ────── ✂︎ ────── ✂︎ ──────\n"
                                             attributes:@{
                                                          
                                                          NSFontAttributeName:[NSFont fontWithName:@"Menlo" size:16]
                                                          
                                                          }]
             
             ];
        }
        
        //[self.logView setString:@""];
        //[self.logView.textStorage deleteCharactersInRange:NSMakeRange(0, self.logView.textStorage.length-1)];
        //        [self.logView.textStorage appendAttributedString:
        //         [[NSAttributedString alloc] initWithString:@"FIR.im Log Service Start...\n"]
        //         ];
    }else{
        NSColor *dateBg,*dateFg,*processBg,*processFg,*logBg,*logFg;
        
        //date
        NSInteger level=logInfo.level;
        switch (level) {
            case LogNotice:
            case LogAll:
                dateBg=[NSColor clearColor];
                dateFg=[NSColor blackColor];
                break;
            case LogWarning:
                dateBg=[NSColor orangeColor];
                dateFg=[NSColor blueColor];
                break;
            case LogError:
                dateBg=[NSColor redColor];
                dateBg=[NSColor whiteColor];
                break;
        }
        
        if (self.showDeviceName) {
            [self.logView.textStorage appendAttributedString:
             [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[%@]",logInfo.device]
                                             attributes:@{
                                                          
                                                          NSFontAttributeName:[NSFont fontWithName:@"Menlo" size:13]
                                                          
                                                          }]
             
             ];
        }
        
        
        if (self.showDate) {
            [self.logView.textStorage appendAttributedString:
             [[NSAttributedString alloc] initWithString:[logInfo.date substringFromIndex:7] attributes:@{
                                                                                                         NSBackgroundColorAttributeName:dateBg,
                                                                                                         NSForegroundColorAttributeName:dateFg,
                                                                                                         NSFontAttributeName:[NSFont fontWithName:@"Menlo" size:13]
                                                                                                         }]
             
             ];
        }
        
        
        //process
        
        
        processFg=[NSColor brownColor];
        processBg=[NSColor whiteColor];
        
        [self.logView.textStorage appendAttributedString:
         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@➜",logInfo.process] attributes:@{
                                                                                                                     NSBackgroundColorAttributeName:processBg,
                                                                                                                     NSForegroundColorAttributeName:processFg,
                                                                                                                     NSFontAttributeName:[NSFont boldSystemFontOfSize:14]
                                                                                                                     }]
         
         ];
        
        
        
        if ([self.lightProcesses containsObject:logInfo.process]) {
            logBg=[NSColor colorWithRed:245/255.0 green:171/255.0 blue:53/255.0 alpha:1];
            logFg=[NSColor whiteColor];
        }else{
            logBg=[NSColor whiteColor];
            logFg=[NSColor lightGrayColor];
        }
        
        [self.logView.textStorage appendAttributedString:
         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",logInfo.log]
                                         attributes:@{
                                                      NSBackgroundColorAttributeName:logBg,
                                                      NSForegroundColorAttributeName:logFg,
                                                      NSFontAttributeName:[NSFont fontWithName:@"Menlo" size:13]
                                                      }]
         
         ];
        
        
        [self.logView scrollRangeToVisible: NSMakeRange(self.logView.textStorage.length, 0)];
        
        
    }
    
}

-(void)logStat:(NSString*)msg{
    [self.logView.textStorage appendAttributedString:
     [[NSAttributedString alloc] initWithString:[msg stringByAppendingString:@"\n"] attributes:@{
                                                                                                 NSBackgroundColorAttributeName:[NSColor grayColor],
                                                                                                 NSForegroundColorAttributeName:[NSColor blackColor]
                                                                                                 }]
     ];
}

-(void)awakeFromNib{
    self.window.backgroundColor=[NSColor whiteColor];
    //self.window.titlebarAppearsTransparent=YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //TODO: cmd+k 清除 明林清@搜狐  18:16:13
    
    NSUserDefaults *df=[NSUserDefaults standardUserDefaults];
    
    self.showDate=![df boolForKey:@"hideDate"];
    self.showDeviceName=[df boolForKey:@"showDeviceName"];
    
    //highlight
    //
    
    self.lightProcesses=[NSMutableArray arrayWithObjects:
                         @"amfid",
                         @"itunesstored",
                         @"installd",
                         @"profiled",
                         //@"ReportCrash",
                         nil];
    
    self.blockProcesses=[NSMutableArray arrayWithObjects:
                         @"kernel",
                         @"atc",
                         @"lsd",
                         @"assetsd",
                         @"assistant_service",
                         @"assertiond",
                         @"backboardd",
                         @"cloudd",
                         @"calaccessd",
                         @"callservicesd",
                         @"configd",
                         @"discoveryd",
                         @"dataaccessd",
                         @"familycircled",
                         @"geod",
                         @"geocorrectiond",
                         @"healthd",
                         @"kbd",
                         @"locationd",
                         @"lockdownd",
                         @"identityservicesd",
                         @"mediaserverd",
                         @"mstreamd",
                         @"networkd",
                         @"nfcd",
                         @"sharingd",
                         @"seld",
                         @"searchd",
                         @"safarifetcherd",
                         @"syncdefaultsd",
                         @"pipelined",
                         @"pppd",
                         @"tccd",
                         @"timed",
                         @"ubd",
                         @"wifid",
                         @"CommCenter",
                         @"CallHistorySyncHelper",
                         @"InCallService",
                         @"SpringBoard",
                         @"WirelessRadioManagerd",
                         @"MessagesNotificationViewService",
                         @"com.apple.AppleHDQGasGauge",
                         @"com.apple.voicetrigger.voicetriggerservice",
                         @"com.apple.WebKit.WebContent",
                         
                         @"AppStore",
                         @"MobileMail",
                         @"MobileCal",
                         @"MobileSafari",
                         @"MobileSMS",
                         @"Preferences",
                         
                         @"UserEventAgent",
                         nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DeviceLog" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self logMsg:note.userInfo];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DeviceChange" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSDictionary *info=note.userInfo;
        
        BOOL connect=[info[@"connect"] boolValue];
        int count=[info[@"count"] intValue];
        NSString *udid=info[@"udid"];
        
        NSString *stat;
        if (count>0) {
            stat=[NSString stringWithFormat:@"%d 台设备已连接",count];
        }else{
            stat=@"等待设备连接";
        }
        [self.statView setStringValue:stat];
        
        [self logStat:[NSString stringWithFormat:@"设备:%@ %@",udid,connect?@"已连接":@"已断开"]];
        
    }];
    
    self.logger=[[FIRUSBLoger alloc] init];
    [self.logger start];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    
    [self.window makeKeyAndOrderFront:self];
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.logger=nil;
}
- (IBAction)openAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://fir.im?utm_source=mac_log_guru"]];
}



@end
