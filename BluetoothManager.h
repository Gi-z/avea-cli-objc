//
//  BluetoothManager.h
//  avea-cli
//
//  Created by Glenn Forbes on 06/09/2016.
//  Copyright © 2016 Glenn Forbes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)sendBytes:(NSArray *)bytes completionHandler:(void (^)(void))handler;

@property (strong, nonatomic) NSArray *peripheralUUIDs;
@property (strong, nonatomic) NSArray *bytesToSend;
@property (strong, nonatomic) CBPeripheral *aveaPeripheral;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (nonatomic) void (^writeCompletionHandler)(void);

@end

