//
//  SEDispatchTimer.m
//  GCDObjects
//
//  Created by bryn austin bellomy on 7.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import <BrynKit/BrynKit.h>
#import <GCDThreadsafe/GCDThreadsafe.h>

#import "SEDispatchTimer.h"
#import "SEDispatchSource.h"



@interface SEDispatchTimer () {}
@end

@implementation SEDispatchTimer {}

#pragma mark- Lifecycle
#pragma mark-

BKImplementConvenienceInitializer( timer,WithIntervalInNanoseconds:, uint64_t, interval,
                                                            leeway:, uint64_t, leeway );

BKImplementConvenienceInitializer( timer,WithIntervalInNanoseconds:, uint64_t, interval,
                                                            leeway:, uint64_t, leeway,
                                                             queue:, dispatch_queue_t, queue );


- (instancetype) initWithIntervalInNanoseconds: (uint64_t)interval
                                        leeway: (uint64_t)leeway
                                         queue: (dispatch_queue_t)queue
{
    self = [super initWithType:DISPATCH_SOURCE_TYPE_TIMER
                        handle:0 mask:0
                         queue:queue];
    if ( self )
    {
        [self commonInitWithInterval:interval leeway:leeway];
    }
    return self;
}



- (instancetype) initWithIntervalInNanoseconds:(uint64_t)interval
                                        leeway:(uint64_t)leeway
{
    self = [super initWithType:DISPATCH_SOURCE_TYPE_TIMER
                        handle:0 mask:0
                    queueLabel:"com.signalenvelope.SEDispatchTimer"
                     queueType:DISPATCH_QUEUE_SERIAL];
    if ( self )
    {
        [self commonInitWithInterval:interval leeway:leeway];
    }
    return self;
}

- (void) commonInitWithInterval: (uint64_t)interval
                         leeway: (uint64_t)leeway
{
    yssert_notNull( self.source );

    _interval = interval;
    _leeway   = leeway;

    dispatch_source_set_timer( self.source,
                              dispatch_walltime( NULL, 0 ),
                              _interval,
                              _leeway );
}



- (void) setInterval:(uint64_t)interval
{
    _interval = interval;

    dispatch_source_set_timer( self.source,
                               dispatch_walltime( NULL, 0 ),
                               _interval,
                               _leeway );
}



- (void) setLeeway:(uint64_t)leeway
{
    _leeway = leeway;

    dispatch_source_set_timer( self.source,
                               dispatch_walltime( NULL, 0 ),
                               _interval,
                               _leeway );
}


@end







