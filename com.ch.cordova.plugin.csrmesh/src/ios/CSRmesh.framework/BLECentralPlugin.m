//
//  BLECentralPlugin.m
//  BLE_Test3
//
//  Created by heyun on 16/12/22.
//
//

#import "BLECentralPlugin.h"
#import <Cordova/CDV.h>
#import <CSRmesh/MeshServiceApi.h>
#import <CSRmesh/LightModelApi.h>
#import <CSRmesh/PowerModelApi.h>
#import "BLECommandContext.h"


@interface BLECentralPlugin()
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)stopScanTimer:(NSTimer *)timer;
@property (nonatomic ,strong) NSNumber  *deviceId;
@property (nonatomic ,strong) NSNumber  *state;
@end

@implementation BLECentralPlugin

@synthesize manager;
@synthesize peripherals;
@synthesize discoveredBridges; ////

- (void)pluginInitialize {
    
    NSLog(@"Cordova BLE Central Plugin");
    NSLog(@"(c)2014-2015 Don Coleman");
    
    [super pluginInitialize];
    
    peripherals = [NSMutableSet set];
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    
    [[MeshServiceApi sharedInstance] setCentralManager:manager]; ////
    discoveredBridges = [NSMutableArray array]; /////
    self.deviceId = [NSNumber numberWithInteger:0x8001]; ///////////////
    self.state = [NSNumber numberWithInteger:1];  /////// 开关起始状态，设置为1
    
    connectCallbacks = [NSMutableDictionary new];
    connectCallbackLatches = [NSMutableDictionary new];
    readCallbacks = [NSMutableDictionary new];
    writeCallbacks = [NSMutableDictionary new];
    notificationCallbacks = [NSMutableDictionary new];
    stopNotificationCallbacks = [NSMutableDictionary new];
}

#pragma mark - Cordova Plugin Methods
// connect: function (device_id, success, failure){}
// 以设备的uuid作为唯一标识来确定连接的是哪一台设备
- (void)connect:(CDVInvokedUrlCommand *)command {
    
    NSLog(@"connect");
    NSString *uuid = [command.arguments objectAtIndex:0];
    
    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];
    
    if (peripheral) {
        NSLog(@"Connecting to peripheral with UUID : %@", uuid);
        
        [connectCallbacks setObject:[command.callbackId copy] forKey:[peripheral uuidAsString]]; // 把回调的uuid设为设备的uuid
        [manager connectPeripheral:peripheral options:nil];
        
    } else {
        NSString *error = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
        NSLog(@"%@", error);
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
}

// disconnect: function (device_id, success, failure) {
- (void)disconnect:(CDVInvokedUrlCommand*)command {
    NSLog(@"disconnect");
    
    NSString *uuid = [command.arguments objectAtIndex:0];
    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];
    
    [connectCallbacks removeObjectForKey:uuid];
    
    if (peripheral && peripheral.state != CBPeripheralStateDisconnected) {
        [manager cancelPeripheralConnection:peripheral];
    }
    
    // always return OK
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    //////根据callbackId回调的id返回原生代码？
}

// read: function (device_id, service_uuid, characteristic_uuid, success, failure) {
- (void)read:(CDVInvokedUrlCommand*)command {
    NSLog(@"read");
    
    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyRead];
    if (context) {
        
        CBPeripheral *peripheral = [context peripheral];
        CBCharacteristic *characteristic = [context characteristic];
        
        NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
        [readCallbacks setObject:[command.callbackId copy] forKey:key];
        
        [peripheral readValueForCharacteristic:characteristic];  // callback sends value
    }
    
}

