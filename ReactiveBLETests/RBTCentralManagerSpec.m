//
//  RBTCentralManagerSpec.m
//  ReactiveBLE
//
//  Created by Indragie Karunaratne on 2014-02-26.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "RBTCentralManager.h"

SpecBegin(RBTCentralManager)

describe(@"scanning", ^{
	__block RBTCentralManager *manager = nil;
	
	before(^{
		manager = [[RBTCentralManager alloc] init];
	});
	
	it(@"should complete an existing signal when replacing scan parameters", ^{
		__block NSUInteger completed = 0;
		[[manager scanForPeripheralsWithServices:nil options:nil]
		 subscribeCompleted:^{
			completed++;
		}];
		NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey : @YES};
		[[manager scanForPeripheralsWithServices:nil options:options]
		 subscribeCompleted:^{
			completed++;
		}];
		CBUUID *UUID = [CBUUID UUIDWithString:@"E17AC209-E93A-4DDC-B2D7-B484337D8C59"];
		[[[manager scanForPeripheralsWithServices:@[UUID] options:options]
		 publish]
		 connect];
		
		expect(completed).to.equal(2);
	});
});

SpecEnd
