//
//  SEDispatchTimer.h
//  GCDObjects
//
//  Created by bryn austin bellomy on 7.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//


#import "SEDispatchSource.h"

@class SEDispatchTimer;

typedef void(^SEDispatchTimerSourceHandlerBlock)(SEDispatchTimer *);



@interface SEDispatchTimer : SEDispatchSource

@property (atomic, copy, readwrite) SEDispatchTimerSourceHandlerBlock handler;
@property (nonatomic, assign, readwrite) uint64_t interval;
@property (nonatomic, assign, readwrite) uint64_t leeway;

/**---------------------------------------------------------------------------------------
 * @name Initialization
 *  ---------------------------------------------------------------------------------------
 */

#pragma mark- Initialization
#pragma mark-

/**
 * Create a timer with the given nanosecond interval and leeway.
 *
 * @param interval The number of nanoseconds between each `RACEvent` sent by the timer.
 * @param leeway The amount of leeway (in nanoseconds) that the timer is allowed while attempting to schedule on-time `RACEvents`.
 * @return An initialized (but unstarted) `RACDispatchTimer`.
 *
 * @see dispatch_source_set_timer
 **/
+ (instancetype) timerWithIntervalInNanoseconds:(uint64_t)interval leeway:(uint64_t)leeway;

+ (instancetype) timerWithIntervalInNanoseconds:(uint64_t)interval leeway:(uint64_t)leeway queue:(dispatch_queue_t)queue;


/**
 * The designated initializer.  Initializes a timer with the given nanosecond interval and leeway.
 *
 * @param interval The number of nanoseconds between each `RACEvent` sent by the timer.
 * @param leeway The amount of leeway (in nanoseconds) that the timer is allowed while attempting to schedule on-time `RACEvents`.
 * @return An initialized (but unstarted) `RACDispatchTimer`.
 *
 * @see dispatch_source_set_timer
 **/
- (instancetype) initWithIntervalInNanoseconds:(uint64_t)interval leeway:(uint64_t)leeway;

- (instancetype) initWithIntervalInNanoseconds:(uint64_t)interval leeway:(uint64_t)leeway queue:(dispatch_queue_t)queue;

@end