// write: function (device_id, service_uuid, characteristic_uuid, value, success, failure) {
- (void)write:(CDVInvokedUrlCommand*)command {
    
    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyWrite];
    NSData *message = [command.arguments objectAtIndex:3]; // This is binary
    if (context) {
        
        if (message != nil) {
            
            CBPeripheral *peripheral = [context peripheral];
            CBCharacteristic *characteristic = [context characteristic];
            
            NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
            [writeCallbacks setObject:[command.callbackId copy] forKey:key];
            
            // TODO need to check the max length
            [peripheral writeValue:message forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            // response is sent from didWriteValueForCharacteristic
            
        } else {
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"message was null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
    
}

// writeWithoutResponse: function (device_id, service_uuid, characteristic_uuid, value, success, failure) {
- (void)writeWithoutResponse:(CDVInvokedUrlCommand*)command {
    NSLog(@"writeWithoutResponse");
    
    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyWriteWithoutResponse];
    NSData *message = [command.arguments objectAtIndex:3]; // This is binary
    
    if (context) {
        CDVPluginResult *pluginResult = nil;
        if (message != nil) {
            CBPeripheral *peripheral = [context peripheral];
            CBCharacteristic *characteristic = [context characteristic];
            
            // TODO need to check the max length
            [peripheral writeValue:message forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"message was null"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

// success callback is called on notification
// notify: function (device_id, service_uuid, characteristic_uuid, success, failure) {
- (void)startNotification:(CDVInvokedUrlCommand*)command {
    NSLog(@"registering for notification");
    
    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyNotify]; // TODO name this better
    
    if (context) {
        CBPeripheral *peripheral = [context peripheral];
        CBCharacteristic *characteristic = [context characteristic];
        
        NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
        NSString *callback = [command.callbackId copy];
        [notificationCallbacks setObject: callback forKey: key];
        
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
    }
    
}

// stopNotification: function (device_id, service_uuid, characteristic_uuid, success, failure) {
- (void)stopNotification:(CDVInvokedUrlCommand*)command {
    NSLog(@"registering for notification");
    
    BLECommandContext *context = [self getData:command prop:CBCharacteristicPropertyNotify]; // TODO name this better
    
    if (context) {
        CBPeripheral *peripheral = [context peripheral];
        CBCharacteristic *characteristic = [context characteristic];
        
        NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
        NSString *callback = [command.callbackId copy];
        [stopNotificationCallbacks setObject: callback forKey: key];
        
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        // callback sent from peripheral:didUpdateNotificationStateForCharacteristic:error:
        
    }
    
}

- (void)isEnabled:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult *pluginResult = nil;
    int bluetoothState = [manager state];
    
    BOOL enabled = bluetoothState == CBCentralManagerStatePoweredOn;
    
    if (enabled) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:bluetoothState];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


 // command参数数组,为ble.js中scan函数的参数:[services, seconds]
- (void)scan:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"scan");
    discoverPeripherialCallbackId = [command.callbackId copy];
    NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
    NSNumber *timeoutSeconds = [command.arguments objectAtIndex:1];
    NSMutableArray *serviceUUIDs = [NSMutableArray new];
    
    for (int i = 0; i < [serviceUUIDStrings count]; i++) {
        CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
        [serviceUUIDs addObject:serviceUUID];
    }
    
    [manager scanForPeripheralsWithServices:serviceUUIDs options:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:[timeoutSeconds floatValue]
                                     target:self
                                   selector:@selector(stopScanTimer:)
                                   userInfo:[command.callbackId copy]
                                    repeats:NO];
    
}

// command参数,为ble.js中startScan函数的参数:[services]
// 这个services是服务UUID ？才开始扫描，这个是哪里来的？
- (void)startScan:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"startScan");
    // 扫描时获取的外设的信息（ NSString型 ？）
    discoverPeripherialCallbackId = [command.callbackId copy];
    NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
    NSMutableArray *serviceUUIDs = [NSMutableArray new];
    
    for (int i = 0; i < [serviceUUIDStrings count]; i++) {
        CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
        [serviceUUIDs addObject:serviceUUID];
    }
    
    [manager scanForPeripheralsWithServices:serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}]; ////
    
}

- (void)stopScan:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"stopScan");
    
    [manager stopScan];
    
    if (discoverPeripherialCallbackId) {
        discoverPeripherialCallbackId = nil;
    }
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}


- (void)isConnected:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult *pluginResult = nil;
    CBPeripheral *peripheral = [self findPeripheralByUUID:[command.arguments objectAtIndex:0]];
    
    if (peripheral && peripheral.state == CBPeripheralStateConnected) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not connected"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - timers

