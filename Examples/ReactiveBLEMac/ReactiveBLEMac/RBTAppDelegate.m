//
//  RBTAppDelegate.m
//  ReactiveBLEMac
//
//  Created by Indragie Karunaratne on 2/24/2014.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "RBTAppDelegate.h"

@interface RBTAppDelegate ()
@property (nonatomic, strong) RBTCentralManager *manager;
@end

@implementation RBTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.manager = [[RBTCentralManager alloc] init];
	[self.manager.rbt_stateSignal subscribeNext:^(id x) {
		NSLog(@"%@", x);
	}];
}

@end
