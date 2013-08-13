//
//  SEDispatchSource.m
//  GCDObjects
//
//  Created by bryn austin bellomy on 1/18/13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>
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

/** unsupported initializers */

BKImplementUnsupportedInitializers( SEDispatchSource, initWithSource:onQueue:,
                                    init );


/** convenience class initializers */

BKImplementConvenienceInitializer( dispatchSource,WithSource:, dispatch_source_t, source,
                                                     onQueue:, dispatch_queue_t,  queue );

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
                        queue: (dispatch_queue_t)queue
{
    gcd_retain( queue );

    dispatch_source_t source = dispatch_source_create( type, handle, mask, queue );
    yssert_notNil( source );

    @onExit {
        gcd_release( source );
        gcd_release( queue );
    };

    id instance = [self initWithSource:source onQueue:queue];

    return instance;
}



- (instancetype) initWithType: (dispatch_source_type_t)type
                       handle: (uintptr_t)handle
                         mask: (unsigned long)mask
                   queueLabel: (char *)queueLabel
                    queueType: (dispatch_queue_attr_t)queueType
{
    dispatch_queue_t queue = dispatch_queue_create( queueLabel, queueType );
    yssert_notNil( queue );

    self = [self initWithType:type handle:handle mask:mask queue:queue];
    gcd_release( queue );

    return self;
}



- (instancetype) initWithSource: (dispatch_source_t)source
                        onQueue: (dispatch_queue_t)queue
{
    self = [super init];

    if (self)
    {
        yssert( dispatch_source_testcancel( source ) == 0, @"Don't pass an already-canceled dispatch_source_t to [SEDispatchSource initWithSource:onQueue:]." );

        gcd_retain( queue );
        _queue = queue;

        gcd_retain( source );
        _source = source;

        _state  = SEDispatchSourceState_Suspended;
    }

    return self;
}



- (void) dealloc
{
    if ( self.state != SEDispatchSourceState_Canceled )
    {
        [self cancelImmediately];
    }
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
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);

        yssert( self.state == SEDispatchSourceState_Suspended );

        dispatch_resume( self.source );
        self.state = SEDispatchSourceState_Resumed;
    }];
}



- (void) cancel
{
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);

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
    gcd_release( self.source );
    self.source = nil;

    gcd_release( self.queue );
    self.queue = nil;

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








