//
//  RBTCentralManager.m
//  ReactiveBLE
//
//  Created by Indragie Karunaratne on 2014-02-26.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "RBTCentralManager.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface RBTCentralManager () <CBCentralManagerDelegate>
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, strong, readonly) RACScheduler *delegateScheduler;
@property (nonatomic, strong, readonly) CBCentralManager *manager;
@end

@implementation RBTCentralManager

#pragma mark - Initialization

- (id)initWithOptions:(NSDictionary *)options
{
	if ((self = [super init])) {
		_delegateQueue = dispatch_queue_create("com.indragie.RBTCentralManager.DelegateQueue", DISPATCH_QUEUE_SERIAL);
		_delegateScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"com.indragie.RBTCentralManager.DelegateQueueScheduler" targetQueue:_delegateQueue];
		_manager = [[CBCentralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];
	}
	return self;
}

- (id)init
{
	return [self initWithOptions:nil];
}

#pragma mark - State

- (RACSignal *)stateSignal
{
	@weakify(self);
	return [[[[[RACSignal
		defer:^{
			@strongify(self);
			return [RACSignal return:self.manager];
		}]
		concat:[[self rac_signalForSelector:@selector(centralManagerDidUpdateState:) fromProtocol:@protocol(CBCentralManagerDelegate)]
			reduceEach:^(CBCentralManager *manager) {
				return manager;
			}]]
		map:^(CBCentralManager *manager) {
			return @(manager.state);
		}]
		takeUntil:self.rac_willDeallocSignal]
		setNameWithFormat:@"RBTCentralManager -stateSignal"];
}

- (RACSignal *)scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
    @weakify(self);
    return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        [self.manager scanForPeripheralsWithServices:services options:options];

        [[[self rac_signalForSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:) fromProtocol:@protocol(CBCentralManagerDelegate)]
          reduceEach:^(CBPeripheralManager *manager, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI){
             return RACTuplePack(peripheral, advertisementData, RSSI);
         }]
         subscribe:subscriber];
        
        return [RACDisposable disposableWithBlock:^{
            [self.manager stopScan];
        }];
    }]
    takeUntil:self.rac_willDeallocSignal]
    setNameWithFormat:@"RBTCentralManager -scanForPeripheralsWithServices: %@ options: %@", services, options];;
}

#pragma mark - CBCentralManagerDelegate

// Empty implementation because it's a required method.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {}

@end
