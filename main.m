//
//  main.m
//  avea-cli
//
//  Created by Glenn Forbes on 05/09/2016.
//  Copyright © 2016 Glenn Forbes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Avea.h"
#import "ColorDescriptor.h"
#import "Color.h"


static NSString *AveaDirectoryPath = @"~/.avea";
static NSString *ColorDescriptorFile = @"avea-colors.json";

//Not used for now. Becuase I'm lazy and only own 1 (broken) Avea bulb.
static NSString *PeripheralUUIDFile = @"avea-uuids.txt";

//ColorDescriptor *colorBlue;
//ColorDescriptor *colorGreen;
//ColorDescriptor *colorRed;
//ColorDescriptor *colorYellow;
//ColorDescriptor *colorOrange;
//ColorDescriptor *colorPurple;
//ColorDescriptor *colorPink;
//ColorDescriptor *colorWhite;
//ColorDescriptor *colorWhiteWarm;
//ColorDescriptor *colorWhiteCold;
//ColorDescriptor *colorWhiteRose;
//
//struct Color cBlue;

NSArray *arguments;

NSArray *defaultColors;

Avea *av;

NSArray* getColorDescriptorsFromFile()
{
    NSString *directoryPath = [AveaDirectoryPath stringByExpandingTildeInPath];
    NSString *filePath = [directoryPath stringByAppendingString:ColorDescriptorFile];
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data)
    {
        NSLog(@"[Error] Can't read colors from file! Make sure %@ exists and is valid JSON.", ColorDescriptorFile);
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSArray *results;
    
    if ([[json allKeys] containsObject:@"colors"])
    {
        results = json[@"colors"];
    }
    
    NSMutableArray *colorDescriptors = [[NSMutableArray alloc] init];
    
    for (NSDictionary *result in results)
    {
        NSString *title = result[@"title"];
        
        int red = [result[@"red"] intValue];
        int green = [result[@"green"] intValue];
        int blue = [result[@"blue"] intValue];
        int white = [result[@"white"] intValue];
        
        struct Color color;
        color.red = red;
        color.green = green;
        color.blue = blue;
        color.white = white;
        
        ColorDescriptor *colorD = [[ColorDescriptor alloc] init];
        
        colorD.title = title;
        colorD.color = color;
        
        [colorDescriptors addObject:colorD];
    }
    
    return colorDescriptors;
}

NSData* getJSONDataForColorDescriptors(NSArray *colorDescriptors)
{
    NSMutableArray *colorDicts = [[NSMutableArray alloc] init];
    
    for (ColorDescriptor *colorDescriptor in colorDescriptors)
    {
        NSMutableDictionary *colorDict = [[NSMutableDictionary alloc] init];
        
        colorDict[@"title"] = colorDescriptor.title;
        colorDict[@"red"] = [NSNumber numberWithInt:colorDescriptor.color.red];
        colorDict[@"green"] = [NSNumber numberWithInt:colorDescriptor.color.green];
        colorDict[@"blue"] = [NSNumber numberWithInt:colorDescriptor.color.blue];
        colorDict[@"white"] = [NSNumber numberWithInt:colorDescriptor.color.white];
        
        [colorDicts addObject:colorDict];
    }
    
    NSDictionary *colorsJSON = [[NSMutableDictionary alloc] init];
    [colorsJSON setValue:colorDicts forKey:@"colors"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:colorsJSON options:NSJSONWritingPrettyPrinted error:nil];
    
    return data;
    
}

BOOL setupAveaDirectory()
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directoryPath = [AveaDirectoryPath stringByExpandingTildeInPath];
    
    BOOL isDirectory = false;
    
    if ([fileManager fileExistsAtPath:AveaDirectoryPath isDirectory:&isDirectory])
    {
        if (isDirectory)
        {
            return true;
        }
        else
        {
            NSLog(@"[Error] File exists at specified Avea directory location '%@'. Remove file or change directory path in script.", directoryPath);
            exit(1);
        }
    }
    else
    {
       if ([fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:true attributes:nil error:nil])
       {
           NSLog(@"[main] Created Avea directory at path '%@'.", directoryPath);
           return true;
       }
       else
       {
           NSLog(@"[main] Error creating Avea directory.");
       }
    }
    
    return false;
}

