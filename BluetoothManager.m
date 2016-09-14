//
//  BluetoothManager.m
//  avea-cli
//
//  Created by Glenn Forbes on 05/09/2016.
//  Copyright © 2016 Glenn Forbes. All rights reserved.
//

#import "BluetoothManager.h"

@implementation BluetoothManager
@synthesize peripheralUUIDs, bytesToSend, aveaPeripheral, centralManager, writeCompletionHandler;

static NSString *ColorServiceUUID = @"F815E810-456C-6761-746F-4D756E696368";
static NSString *ColorCharacteristicUUID = @"F815E811-456C-6761-746F-4D756E696368";

- (id)init
{
    self = [super init];
    
    return self;
}

- (void)sendBytes:(NSArray *)bytes completionHandler:(void (^)(void))handler
{
    bytesToSend = bytes;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    writeCompletionHandler = handler;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name containsString:@"Avea"])
    {
        NSLog(@"[CentralManager] Discovered peripheral %@", peripheral.name);
        
        [centralManager connectPeripheral:peripheral options:nil];
        aveaPeripheral = peripheral;
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"[CentralManager] State: %ld", (long)central.state);
    
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"[CentralManager] Powered On");
        
        [centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"[CentralManager] Connected to peripheral %@", peripheral.name);
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:ColorServiceUUID]]];
    NSLog(@"[CBPeripheral] Looking for color service.");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *serv in peripheral.services)
    {
        if ([serv.UUID.UUIDString isEqualToString:ColorServiceUUID])
        {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ColorCharacteristicUUID]] forService:serv];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"[CBPeripheral] Found characteristic.");
    
    NSArray *characteristics = service.characteristics;
    
    if (characteristics.count == 0)
    {
        NSLog(@"[CBPeripheral No characteristics set on service.");
        return;
    }

    for (CBCharacteristic *ca in service.characteristics)
    {
        if ([ca.UUID.UUIDString isEqualToString:ColorCharacteristicUUID])
        {
            NSMutableData *data = [[NSMutableData alloc] initWithCapacity:bytesToSend.count];
            for (int i=0; i<bytesToSend.count; i++)
            {
                id obj = [bytesToSend objectAtIndex:i];
                if ([obj isKindOfClass:[NSNumber class]])
                {
                    NSNumber *num = (NSNumber *)obj;
                    UInt8 byte = [num unsignedIntValue];
                    [data appendBytes: &byte length:1];
                    
                }
                else
                {
                    NSLog(@"this shit");
                    NSArray *byteArray = (NSArray *)obj;
                    for (NSNumber *num in byteArray)
                    {
                        char byte = [num unsignedShortValue];
                        [data appendBytes: &byte length:1];
                    }
                }
            }
            //NSString *bye = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //NSLog(@"%@", data);
            
            //NSString *str = @"35 da 0a 5e 1d 57 2c 4f 3b 00 00 00 00 00 00 64 0c";
            //NSData *d = [[self class] dataFromHexString:str];
            
            [peripheral writeValue:data forCharacteristic:ca type:CBCharacteristicWriteWithResponse];
        }
    }
}

+ (NSData *)dataFromHexString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBPeripheral] Data sent.");
    
    //[self writeCompletionHandler];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBPeripheral] Received data.");
}

@end
