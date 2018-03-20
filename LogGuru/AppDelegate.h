//
//  AppDelegate.h
//  FIRForMac
//
//  Created by Travis on 14-9-21.
//  Copyright (c) 2014年 Fly It Remotely International Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTokenFieldDelegate>

+ (void)logMsg:(NSDictionary *)logInfo;
@end