BOOL setUpColorFile()
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directoryPath = [AveaDirectoryPath stringByExpandingTildeInPath];
    NSString *colorFilePath = [directoryPath stringByAppendingString:ColorDescriptorFile];
    
    if ([fileManager fileExistsAtPath:colorFilePath])
    {
        return !(getColorDescriptorsFromFile() == nil);
    }
    else
    {
        if ([fileManager createFileAtPath:colorFilePath contents:getJSONDataForColorDescriptors(defaultColors) attributes:nil])
        {
            NSLog(@"[main] Created color file '%@'.", colorFilePath);
            return true;
        }
        else
        {
            NSLog(@"Couldn't create Avea color file at path '%@'.", colorFilePath);
            exit(1);
        }
    }
}

//******************* TO BE PORTED ************************

//// Returns true if periheral id file exists/has been created
//func setUpPeripheralUUIDFile() -> Bool {
//    let fileManager = NSFileManager.defaultManager()
//    let directoryPath = NSString(string: Constants.AveaDirectoryPath).stringByExpandingTildeInPath
//    let idFilePath = directoryPath.stringByAppendingString("/\(Constants.PeripheralUUIDFile)")
//    
//    if fileManager.fileExistsAtPath(idFilePath) {
//        return true
//    } else { // file doesn't exist, create file
//        if fileManager.createFileAtPath(idFilePath, contents: nil, attributes: nil) {
//            print("[main] Created peripheral ID file \'\(idFilePath)\'")
//            return true
//        } else {
//            print("Couldn't create peripheral ID file at path \'\(idFilePath)\'")
//            exit(1)
//        }
//    }
//    }
//    
//    
//    func setupAveaFiles() -> Bool {
//        return setUpColorFile() && setUpPeripheralUUIDFile()
//    }
//    
//    
//    func getUUIDSFromFile() -> [String]? {
//        let directoryPath = NSString(string: Constants.AveaDirectoryPath).stringByExpandingTildeInPath
//        let idFilePath = directoryPath.stringByAppendingString("/\(Constants.PeripheralUUIDFile)")
//        
//        guard let data = NSData(contentsOfFile: idFilePath) else {
//            print("[Error] Can't read peripheral ids from id file! Make sure \"\(idFilePath)\" exists")
//            return nil
//        }
//        
//        guard let dataString = String(data: data, encoding: NSUTF8StringEncoding) else {
//            print("[Error] Can't parse periherpal id file data to String!")
//            return nil
//        }
//        let components = dataString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
//        var uuids = [String]()
//        
//        for component in components where component.characters.count > 0 {
//            uuids.append(component)
//        }
//        
//        return uuids
//    }
//    
//    func writeUUIDsToFile(uuids: [String]) {
//        let directoryPath = NSString(string: Constants.AveaDirectoryPath).stringByExpandingTildeInPath
//        let idFilePath = directoryPath.stringByAppendingString("/\(Constants.PeripheralUUIDFile)")
//        
//        guard let fileHandle = NSFileHandle(forUpdatingAtPath: idFilePath) else {
//            print("[Error] Can't write to peripheral uuid file, exiting")
//            exit(1)
//        }
//        
//        var writeString = ""
//        for (index,uuid) in uuids.enumerate() {
//            if index != 0 {
//                writeString.appendContentsOf("\n")
//            }
//            
//            writeString.appendContentsOf(uuid)
//        }
//        
//        guard let data = writeString.dataUsingEncoding(NSUTF8StringEncoding) else {
//            print("[ERROR] Can't get data from peripheral id string, exiting!")
//            exit(1)
//        }
//        
//        fileHandle.truncateFileAtOffset(0) //Delete current file contents
//        fileHandle.writeData(data)
//    }
//    
//    func addNewPeripheralUUIDToFile(uuid: String) {
//        var ids = [uuid]
//        
//        if let existingIDs = getUUIDSFromFile() {
//            ids.appendContentsOf(existingIDs)
//        }
//        
//        print("[main] Stored new peripheral UUID \'\(uuid)\'")
//        writeUUIDsToFile(ids)
//    }

BOOL setupAveaFiles()
{
    //return setUpColorFile() && setUpPeripheralUUIDFile();
    
    return setUpColorFile();
}

