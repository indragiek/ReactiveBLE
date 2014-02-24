//
//  CBCentralManager+RBTAdditions.h
//  ReactiveBLE
//
//  Created by Indragie Karunaratne on 2/24/2014.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

@interface CBCentralManager (RBTAdditions)

/**
 *  Observes the state of the receiver.
 *
 *  @return A signal that sends the current state of the receiver and the new state any time it changes.
 */
- (RACSignal *)rbt_stateSignal;

/**
 *  Scans for peripherals that are advertising services.
 *
 *  @param services An array of CBUUID objects representing services that the app is interested in.
 *  @param options  An optional dictionary specifying options to customize the scan.
 *
 *  @return A signal that sends a tuple containing a discovered `CBPeripheral`, an `NSDictionary`
 *  containing advertisement data, and an `NSNumber` representing the RSSI.
 */
- (RACSignal *)rbt_scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options;

@end
