//
//  SEDispatchSource.m
//  GCDObjects
//
//  Created by bryn austin bellomy on 1/18/13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import <libextobjc/EXTAnnotation.h>
#import <GCDThreadsafe/GCDThreadsafe.h>
#import <BrynKit/BrynKit.h>

#import "SEDispatchSource.h"


@interface SEDispatchSource ()
{
    SEDispatchSourceHandlerBlock    _handler;
    dispatch_block_t                _cancelation, _registration;
    dispatch_function_t             _finalizer;
}

@property (atomic,    gcd_strong, readwrite) dispatch_source_t source;
@property (atomic,    gcd_strong, readwrite) dispatch_queue_t queue;
@property (atomic,    assign,     readwrite) SEDispatchSourceState state;

@end




@implementation SEDispatchSource {}

#pragma mark- Lifecycle
#pragma mark-

//@designatedInitializer( SEDispatchSource, initWithType:handle:mask:queue: );

/** unsupported initializers */

//BKImplementUnsupportedInitializers( init );


/** convenience class initializers */

//BKImplementConvenienceInitializer( dispatchSource,WithSource:, dispatch_source_t, source,
//                                                     onQueue:, dispatch_queue_t,  queue );

BKImplementConvenienceInitializer( dispatchSource,WithType:, dispatch_source_type_t, type,
                                                    handle:, uintptr_t, handle,
                                                      mask:, unsigned long, mask,
                                                     queue:, dispatch_queue_t, queue );

BKImplementConvenienceInitializer( dispatchSource,WithType:, dispatch_source_type_t, type,
                                                    handle:, uintptr_t, handle,
                                                      mask:, unsigned long, mask,
                                                queueLabel:, char *, queueLabel,
                                                 queueType:, dispatch_queue_attr_t, queueType );



- (instancetype) initWithType: (dispatch_source_type_t)type
                       handle: (uintptr_t)handle
                         mask: (unsigned long)mask
                        queue: (dispatch_queue_t)foreignQueue
{
    yssert_notNil( foreignQueue );

    self = [super init];
    if (self)
    {
        gcd_retainUntilScopeExit( queue );

        // create our local dispatch queue and point it at the foreign queue
        _queue = dispatch_queue_create( "com.signalenvelope.GCDObjects.SEDispatchSource", DISPATCH_QUEUE_SERIAL );
        dispatch_set_target_queue( _queue, foreignQueue );

        [self commonInitWithType:type handle:handle mask:mask];
    }
    return self;
}



- (instancetype) initWithType: (dispatch_source_type_t)type
                       handle: (uintptr_t)handle
                         mask: (unsigned long)mask
                   queueLabel: (char *)queueLabel
                    queueType: (dispatch_queue_attr_t)queueType
{
    self = [super init];
    if (self)
    {
        // create our local dispatch queue as a private queue
        _queue = dispatch_queue_create( queueLabel, queueType );

        [self commonInitWithType:type handle:handle mask:mask];
    }
    return self;
}



- (void) commonInitWithType: (dispatch_source_type_t)type
                     handle: (uintptr_t)handle
                       mask: (unsigned long)mask
{
    yssert_notNil( _queue );
    GCDInitializeQueue( _queue );

    // create our dispatch source
    _source = dispatch_source_create( type, handle, mask, _queue );
    yssert_notNil( _source );

    _state  = SEDispatchSourceState_Suspended;
}



- (void) dealloc
{
    if ( self.state != SEDispatchSourceState_Canceled )
    {
        [self cancelImmediately];
    }

    gcd_release( _queue );
    gcd_release( _source );
}



#pragma mark- State transitions
#pragma mark-

- (void) suspend
{
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);
        if ( !self ) { return; }

        yssert( self.state == SEDispatchSourceState_Resumed );

        dispatch_suspend( self.source );
        self.state = SEDispatchSourceState_Suspended;
    }];
}



- (void) resume
{
//    @weakify(self);

    [self runCriticalMutableSection:^{
//        @strongify(self);

        yssert( self.state == SEDispatchSourceState_Suspended );

        dispatch_resume( self.source );
        self.state = SEDispatchSourceState_Resumed;
    }];
}



- (void) cancel
{
//    @weakify(self);

    [self runCriticalMutableSection:^{
//        @strongify(self);

        [self cancelImmediately];
    }];
}



- (void) cancelImmediately
{
    yssert( self.state != SEDispatchSourceState_Canceled );

    // when cancelling, must make sure we resume first if we're suspended
    if ( self.state == SEDispatchSourceState_Suspended )
    {
        dispatch_resume( self.source );
    }

    dispatch_source_cancel( self.source );
//    gcd_release( self.source );
//    self.source = nil;
//
//    gcd_release( self.queue );
//    self.queue = nil;

    self.state = SEDispatchSourceState_Canceled;
}



- (void) ensureSuspended
{
    if ( self.state == SEDispatchSourceState_Suspended ) {
        return;
    }

    [self suspend];
}



- (void) ensureResumed
{
    if ( self.state == SEDispatchSourceState_Resumed ) {
        return;
    }

    [self resume];
}



- (void) ensureCanceled
{
    if ( self.state == SEDispatchSourceState_Canceled ) {
        return;
    }

    [self cancel];
}


/**---------------------------------------------------------------------------------------
 * @name Accessors
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Accessors
#pragma mark-

@gcd_threadsafe_implementGetter_dispatch( SEDispatchSourceHandlerBlock, handler );
@gcd_threadsafe_implementGetter_dispatch( dispatch_block_t, registration );
@gcd_threadsafe_implementGetter_dispatch( dispatch_block_t, cancelation );
@gcd_threadsafe_implementGetter_dispatch( dispatch_function_t, finalizer );



- (void) setHandler:(SEDispatchSourceHandlerBlock)handler
{
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);

        _handler = handler;
        dispatch_source_set_event_handler(self.source, ^{
            @strongify(self);
            if ( !self ) { return; }

            if ( _handler ) {
                _handler( self );
            }
        });
    }];
}



- (void) setRegistration:(dispatch_block_t)registration
{
    [self runCriticalMutableSection:^{
        _registration = registration ?: ^{};
        dispatch_source_set_registration_handler( self.source, _registration );
    }];
}



- (void) setCancelation:(dispatch_block_t)cancelation
{
    [self runCriticalMutableSection:^{
        _cancelation = cancelation ?: ^{};
        dispatch_source_set_cancel_handler( self.source, _cancelation );
    }];
}



- (void) setFinalizer:(dispatch_function_t)finalizer
{
    [self runCriticalMutableSection:^{
        _finalizer = finalizer ?: SEDispatchSource_emptyFinalizer;
        dispatch_set_finalizer_f( self.source, _finalizer );
    }];
}



- (void *) context
{
    __block void *context = NULL;

    @weakify(self);

    [self runCriticalReadSection:^{
        @strongify(self);
        context = dispatch_get_context( self.source );
    }];

    return context;
}



- (void) setContext:(void *)context
{
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);
        dispatch_set_context( self.source, context );
    }];
}



void SEDispatchSource_emptyFinalizer() {}



#pragma mark- Grand Central Dispatch API wrappers
#pragma mark-

- (unsigned long) getData
{
    __block unsigned long data = 0;

    @weakify(self);

    [self runCriticalReadSection:^{
        @strongify(self);
        data = dispatch_source_get_data( self.source );
    }];

    return data;
}



- (void) mergeData:(unsigned long)value
{
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);
        dispatch_source_merge_data( self.source, value );
    }];
}


@end