-(void)stopScanTimer:(NSTimer *)timer {
    NSLog(@"stopScanTimer");
    
    [manager stopScan];
    
    if (discoverPeripherialCallbackId) {
        discoverPeripherialCallbackId = nil;
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if ([peripherals containsObject:peripheral]) { // 如果外设集合包含当前扫描到的外设的话，先移除。
        [peripherals removeObject:peripheral];
    }  ////////
    if ([peripheral.name isEqualToString:@"CSRmesh"]) {
        [peripherals addObject:peripheral];  //////////////原码
    } //////
    
    [peripheral setAdvertisementData:advertisementData RSSI:RSSI];
    NSLog(@"peripherals ===== %@ ",peripherals);
    NSMutableDictionary *enhancedAdvertisementData = [NSMutableDictionary dictionaryWithDictionary:advertisementData]; /////
    enhancedAdvertisementData[CSR_PERIPHERAL] = peripheral; ////
    NSNumber *messageStatus = [[MeshServiceApi sharedInstance] processMeshAdvert:enhancedAdvertisementData RSSI:RSSI]; /////
    if ([messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {
        [peripheral setIsBridgeService:@(YES)];}
    else{
        [peripheral setIsBridgeService:@(NO)];
    }  ////////
    if (![discoveredBridges containsObject:peripheral]) {
        [discoveredBridges addObject:peripheral];
    } //////
    
    if (discoverPeripherialCallbackId) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
        NSLog(@"Discovered %@", [peripheral asDictionary]);
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:discoverPeripherialCallbackId];
    }
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Status of CoreBluetooth central manager changed %ld %@", (long)central.state, [self centralManagerStateToString: central.state]);
    
    if (central.state == CBCentralManagerStateUnsupported)
    {
        NSLog(@"=============================================================");
        NSLog(@"WARNING: This hardware does not support Bluetooth Low Energy.");
        NSLog(@"=============================================================");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"didConnectPeripheral");
    
    peripheral.delegate = self;
    
    // NOTE: it's inefficient to discover all services
    [peripheral discoverServices:nil];
    
    // NOTE: not calling connect success until characteristics are discovered
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"didDisconnectPeripheral");
    
    if ([peripherals containsObject:peripheral]) {
        [peripherals removeObject:peripheral];
        [[MeshServiceApi sharedInstance] disconnectBridge:peripheral];
    } ////////////////////
    
    NSString *connectCallbackId = [connectCallbacks valueForKey:[peripheral uuidAsString]];
    [connectCallbacks removeObjectForKey:[peripheral uuidAsString]];
    
    if (connectCallbackId) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[peripheral asDictionary]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"didFailToConnectPeripheral");
    
    NSString *connectCallbackId = [connectCallbacks valueForKey:[peripheral uuidAsString]];
    [connectCallbacks removeObjectForKey:[peripheral uuidAsString]];
    
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[peripheral asDictionary]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];
    
}

#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    NSLog(@"didDiscoverServices");
    
    // save the services to tell when all characteristics have been discovered
    NSMutableSet *servicesForPeriperal = [NSMutableSet new];
    [servicesForPeriperal addObjectsFromArray:peripheral.services];
    [connectCallbackLatches setObject:servicesForPeriperal forKey:[peripheral uuidAsString]];
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service]; // discover all is slow
    }
}

#define MESH_MTL_CHAR_ADVERT        @"C4EDC000-9DAF-11E3-8004-00025B000B00"
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error == nil) {
        [[MeshServiceApi sharedInstance] connectBridge:peripheral enableBridgeNotification:@(CSR_SCAN_NOTIFICATION_LISTEN_MODE)];
    } /////////
    
    NSLog(@"didDiscoverCharacteristicsForService");
    
    NSString *peripheralUUIDString = [peripheral uuidAsString];
    NSString *connectCallbackId = [connectCallbacks valueForKey:peripheralUUIDString];
    NSMutableSet *latch = [connectCallbackLatches valueForKey:peripheralUUIDString];
    
    [latch removeObject:service];
    
    if ([latch count] == 0) {
        // Call success callback for connect
        if (connectCallbackId) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
            [pluginResult setKeepCallbackAsBool:TRUE];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:connectCallbackId];
        }
        [connectCallbackLatches removeObjectForKey:peripheralUUIDString];
    }
    
    NSLog(@"Found characteristics for service %@", service);
//    for (CBCharacteristic *characteristic in service.characteristics) {
//        NSLog(@"Characteristic %@", characteristic);
//    }  ///////////
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MESH_MTL_CHAR_ADVERT]]) {
            [self subscribeToMeshSimNotifyChar:peripheral :characteristic];
        }
    }
    [peripheral setIsBridgeService:@(YES)];
}  //////////
//============================================================================
// MeshSimulator Notification Charactersitic
-(void) subscribeToMeshSimNotifyChar :(CBPeripheral *) peripheral :(CBCharacteristic *) characteristic {
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
} /////////////


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateValueForCharacteristic");
///////////////////////
    NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];
    
    [advertisementData setObject:@(NO) forKey:CBAdvertisementDataIsConnectable];
    
    advertisementData [CBAdvertisementDataIsConnectable] = @(NO);
    [advertisementData setObject:characteristic.value forKey:CSR_NotifiedValueForCharacteristic];
    [advertisementData setObject:characteristic forKey:CSR_didUpdateValueForCharacteristic];
    [advertisementData setObject:peripheral forKey:CSR_PERIPHERAL];

    [[MeshServiceApi sharedInstance] processMeshAdvert:advertisementData RSSI:nil];
