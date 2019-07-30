//
//  SITimerManager.m
//  SIGCDTimerManager
//
//  Created by Silence on 2019/7/30.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import "SITimerManager.h"

#define kIsStringEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
#define kWeakObj(o)   @autoreleasepool {} __weak typeof(o) o ## Weak = o;

@interface SITimerManager ()

@property (strong, nonatomic) NSMutableDictionary *timerArray;
@property (strong, nonatomic) NSMutableDictionary *timerActionArray;

@end

@implementation SITimerManager

+ (instancetype)manager {
    static SITimerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SITimerManager alloc]init];
        manager.timerArray = [NSMutableDictionary dictionary];
        manager.timerActionArray = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (void)scheduleTimerWithName:(NSString *)name
                     interval:(NSTimeInterval)interval
                        queue:(dispatch_queue_t)queue
                      repeats:(BOOL)repeats
                         type:(SITimerType)type
                       action:(dispatch_block_t)action {
    if (kIsStringEmpty(name)) return;
    if (queue == nil) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    dispatch_source_t timer = [self.timerArray objectForKey:name];
    if (timer == nil) {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        [self.timerArray setObject:timer forKey:name];
    }
    
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    kWeakObj(self)
    if (type == SITimerTypeCancel) {
        [self removeActionCacheForTimer:name];
        dispatch_source_set_event_handler(timer, ^{
            if (action) {
                action();
            }
            if (!repeats) {
                [selfWeak cancelTimerWithName:name];
            }
        });
    }else if (type == SITimerTypeMerge) {
        [self cacheAction:action forTimer:name];
        dispatch_source_set_event_handler(timer, ^{
            NSMutableArray *actionArray = [self.timerActionArray objectForKey:name];
            [actionArray enumerateObjectsUsingBlock:^(dispatch_block_t actionBlock, NSUInteger idx, BOOL * _Nonnull stop) {
                actionBlock();
            }];
            if (!repeats) {
                [selfWeak cancelTimerWithName:name];
            }
        });
    }
    dispatch_resume(timer);
}

- (void)cancelTimerWithName:(NSString *)name {
    dispatch_source_t timer = [self.timerArray objectForKey:name];
    if (!timer) return;
    [self.timerArray removeObjectForKey:name];
    [self.timerActionArray removeObjectForKey:name];
    dispatch_source_cancel(timer);
}

#pragma mark - Private
- (void)cacheAction:(dispatch_block_t)action forTimer:(NSString *)name {
    id actionArray = [self.timerActionArray objectForKey:name];
    if (actionArray && [actionArray isKindOfClass:[NSMutableArray class]]){
        [(NSMutableArray *)actionArray addObject:action];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithObject:action];
        [self.timerActionArray setObject:array forKey:name];
    }
}

- (void)removeActionCacheForTimer:(NSString *)name {
    if (![self.timerActionArray objectForKey:name])return;
    [self.timerActionArray removeObjectForKey:name];
}

@end
