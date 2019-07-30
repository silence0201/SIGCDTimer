//
//  SITimerManager.h
//  SIGCDTimerManager
//
//  Created by Silence on 2019/7/30.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SITimerType) {
    SITimerTypeCancel,
    SITimerTypeMerge,
};

NS_ASSUME_NONNULL_BEGIN

@interface SITimerManager : NSObject

+ (instancetype)manager;

- (void)scheduleTimerWithName:(NSString *)name
                     interval:(NSTimeInterval)interval
                        queue:(dispatch_queue_t)queue
                      repeats:(BOOL)repeats
                         type:(SITimerType)type
                       action:(dispatch_block_t)action;

- (void)cancelTimerWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