///////////////////////
    NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
    NSString *notifyCallbackId = [notificationCallbacks objectForKey:key];
    
    if (notifyCallbackId) {
        NSData *data = characteristic.value; // send RAW data to Javascript
        
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
        [pluginResult setKeepCallbackAsBool:TRUE]; // keep for notification
        [self.commandDelegate sendPluginResult:pluginResult callbackId:notifyCallbackId];
    }
    
    NSString *readCallbackId = [readCallbacks objectForKey:key];
    
    if(readCallbackId) {
        NSData *data = characteristic.value; // send RAW data to Javascript
        
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:readCallbackId];
        
        [readCallbacks removeObjectForKey:key];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
    NSString *notificationCallbackId = [notificationCallbacks objectForKey:key];
    NSString *stopNotificationCallbackId = [stopNotificationCallbacks objectForKey:key];
    
    CDVPluginResult *pluginResult = nil;
    
    // we always call the stopNotificationCallbackId if we have a callback
    // we only call the notificationCallbackId on errors and if there is no stopNotificationCallbackId
    
    if (stopNotificationCallbackId) {
        
        if (error) {
            NSLog(@"%@", error);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:stopNotificationCallbackId];
        [stopNotificationCallbacks removeObjectForKey:key];
        [notificationCallbacks removeObjectForKey:key];
        
    } else if (notificationCallbackId && error) {
        
        NSLog(@"%@", error);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:notificationCallbackId];
    }
    
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // This is the callback for write
    
    NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
    NSString *writeCallbackId = [writeCallbacks objectForKey:key];
    
    if (writeCallbackId) {
        CDVPluginResult *pluginResult = nil;
        if (error) {
            NSLog(@"%@", error);
            pluginResult = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_ERROR
                            messageAsString:[error localizedDescription]
                            ];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:writeCallbackId];
        [writeCallbacks removeObjectForKey:key];
    }
    
}

#pragma mark - internal implemetation

- (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid {
    
    CBPeripheral *peripheral = nil;
    
    for (CBPeripheral *p in peripherals) {
        
        NSString* other = p.identifier.UUIDString;
        
        if ([uuid isEqualToString:other]) {
            peripheral = p;
            break;
        }
    }
    return peripheral;
}

// RedBearLab
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }
    
    return nil; //Service not found on this peripheral
}

// Find a characteristic in service with a specific property
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service prop:(CBCharacteristicProperties)prop
{
    NSLog(@"Looking for %@ with properties %lu", UUID, (unsigned long)prop);
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ((c.properties & prop) != 0x0 && [c.UUID.UUIDString isEqualToString: UUID.UUIDString]) {
            return c;
        }
    }
    return nil; //Characteristic with prop not found on this service
}

// Find a characteristic in service by UUID
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    NSLog(@"Looking for %@", UUID);
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([c.UUID.UUIDString isEqualToString: UUID.UUIDString]) {
            return c;
        }
    }
    return nil; //Characteristic not found on this service
}

// RedBearLab
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    
    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

