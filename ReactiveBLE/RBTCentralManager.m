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
@property (nonatomic, strong, readonly) RACScheduler *CBScheduler;
@property (nonatomic, strong, readonly) CBCentralManager *manager;
@end

@implementation RBTCentralManager

#pragma mark - Initialization

- (id)initWithOptions:(NSDictionary *)options
{
	if ((self = [super init])) {
		dispatch_queue_t queue = dispatch_queue_create("com.indragie.RBTCentralManager.CoreBluetoothQueue", DISPATCH_QUEUE_SERIAL);
		_CBScheduler = [[RACTargetQueueScheduler alloc] initWithName:@"com.indragie.RBTCentralManager.CoreBluetoothScheduler" targetQueue:queue];
		_manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
	}
	return self;
}

- (id)init
{
	return [self initWithOptions:nil];
}

#pragma mark - RAC

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p>", self.class, self];
}

#pragma mark - State

- (RACSignal *)stateSignal
{
	@weakify(self);
	return [[[[[RACSignal defer:^{
		@strongify(self);
		return [[RACSignal return:self.manager] deliverOn:self.CBScheduler];
	}]
	concat:[[self rac_signalForSelector:@selector(centralManagerDidUpdateState:) fromProtocol:@protocol(CBCentralManagerDelegate)]
		reduceEach:^(CBCentralManager *manager) {
			return manager;
		}]]
	map:^(CBCentralManager *manager) {
		return @(manager.state);
	}]
	takeUntil:self.rac_willDeallocSignal]
	setNameWithFormat:@"<%@:%p> -stateSignal", self.class, self];
}

- (RACSignal *)scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options
{
	NSDictionary *copiedOptions = [options copy];
	return [[[[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACDisposable *disposable = [[[self
			rac_signalForSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:) fromProtocol:@protocol(CBCentralManagerDelegate)]
			reduceEach:^(CBCentralManager *manager, CBPeripheral *peripheral, NSDictionary *data, NSNumber *RSSI) {
				return RACTuplePack(peripheral, data, RSSI);
			}]
			subscribe:subscriber];
		
		[self.manager scanForPeripheralsWithServices:services options:copiedOptions];
		
		return [RACDisposable disposableWithBlock:^{
			[disposable dispose];
			[self.CBScheduler schedule:^{
				[self.manager stopScan];
			}];
		}];
	}]
	subscribeOn:self.CBScheduler]
	// Previous signals returned by this method should complete when the method is called again
	// with different scan parameters, since the scanning state is centralized to a single instance
	// of `CBCentralManager`.
	takeUntil:[[self
		rac_signalForSelector:_cmd]
		filter:^BOOL(RACTuple *args) {
			return ![args isEqual:RACTuplePack(services, options)];
		}]]
	setNameWithFormat:@"<%@:%p> -scanForPeripheralsWithServices: %@ options: %@", self.class, self, services, options];
}

- (RACSignal *)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options
{
	NSDictionary *copiedOptions = [options copy];
	return [[[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACDisposable *connectedDisposable = [[[[[self
			rac_signalForSelector:@selector(centralManager:didConnectPeripheral:) fromProtocol:@protocol(CBCentralManagerDelegate)]
			reduceEach:^(CBCentralManager *manager, CBPeripheral *connectedPeripheral) {
				return connectedPeripheral;
			}]
			filter:^BOOL (CBPeripheral *connectedPeripheral) {
				return [connectedPeripheral isEqual:peripheral];
			}]
			take:1]
			subscribe:subscriber];
		
		RACDisposable *failedDisposable = [[[self
			rac_signalForSelector:@selector(centralManager:didFailToConnectPeripheral:error:) fromProtocol:@protocol(CBCentralManagerDelegate)]
			filter:^BOOL(RACTuple *args) {
				return [args.second isEqual:peripheral];
			}]
			subscribeNext:^(RACTuple *args) {
				[subscriber sendError:args.third];
			}];
		
		[self.manager connectPeripheral:peripheral options:copiedOptions];
		
		return [RACDisposable disposableWithBlock:^{
			[connectedDisposable dispose];
			[failedDisposable dispose];
			[self.CBScheduler schedule:^{
				[self.manager cancelPeripheralConnection:peripheral];
			}];
		}];
	}]
	subscribeOn:self.CBScheduler]
	setNameWithFormat:@"<%@:%p> -connectToPeripheral: %@ options: %@", self.class, self, peripheral, options];
}

// Used by -retrievePeripheralsWithIdentifiers: and -retrieveConnectedPeripheralsWithServices:
// since the method signatures are identical.
- (RACSignal *)peripheralsSignalForSelector:(SEL)selector
{
	return [[[self
		rac_signalForSelector:selector fromProtocol:@protocol(CBCentralManagerDelegate)]
		take:1]
		reduceEach:^(CBCentralManager *manager, NSArray *peripherals) {
			return peripherals;
		}];
}

- (RACSignal *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
	return [[[RACSignal
		defer:^{
			RACSignal *signal = [self peripheralsSignalForSelector:@selector(centralManager:didRetrievePeripherals:)];
			[self.manager retrievePeripheralsWithIdentifiers:identifiers];
			return signal;
		}]
		subscribeOn:self.CBScheduler]
		setNameWithFormat:@"<%@:%p> -retrievePeripheralsWithIdentifiers: %@", self.class, self, identifiers];
}

- (RACSignal *)retrieveConnectedPeripheralsWithServices:(NSArray *)services
{
	return [[[RACSignal
		defer:^{
			RACSignal *signal = [self peripheralsSignalForSelector:@selector(centralManager:didRetrieveConnectedPeripherals:)];
			[self.manager retrieveConnectedPeripheralsWithServices:services];
			return signal;
		}]
		subscribeOn:self.CBScheduler]
		setNameWithFormat:@"<%@:%p> -retrieveConnectedPeripheralsWithServices: %@", self.class, self, services];
}

#pragma mark - CBCentralManagerDelegate

// Empty implementation because it's a required method.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {}

@end
