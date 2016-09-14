//
//  Avea.m
//  avea-cli
//
//  Created by Glenn Forbes on 05/09/2016.
//  Copyright © 2016 Glenn Forbes. All rights reserved.
//

#import "Avea.h"

@implementation Avea : NSObject

BluetoothManager *bluetoothManagerA;
BOOL running;

- (id)init
{
    self = [super init];
    
    bluetoothManagerA = [[BluetoothManager alloc] init];
    
    return self;
}

- (void)send:(NSArray *)bytes peripheralUUIDs:(NSArray *)uuids newPeripheralHandler:(NSString *)handler
{
    running = true;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    bluetoothManagerA.peripheralUUIDs = uuids;
    
    [bluetoothManagerA sendBytes:bytes completionHandler:^(void)
     {
         dispatch_semaphore_signal(sem);
     }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void)setColor:(struct Color)color peripheralUUIDs:(NSArray *)uuids newPeripheralHandler:(NSString *)handler
{
    [self send:[self getBytesForColor:color] peripheralUUIDs:uuids newPeripheralHandler:handler];
}

- (void)setBrightness:(int)brightness peripheralUUIDs:(NSArray *)uuids newPeripheralHandler:(NSString *)handler
{
    [self send:[self getBytesForBrightness:brightness] peripheralUUIDs:uuids newPeripheralHandler:handler];
}

- (NSArray *)getBytesForBrightness:(int)brightness
{
    NSMutableArray *bytes = [NSMutableArray array];
    
    UInt16 extended = brightness;
    
    [bytes addObject:[NSNumber numberWithInteger:0x57]];
    [bytes addObject:[[self splitWord:extended] objectAtIndex:1]];
    [bytes addObject:[[self splitWord:extended] objectAtIndex:0]];
    
    return bytes;
}

- (NSArray *)splitWord:(UInt16)word
{
    UInt8 d = (word >> 8);
    UInt8 e = (word & 0xFF);
    
    NSNumber *a = [NSNumber numberWithUnsignedInt:d];
    NSNumber *b = [NSNumber numberWithUnsignedInt:e];
    
    return [NSArray arrayWithObjects:a, b, nil];
}

- (UInt16)encodeWhite:(int)color
{
    return [self colorEncodeWithPrefix:8 color:color];
}

- (UInt16)encodeRed:(int)color
{
    return [self colorEncodeWithPrefix:3 color:color];
}

- (UInt16)encodeGreen:(int)color
{
    return [self colorEncodeWithPrefix:2 color:color];
}

- (UInt16)encodeBlue:(int)color
{
    return [self colorEncodeWithPrefix:1 color:color];
}

- (UInt16)colorEncodeWithPrefix:(int)prefix color:(int)color
{
    NSMutableArray *arr = [NSMutableArray array];
    for (int i=0; i<255; i++)
    {
        NSNumber *n = [NSNumber numberWithInt:i];
        [arr addObject:n];
    }
    
    if (![arr containsObject:[NSNumber numberWithInt:color]])
    {
        NSLog(@"Color value out of range.");
        return 0;
    }
    
    int extended = color * 16;
    int prefixMask = prefix << 4;
    
    int lower = (extended >> 8) | prefixMask;
    int higher = extended & 0xFF;
    
    UInt16 ret = (higher << 8) | lower;

    return ret;
}

- (NSArray *)getBytesForColor:(struct Color)color
{
    NSMutableArray *bytes = [NSMutableArray array];
    
    [bytes addObject:[NSNumber numberWithUnsignedInt:0x35]];
    [bytes addObject:[NSNumber numberWithUnsignedInt:0x32]];
    [bytes addObject:[NSNumber numberWithUnsignedInt:0]];
    [bytes addObject:[NSNumber numberWithUnsignedInt:0x0a]];
    [bytes addObject:[NSNumber numberWithUnsignedInt:0]];
    [bytes addObject:[[self splitWord:[self encodeWhite:color.white]] objectAtIndex:0]];
    [bytes addObject:[[self splitWord:[self encodeWhite:color.white]] objectAtIndex:1]];
    [bytes addObject:[[self splitWord:[self encodeRed:color.red]] objectAtIndex:0]];
    [bytes addObject:[[self splitWord:[self encodeRed:color.red]] objectAtIndex:1]];
    [bytes addObject:[[self splitWord:[self encodeGreen:color.green]] objectAtIndex:0]];
    [bytes addObject:[[self splitWord:[self encodeGreen:color.green]] objectAtIndex:1]];
    [bytes addObject:[[self splitWord:[self encodeBlue:color.blue]] objectAtIndex:0]];
    [bytes addObject:[[self splitWord:[self encodeBlue:color.blue]] objectAtIndex:1]];
    
    return bytes;
}

@end