// expecting deviceUUID, serviceUUID, characteristicUUID in command.arguments
-(BLECommandContext*) getData:(CDVInvokedUrlCommand*)command prop:(CBCharacteristicProperties)prop {
    NSLog(@"getData");
    
    CDVPluginResult *pluginResult = nil;
    
    NSString *deviceUUIDString = [command.arguments objectAtIndex:0];
    NSString *serviceUUIDString = [command.arguments objectAtIndex:1];
    NSString *characteristicUUIDString = [command.arguments objectAtIndex:2];
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDString];
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:characteristicUUIDString];
    
    CBPeripheral *peripheral = [self findPeripheralByUUID:deviceUUIDString];
    
    if (!peripheral) {
        
        NSLog(@"Could not find peripherial with UUID %@", deviceUUIDString);
        
        NSString *errorMessage = [NSString stringWithFormat:@"Could not find peripherial with UUID %@", deviceUUIDString];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        return nil;
    }
    
    CBService *service = [self findServiceFromUUID:serviceUUID p:peripheral];
    
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              serviceUUIDString,
              peripheral.identifier.UUIDString);
        
        
        NSString *errorMessage = [NSString stringWithFormat:@"Could not find service with UUID %@ on peripheral with UUID %@",
                                  serviceUUIDString,
                                  peripheral.identifier.UUIDString];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        return nil;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service prop:prop];
    
    // Special handling for INDICATE. If charateristic with notify is not found, check for indicate.
    if (prop == CBCharacteristicPropertyNotify && !characteristic) {
        characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service prop:CBCharacteristicPropertyIndicate];
    }
    
    // As a last resort, try and find ANY characteristic with this UUID, even if it doesn't have the correct properties
    if (!characteristic) {
        characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    }
    
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              characteristicUUIDString,
              serviceUUIDString,
              peripheral.identifier.UUIDString);
        
        NSString *errorMessage = [NSString stringWithFormat:
                                  @"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
                                  characteristicUUIDString,
                                  serviceUUIDString,
                                  peripheral.identifier.UUIDString];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        return nil;
    }
    
    BLECommandContext *context = [[BLECommandContext alloc] init];
    [context setPeripheral:peripheral];
    [context setService:service];
    [context setCharacteristic:characteristic];
    return context;
    
}

-(NSString *) keyForPeripheral: (CBPeripheral *)peripheral andCharacteristic:(CBCharacteristic *)characteristic {
    return [NSString stringWithFormat:@"%@|%@", [peripheral uuidAsString], [characteristic UUID]];
}

#pragma mark - util

- (NSString*) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return @"State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return @"State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return @"State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return @"State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return @"State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return @"State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return @"State unknown";
    }
    
    return @"Unknown state";
}

// 关闭灯泡
- (void)close:(CDVInvokedUrlCommand*)command {
    
    for (int i = 0; i < self.discoveredBridges.count; i++) {
        if (self.state == [NSNumber numberWithInteger:1]) {  // 如果灯泡的状态是开,那么关闭
            
            NSNumber *powerSta = [NSNumber numberWithInteger:0];
            [self setPower:powerSta];
            
            self.state = [NSNumber numberWithInteger:0]; //灯泡关闭后，把状态值设置为0
              NSLog(@"设置关闭灯泡成功");
            return;
           
        }else{
            
            NSString *error = [NSString stringWithFormat:@"Could not turnOff  %@.", self.discoveredBridges[i]];
            NSLog(@"%@", error);
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }

    }
}

