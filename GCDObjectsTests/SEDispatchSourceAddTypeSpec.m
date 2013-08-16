//
//  SEDispatchSourceAddTypeSpec.m
//  GCDObjects
//
//  Created by bryn austin bellomy on 8.12.13.
//  Copyright 2013 signalenvelope llc. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import "Kiwi.h"
#import "SEDispatchSource.h"

SPEC_BEGIN(SEDispatchSourceAddTypeSpec)

describe(@"SEDispatchSource (type ADD)", ^{
    __block SEDispatchSource *source = [SEDispatchSource dispatchSourceWithType:DISPATCH_SOURCE_TYPE_DATA_ADD
                                                                         handle:0 mask:0
                                                                     queueLabel:"com.signalenvelope.SEDispatchSourceSpec.sourceQueue"
                                                                      queueType:DISPATCH_QUEUE_SERIAL];

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

        it(@"should be able to return that context by accessing the context property", ^{
            char *contextStr = (char *)source.context;
            [[theValue( strcmp("xyzzy", contextStr) ) should] equal:0 withDelta:0];
        });
    });

    context(@"when assigned a non-NULL handler block and then resumed", ^{
        __block NSNumber *didCallHandler   = @NO;
        __block NSMutableArray *dataValues = @[].mutableCopy;

        beforeAll(^{
            source.handler = ^(SEDispatchSource *source) {
                didCallHandler = @YES;
                NSNumber *data = @( [source getData] );

                [dataValues addObject: data];
            };
            [source resume];
        });

        it(@"should reflect the presence of that handler block through its 'handler' property", ^{
            [[theValue( source.handler ) should] beNonNil];
        });



        context(@"when non-zero data is merged in", ^{
            beforeAll(^{ [source mergeData:7]; });

            it(@"should call the handler block", ^{ [[expectFutureValue( didCallHandler ) shouldEventually] beYes]; });
            it(@"should yield non-zero values on its 'data' property", ^{
                [[expectFutureValue( theValue(dataValues.count) ) shouldEventually] beGreaterThan: theValue(0)];
                [[expectFutureValue( dataValues[0] ) shouldEventually] equal:7 withDelta:0];
            });
        });


    });

});

SPEC_END






