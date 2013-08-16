//
//  SEDispatchSourceOrTypeSpec.m
//  GCDObjects
//
//  Created by bryn austin bellomy on 8.12.13.
//  Copyright 2013 signalenvelope llc. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import "Kiwi.h"
#import "SEDispatchSource.h"


//void blah(SEDispatchSource *source)
//{
//    context(@"after initialization", ^{
//        it(@"should not be nil",                        ^{ [source shouldNotBeNil]; });
//        it(@"should have a non-nil dispatch_source_t",  ^{ [source.source shouldNotBeNil]; });
//        it(@"should have a non-nil dispatch_queue_t",   ^{ [source.queue shouldNotBeNil]; });
//        it(@"should return 0 when told to getData",     ^{ [[theValue( [source getData] ) should] equal:0 withDelta:0]; });
//    });
//}



SPEC_BEGIN(SEDispatchSourceOrTypeSpec)

describe(@"SEDispatchSource (type OR)", ^{
    __block SEDispatchSource *source = [SEDispatchSource dispatchSourceWithType:DISPATCH_SOURCE_TYPE_DATA_OR
                                                                         handle:0 mask:0
                                                                     queueLabel:"com.signalenvelope.SEDispatchSourceSpec.sourceQueue"
                                                                      queueType:DISPATCH_QUEUE_SERIAL];
//    blah(source);

    context(@"after initialization", ^{
        it(@"should not be nil",                        ^{ [source shouldNotBeNil]; });
        it(@"should have a non-nil dispatch_source_t",  ^{ [source.source shouldNotBeNil]; });
        it(@"should have a non-nil dispatch_queue_t",   ^{ [source.queue shouldNotBeNil]; });
        it(@"should return 0 when told to getData",     ^{ [[theValue( [source getData] ) should] equal:0 withDelta:0]; });
    });

    context(@"when assigned a non-NULL context", ^{
        beforeEach(^{
            char *contextStr = "xyzzy";
            source.context = (void *)contextStr;
        });

        afterEach(^{ free(source.context); });

        it(@"should be able to return that context via the 'context' property", ^{
            char *contextStr = (char *)source.context;
            [[theValue( strcmp("xyzzy", contextStr) ) should] equal:0 withDelta:0];
        });
    });

    context(@"when assigned a non-NULL handler block and then resumed", ^{
        __block NSNumber *didCallHandler   = @NO;
        __block NSMutableArray *dataValuesReceived = @[].mutableCopy;
        __block NSUInteger dataValuesORed = 0;
        NSArray *dataValuesToSend = @[ @1, @2, @3, @8 ];

        beforeAll(^{
            source.handler = ^(SEDispatchSource *source) {
                didCallHandler = @YES;
                NSNumber *data = @( [source getData] );

                [dataValuesReceived addObject: data];
                dataValuesORed |= data.unsignedIntegerValue;
            };
        });

        it(@"should reflect the presence of that handler block through its 'handler' property", ^{
            [[theValue( source.handler ) should] beNonNil];
        });



        context(@"when non-zero values are merged in synchronously or asynchronously", ^{
            beforeAll(^{
                [source resume];

                dispatch_apply(dataValuesToSend.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
                    NSUInteger valueToSend = [dataValuesToSend[ index ] unsignedIntegerValue];
                    [source mergeData: valueToSend];
                });
            });

            it(@"should call the handler block", ^{ [[expectFutureValue( didCallHandler ) shouldEventually] beYes]; });
            it(@"should yield at least one value on its 'data' property", ^{ [[expectFutureValue( theValue(dataValuesReceived.count) ) shouldEventually] beGreaterThan: theValue(0)]; });
            it(@"should yield values on its 'data' property that, when ORed together, equal the values passed to -mergeData: ORed together, regardless of how GCD coalesces and orders the merge calls", ^{
                NSUInteger dataValuesToSendORed = 0;
                for ( NSNumber *val in dataValuesToSend )
                {
                    dataValuesToSendORed |= val.unsignedIntegerValue;
                }
                [[expectFutureValue( theValue( dataValuesORed ) ) shouldEventually] equal:dataValuesToSendORed withDelta:0];
            });
        });
        
        
    });
    
});

SPEC_END