// 开启灯泡
- (void)open:(CDVInvokedUrlCommand*)command {
    
    for (int i = 0; i < self.discoveredBridges.count; i++) {
        if (self.state == [NSNumber numberWithInteger:0]) {
            
            NSNumber *powerSta = [NSNumber numberWithInteger:1];
            [self setPower:powerSta];
            
            self.state = [NSNumber numberWithInteger:1]; //灯泡开启后，把状态值设置为1
            NSLog(@"设置开启灯泡成功");
            NSString *hexcolor = @"#00FF00";
            UIColor *color = [self colorWithHexString:hexcolor];
            NSLog(@"color === %@",color); //UIDeviceRGBColorSpace 0 1 0 1
//            [self change2color:color];
            return;
            
        }else{
            
            NSString *error = [NSString stringWithFormat:@"Could not turnOn  %@.", self.discoveredBridges[i]];
            NSLog(@"%@", error);
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        
    }
}

- (void)setPower:(NSNumber *)state
{
    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
    [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];
    
    [[PowerModelApi sharedInstance] setPowerState:self.deviceId state:state acknowledged:YES];
    [manager stopScan];
}


// 设置灯泡颜色,需要传参［color］
- (void)changeColor:(CDVInvokedUrlCommand *)command
{
        CDVPluginResult *pluginResult = nil;
        
        NSString *colorString = [command.arguments objectAtIndex:0];
        NSLog(@"colorString ===== %@",colorString); // 十进制
        UIColor *color = [self getColorFromString:colorString];
        NSLog(@"color ======== %@",color);
        
        [self change2color:color];
        if (color != nil) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                
        }else{       
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"could not change color!"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


// 改变颜色
- (void)change2color:(UIColor *)desiredColor
{
    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
    [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];
    
    const CGFloat *componentColors = CGColorGetComponents(desiredColor.CGColor);
    CGFloat red = componentColors[0];
    CGFloat green = componentColors[1];
    CGFloat blue = componentColors[2];
    //CGFloat alpha = componentColors[3];
    
    
    uint8_t red8 = (uint8_t) (red * 255);
    uint8_t green8 = (uint8_t) (green * 255);
    uint8_t blue8 = (uint8_t) (blue * 255);
    uint8_t level8 = 255;
    
    NSNumber *redColor = [NSNumber numberWithUnsignedChar:red8];
    NSNumber *greenColor = [NSNumber numberWithUnsignedChar:green8];
    NSNumber *blueColor = [NSNumber numberWithUnsignedChar:blue8];
    NSNumber *levelValue = [NSNumber numberWithUnsignedChar:level8];
    NSNumber *duration = [NSNumber numberWithUnsignedShort:0];
    
    NSLog(@"desiredColor == %@,redColor == %@,greenColor == %@,blueColor == %@",desiredColor,redColor,greenColor,blueColor);
    
    [[LightModelApi sharedInstance] setRgb:self.deviceId red:redColor green:greenColor blue:blueColor level:levelValue duration:duration acknowledged:YES];
    
    [manager stopScan];  // 停止扫描
    
}

//从页面js传来的十六进制值变成了十进制的值，因此需要将十进制值转换为UIColor
// 通常这个方法用来放在UIColor的分类方法中，且封装为类方法（＋）
- (UIColor *)getColorFromString:(NSString *)color
{
    // 十进制转换为十六进制
    int colorInt = [color intValue]; //字符串转int
    if (colorInt < 0)
        return [UIColor whiteColor];
    
    NSString *nLetterValue;
    NSString *colorString16 = @"";
    int ttmpig;
    
    for (int i = 0; i < 9; i++)
    {
        ttmpig = colorInt % 16;
        colorInt = colorInt/16;
        
        switch (ttmpig) {
            case 10:
                nLetterValue = @"A";
                break;
                
            case 11:
                nLetterValue = @"B";
                break;

            case 12:
                nLetterValue = @"C";
                break;

            case 13:
                nLetterValue = @"D";
                break;
                
            case 14:
                nLetterValue = @"E";
                break;

            case 15:
                nLetterValue = @"F";
                break;
                
            default: nLetterValue = [[NSString alloc]initWithFormat:@"%i",ttmpig];
                break;
        }
        
        colorString16 = [nLetterValue stringByAppendingString:colorString16];
       
        if (colorInt == 0)
            break;
    }
      colorString16 = [[colorString16 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString]; // 去掉前后空格换行符

    //     string should be 6 or 8 characters
    if ([colorString16 length] < 6) {
        
        int cc = 6 - [colorString16 length];
        for (int i=0; i < cc; i++)
            colorString16 = [@"0" stringByAppendingString:colorString16];
        
    }  // 紫色，十进制是800080
//    
    colorString16 = [@"0x" stringByAppendingString:colorString16];
//    NSLog(@"十进制颜色值转换为十六进制颜色值,再加上0x前缀之后是 ========= %@",colorString16);
    // 这里加上0x前缀之后，在下面代码里又去除了前缀，多此一举。不添加前缀，直接往下range取RGB的值。
    // 不添加的话，长度不足6个字符的颜色值，就会被clearColor
    
    // strip 0x if it appears
    // 如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([colorString16 hasPrefix:@"0x"])
        colorString16 = [colorString16 substringFromIndex:2];
    
    // 如果是＃开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if([colorString16 hasPrefix:@"#"])
        colorString16 = [colorString16 substringFromIndex:1];
    
    if([colorString16 length] != 6)
        return [UIColor clearColor];
    

    NSLog(@"colorString16 ====== %@",colorString16);
//    if ([colorString16 length] != 6)
//        return [UIColor whiteColor];
    
    // seperate into r, g, b subStrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    // r
    NSString *rString = [colorString16 substringWithRange:range];
    
    // g
    range.location = 2;
    NSString *gString = [colorString16 substringWithRange:range];
    
    // b
    range.location = 4;
    NSString *bString = [colorString16 substringWithRange:range];
    
    // scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:0.5f];
    

}

// 十六进制颜色值转换为UIColor,这里没有用到
- (UIColor *)colorWithHexString:(NSString *)color
{
    // 删除字符串中的空格
        NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]uppercaseString];
    
    //     string should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0x if it appears
    // 如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    
    // 如果是＃开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    
    if([cString length] != 6)
        return [UIColor clearColor];
    
    // seperate into r, g, b subStrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    // r
    NSString *rString = [cString substringWithRange:range];
    
    // g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    // b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];

}
@end

