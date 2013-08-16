//
//  SEDispatchSource.h
//  GCDObjects
//
//  Created by bryn austin bellomy on 1/18/13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <GCDThreadsafe/GCDThreadsafe.h>
#import <BrynKit/BrynKit.h>

typedef NS_ENUM( NSUInteger, SEDispatchSourceState ) {
    SEDispatchSourceState_Suspended = 1,
    SEDispatchSourceState_Resumed   = 2,
    SEDispatchSourceState_Canceled  = 3
};

@class SEDispatchSource;

typedef void(^SEDispatchSourceHandlerBlock)(SEDispatchSource *);



/**
 * An Objective-C object wrapper for a Grand Central Dispatch `dispatch_source_t`.
 */
@interface SEDispatchSource : NSObject <GCDThreadsafe>

/**---------------------------------------------------------------------------------------
 * @name Properties
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Properties
#pragma mark-

/** The underlying GCD `dispatch_source_t` that fires events for our handler. */
@property (atomic, gcd_strong, readonly) dispatch_source_t source;

/** The `dispatch_queue_t` on which to handle events sent by the dispatch source. */
@property (atomic, gcd_strong, readonly) dispatch_queue_t queue;

/** The block that's called when GCD is able to respond to pending events from this dispatch source. */
@property (atomic, copy, readwrite) SEDispatchSourceHandlerBlock handler;

/** The block that's called when the GCD queue is canceled. */
@property (atomic, copy, readwrite) dispatch_block_t cancelation;

/** The block that's called when the source is finished initializing. */
@property (atomic, copy, readwrite) dispatch_block_t registration;

/** A C function called after the `dispatch_source_t` has been deallocated and destroyed. */
@property (atomic, assign, readwrite) dispatch_function_t finalizer;

/** An enum value representing the current state of the `dispatch_source_t`. */
@property (atomic, assign, readonly) SEDispatchSourceState state;

/** The user-provided context that can be accessed by the underlying `dispatch_source_t`. */
@property (atomic, assign, readwrite) void *context;



/**---------------------------------------------------------------------------------------
 * @name Create a new SEDispatchSource object
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Initializers
#pragma mark-

//BKInitializerIsUnsupported( init );

/**
 * @param source An already-initialized `dispatch_source_t` that will fire the events handled by the returned `SEDispatchSource`.
 * @param queue An already-initialized `dispatch_queue_t` on which the `dispatch_source_t`'s event handler will run.
 * @param handler A block to execute every time events are handled by the `dispatch_source_t`.
 * @param registration A block to execute when the `dispatch_source_t` finishes initializing.
 * @param cancelation A block to execute after the `dispatch_source_t` is canceled.
 */
//+ (instancetype) dispatchSourceWithSource:(dispatch_source_t)source
//                                  onQueue:(dispatch_queue_t)queue;

/**
 * @param type
 * @param handle
 * @param mask
 * @param queue
 */
+ (instancetype) dispatchSourceWithType:(dispatch_source_type_t)type
                                 handle:(uintptr_t)handle
                                   mask:(unsigned long)mask
                                  queue:(dispatch_queue_t)queue;

/**
 * @param type
 * @param handle
 * @param mask
 * @param queueLabel
 * @param queueType
 */
+ (instancetype) dispatchSourceWithType:(dispatch_source_type_t)type
                                 handle:(uintptr_t)handle
                                   mask:(unsigned long)mask
                             queueLabel:(char *)queueLabel
                              queueType:(dispatch_queue_attr_t)queueType;



//- (instancetype) initWithSource:(dispatch_source_t)source
//                        onQueue:(dispatch_queue_t)queue;

/**
 * @param type
 * @param handle
 * @param mask
 * @param queue
 */
- (instancetype) initWithType:(dispatch_source_type_t)type
                       handle:(uintptr_t)handle
                         mask:(unsigned long)mask
                        queue:(dispatch_queue_t)queue;

/**
 * @param type
 * @param handle
 * @param mask
 * @param queueLabel
 * @param queueType
 */
- (instancetype) initWithType:(dispatch_source_type_t)type
                       handle:(uintptr_t)handle
                         mask:(unsigned long)mask
                   queueLabel:(char *)queueLabel
                    queueType:(dispatch_queue_attr_t)queueType;


/**---------------------------------------------------------------------------------------
 * @name Working with the dispatch source
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Actions
#pragma mark-

/** Suspend the dispatch source.  The source must be in the `resumed` state. */
- (void) suspend;

/** Start a new dispatch source or restart a stopped/paused dispatch source.  The source must be in the `suspended` state. */
- (void) resume;

/** Tear down a dispatch source.  No new blocks can be submitted by the source.  The source must not already be canceled. */
- (void) cancel;

/** Suspend the dispatch source.  If the source is already paused, this method does nothing. */
- (void) ensureSuspended;

/** Start a new dispatch source or restart a stopped/paused dispatch source.  If the source is already resumed, this method does nothing.*/
- (void) ensureResumed;

/** Tear down a dispatch source. No new blocks can be submitted by the source.  If the source is already canceled, this method does nothing. */
- (void) ensureCanceled;

/** Retrieve the coalesced data from messages sent to the `dispatch_source_t`. */
- (unsigned long) getData;

/** Send new data to the `dispatch_source_t`. */
- (void) mergeData:(unsigned long)value;

@end




