//
//  CBCentralManager+RBTAdditions.m
//  ReactiveBLE
//
//  Created by Indragie Karunaratne on 2/24/2014.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "CBCentralManager+RBTAdditions.h"

@implementation CBCentralManager (RBTAdditions)

- (RACSignal *)rbt_stateSignal
{
	return RACObserve(self, state);
}

- (RACSignal *)rbt_scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		[self scanForPeripheralsWithServices:services options:options];
		return [RACDisposable disposableWithBlock:^{
			[self stopScan];
		}];
	}];
}

@end
