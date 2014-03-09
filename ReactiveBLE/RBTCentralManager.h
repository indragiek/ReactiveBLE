//
//  RBTCentralManager.h
//  ReactiveBLE
//
//  Created by Indragie Karunaratne on 2014-02-26.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@class CBPeripheral;
/**
 *  ReactiveCocoa interface to `CBCentralManager`
 */
@interface RBTCentralManager : NSObject

/**
 *  Creates a new instance of `RBTCentralManager`
 *
 *  @param options Optional dictionary of options as described in "Central Manager Initialization Options"
 *  in the `CBCentralManager` documentation.
 *
 *  @return A new instance of `RBTCentralManager`
 */
- (id)initWithOptions:(NSDictionary *)options;

/**
 *  Observes the state of the receiver.
 *
 *  @return A signal that sends the current state of the receiver and the new state any time it changes.
 */
- (RACSignal *)stateSignal;

/**
 *  Scans for peripherals that are advertising services.
 *
 *  A signal returned by this method will complete if this method is called again with different
 *  parameters, since only one scanning session is supported per manager.
 *
 *  @param services An array of CBUUID objects representing services that the app is interested in.
 *  @param options  An optional dictionary specifying options to customize the scan.
 *
 *  @return A signal that sends a tuple containing a discovered `CBPeripheral`, an `NSDictionary`
 *  containing advertisement data, and an `NSNumber` representing the RSSI.
 */
- (RACSignal *)scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options;

/**
 *  Connects to a Bluetooth peripheral.
 *
 *  Disposal of a subscription to this signal will result in the peripheral automatically being
 *  disconnected.
 *
 *  @param peripheral The peripheral to connect to.
 *  @param options    Options to customize the behaviour of the connection. See "Peripheral Connection
 *  Options" in the `CBCentralManager` documentation.
 *
 *  @return A signal that completes on successful connection or errors if the connection fails.
 */
- (RACSignal *)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options;

@end
