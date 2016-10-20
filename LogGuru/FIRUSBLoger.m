//
//  FIRUSBLoger.m
//  FIR.im
//
//  Created by Travis on 14/12/24.
//  Copyright (c) 2014年 Fly It Remotely International Corporation. All rights reserved.
//

#import "FIRUSBLoger.h"
#import "MobileDevice.h"
#import <AppKit/AppKit.h>


typedef struct {
    service_conn_t connection;
    CFSocketRef socket;
    CFRunLoopSourceRef source;
} DeviceConsoleConnection;

static CFMutableDictionaryRef liveConnections;

static NSRegularExpression *reg;

static int LogLevelLimit;

static void SocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    // Skip null bytes
    ssize_t length = CFDataGetLength(data);
    const char *buffer = (const char *)CFDataGetBytePtr(data);
    while (length) {
        while (*buffer == '\0') {
            buffer++;
            length--;
            if (length == 0)
                return;
        }
        size_t extentLength = 0;
        while ((buffer[extentLength] != '\0') && extentLength != length) {
            extentLength++;
        }
        
        if (extentLength>=3) {
            NSString * msg=[[NSString alloc] initWithBytes:buffer length:extentLength encoding:NSUTF8StringEncoding];
            if([msg rangeOfString:@"libxpc.dylib"].length==0){
                NSArray *matches= [reg matchesInString:msg options:0 range:NSMakeRange(0, msg.length-1)];
                if (matches) {
                    NSTextCheckingResult *restult=[matches lastObject];
                    if (restult.numberOfRanges==6) {
                        int lv=LogAll;
                        NSString *level=[msg substringWithRange:[restult rangeAtIndex:4]];
                        if ([level isEqualTo:@"Notice"]) {
                            lv=LogNotice;
                        }else if ([level isEqualTo:@"Warning"]) {
                            lv=LogWarning;
                        }else if ([level isEqualTo:@"Error"]) {
                            lv=LogNotice;
                        }
                        
                        if (lv>=LogLevelLimit) {
                            NSDictionary *info=@{
                                                 @"date"    :[msg substringWithRange:[restult rangeAtIndex:1]],
                                                 @"device"  :[msg substringWithRange:[restult rangeAtIndex:2]],
                                                 @"process" :[msg substringWithRange:[restult rangeAtIndex:3]],
                                                 @"level"   :@(lv),
                                                 @"log"     :[msg substringWithRange:[restult rangeAtIndex:5]],
                                                 };
                            
                            
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceLog" object:nil userInfo:info];
                        }
                        
                    }
                }

            }
        }
        
        length -= extentLength;
        buffer += extentLength;
    }
}

static void DeviceNotificationCallback(am_device_notification_callback_info *info, void *unknown)
{
    struct am_device *device = info->dev;
    CFStringRef deviceId = AMDeviceCopyDeviceIdentifier(device);
    NSString *udid=[(__bridge NSString*)deviceId copy];
    CFRelease(deviceId);
    
    switch (info->msg) {
        case ADNCI_MSG_CONNECTED: {
            //
            if (AMDeviceConnect(device) == MDERR_OK) {
                if (AMDeviceIsPaired(device) && (AMDeviceValidatePairing(device) == MDERR_OK)) {
                    if (AMDeviceStartSession(device) == MDERR_OK) {
                        service_conn_t connection;
                        if (AMDeviceStartService(device, AMSVC_SYSLOG_RELAY, &connection, NULL) == MDERR_OK) {
                            CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault, connection, kCFSocketDataCallBack, SocketCallback, NULL);
                            if (socket) {
                                CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
                                if (source) {
                                    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
                                    AMDeviceRetain(device);
                                    DeviceConsoleConnection *data = malloc(sizeof *data);
                                    data->connection = connection;
                                    data->socket = socket;
                                    data->source = source;
                                    CFDictionarySetValue(liveConnections, device, data);
                                    
                                    NSDictionary *info=@{
                                                         @"count":@(CFDictionaryGetCount(liveConnections)),
                                                         @"connect":@(1),
                                                         @"udid":udid
                                                         };
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceChange" object:nil userInfo:info];
                                    return;
                                }
                                CFRelease(source);
                            }
                        }
                        AMDeviceStopSession(device);
                    }
                }
            }
            AMDeviceDisconnect(device);
            break;
        }
        case ADNCI_MSG_DISCONNECTED: {
            DeviceConsoleConnection *data = (DeviceConsoleConnection *)CFDictionaryGetValue(liveConnections, device);
            if (data) {
                CFDictionaryRemoveValue(liveConnections, device);
                AMDeviceRelease(device);
                CFRunLoopRemoveSource(CFRunLoopGetMain(), data->source, kCFRunLoopCommonModes);
                CFRelease(data->source);
                CFRelease(data->socket);
                free(data);
                AMDeviceStopSession(device);
                AMDeviceDisconnect(device);
                
                NSDictionary *info=@{
                                     @"count":@(CFDictionaryGetCount(liveConnections)),
                                     @"connect":@(0),
                                     @"udid":udid
                                     };
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceChange" object:nil userInfo:info];
            }
            break;
        }
        default:
            break;
    }
}


@implementation NSDictionary(LogInfo)

-(LogLevel)level{
    return [self[@"level"] integerValue];
}

-(NSString*)log{
    return self[@"log"];
}

-(NSString*)date{
    return self[@"date"];
}

-(NSString*)device{
    return self[@"device"];
}

-(NSString*)process{
    return self[@"process"];
}

@end

@implementation FIRUSBLoger
+(NSDictionary*)logInfo:(NSString*)msg{
    
    
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSError *err;
        
        reg=[NSRegularExpression regularExpressionWithPattern:@"([A-z]{3} {1,2}[0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}) ([^ ]+) ([^\\[]+)\\[[0-9]{1,8}\\] <([^>]+)>: (.+)$" options:0 error:&err];
        
        LogLevelLimit=LogAll;
    }
    return self;
}

-(void)setLevel:(LogLevel)level{
    LogLevelLimit=level;
}
-(LogLevel)level{
    return LogLevelLimit;
}

-(int)start{
    liveConnections = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    am_device_notification *notification;
    AMDeviceNotificationSubscribe(DeviceNotificationCallback, 0, 0, NULL, &notification);
    return 0;
}


@end
