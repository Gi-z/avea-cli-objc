//
//  Avea.h
//  avea-cli
//
//  Created by Glenn Forbes on 06/09/2016.
//  Copyright © 2016 Glenn Forbes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothManager.h"
#import "Color.h"

@interface Avea : NSObject

- (void)setColor:(struct Color)color peripheralUUIDs:(NSArray *)uuids newPeripheralHandler:(NSString *)handler;
- (void)setBrightness:(int)brightness peripheralUUIDs:(NSArray *)uuids newPeripheralHandler:(NSString *)handler;
@end
