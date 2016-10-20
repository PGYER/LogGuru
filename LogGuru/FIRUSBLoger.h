//
//  FIRUSBLoger.h
//  FIR.im
//
//  Created by Travis on 14/12/24.
//  Copyright (c) 2014年 Fly It Remotely International Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    LogAll = 0,
    LogNotice,
    LogWarning,
    LogError
} LogLevel;


@interface NSDictionary(LogInfo)
@property(readonly) LogLevel level;
@property(readonly) NSString *date;
@property(readonly) NSString *log;
@property(readonly) NSString *process;
@property(readonly) NSString *device;

@end

@interface FIRUSBLoger : NSObject

@property(nonatomic, assign) LogLevel level;

+(NSDictionary*)logInfo:(NSString*)msg;
-(int)start;

@end