void setColorUsingRGBW()
{
    if (arguments.count < 6)
    {
        NSLog(@"[Error] Wrong number of arguments! Needs [red] [green] [blue] [white].");
        exit(1);
    }
    
    int red = [arguments[2] intValue];
    int green = [arguments[3] intValue];
    int blue = [arguments[4] intValue];
    int white = [arguments[5] intValue];
    
    NSLog(@"[setColor] Red: %d, Green: %d, Blue: %d, White: %d", red, green, blue, white);
    
    struct Color newColor;
    newColor.red = red;
    newColor.green = green;
    newColor.blue = blue;
    newColor.white = white;
    
    [av setColor:newColor peripheralUUIDs:nil newPeripheralHandler:nil];
}

void setColorUsingDescriptor()
{
    if (arguments.count < 3)
    {
        NSLog(@"[Error] Wrong number of arguments! See help for usage details.");
        exit(1);
    }
    
    NSString *input = arguments[2];
    
    NSArray *colorDescriptors = getColorDescriptorsFromFile();
    if (!colorDescriptors)
    {
        NSLog(@"Colors not loaded. Exiting.");
        exit(1);
    }
    
    for (ColorDescriptor *colorDescriptor in colorDescriptors)
    {
        if ([colorDescriptor.title isEqualToString:input])
        {
            NSLog(@"[setColor] %@ - Red: %d, Green: %d, Blue: %d, White: %d.", input, colorDescriptor.color.red, colorDescriptor.color.green, colorDescriptor.color.blue, colorDescriptor.color.white);
            
            [av setColor:colorDescriptor.color peripheralUUIDs:nil newPeripheralHandler:nil];
            return;
        }
    }
    
    NSLog(@"[Error] Color Descriptor not recognized! Show available colors using 'avea show-colors'.");
}

void setBrightness()
{
    if (arguments.count < 3)
    {
        NSLog(@"[Error] Wrong number of arguments! See help for usage details.");
        exit(1);
    }
    
    int brightness = [arguments[2] intValue];
    
    if (brightness > 255)
    {
        NSLog(@"[Error] Brightness value '%d; is not an Int or out of range (0-255).", brightness);
    }
    
    [av setBrightness:brightness peripheralUUIDs:nil newPeripheralHandler:nil];
}

void turnOff()
{
    NSLog(@"[main] Turning off Avea.");
    
    struct Color off;
    
    off.red = 0;
    off.green = 0;
    off.blue = 0;
    off.white = 0;
    
    [av setColor:off peripheralUUIDs:nil newPeripheralHandler:nil];
}

void showColorDescriptors()
{
    NSArray *colorDescriptors = getColorDescriptorsFromFile();
    
    if (colorDescriptors.count < 1)
    {
        NSLog(@"Colors not loaded, exiting.");
        exit(1);
    }
    
    NSLog(@"Available colors: ");
    for (ColorDescriptor *colorDescriptor in colorDescriptors)
    {
        NSLog(@"[%@] Red: %d, Green: %d, Blue: %d, White: %d.", colorDescriptor.title, colorDescriptor.color.red, colorDescriptor.color.green, colorDescriptor.color.blue, colorDescriptor.color.white);
    }
}

//Not added right now because I'm tired as hell.

void addColor()
{
    
}

void deleteColor()
{
    
}

void printHelp()
{
    
}

void startMenu()
{
    
    if ([arguments[1] isEqualToString:@"rgbw"] || [arguments[1] isEqualToString:@"set-color-rgbw"])
    {
        setColorUsingRGBW();
    }
    else if ([arguments[1] isEqualToString:@"c"] || [arguments[1] isEqualToString:@"set-color"])
    {
        setColorUsingDescriptor();
    }
    else if ([arguments[1] isEqualToString:@"b"] || [arguments[1] isEqualToString:@"set-brightness"])
    {
        setBrightness();
    }
    else if ([arguments[1] isEqualToString:@"off"])
    {
        turnOff();
    }
    else if ([arguments[1] isEqualToString:@"show-colors"])
    {
        showColorDescriptors();
    }
    else if ([arguments[1] isEqualToString:@"add-color"])
    {
        addColor();
    }
    else if ([arguments[1] isEqualToString:@"delete-color"])
    {
        deleteColor();
    }
    else if ([arguments[1] isEqualToString:@"help"])
    {
        printHelp();
    }
    else
    {
        NSLog(@"Argument not recognized. Use Avea Help for more information.");
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        arguments = [[NSProcessInfo processInfo] arguments];
        
        av = [[Avea alloc] init];
        
        startMenu();
    }
    return 0;
}


