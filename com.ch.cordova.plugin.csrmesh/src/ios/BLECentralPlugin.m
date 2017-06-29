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
#import <CSRmesh/GroupModelApi.h>
#import <CSRmesh/ConfigModelApi.h>
#import "BLECommandContext.h"


@interface BLECentralPlugin()<MeshServiceApiDelegate, GroupModelApiDelegate, PowerModelApiDelegate, LightModelApiDelegate>{
    BOOL isAssociated;
    BOOL isAssociating;
    BOOL isPendingAssociation; // 待associate
    NSData *authCode;
    NSNumber *associationStepsCompleted;
    NSNumber *associationStepsTotal;
    NSNumber *failedToAssociate;
}
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)stopScanTimer:(NSTimer *)timer;
@property (nonatomic ,strong) NSNumber  *deviceId;
@property (nonatomic ,strong) NSNumber  *state;
@property (nonatomic ,strong) NSMutableArray  *connectedPeripherals;
@property (nonatomic ,strong) NSMutableArray  *Auuids;
@property (nonatomic ,strong) NSMutableArray *unAssociatedUUIDArray; // 保存unAssociated的设备的UUID数组
@property (nonatomic ,strong) CBUUID  *uuid;
@property (nonatomic ,strong) NSData  *deviceHash; // 2017.4.28

@end

@implementation BLECentralPlugin

@synthesize manager;
@synthesize connectedPeripherals;
@synthesize discoveredBridges; ////
@synthesize peripherals;

- (void)pluginInitialize {
    
    NSLog(@"Cordova BLE Central Plugin");
    NSLog(@"(c)2014-2015 Don Coleman");
    
    [super pluginInitialize];
    
   connectedPeripherals = [NSMutableArray array];
    
    dispatch_queue_t centralQueue = dispatch_queue_create("com.dispatch.mycentral", DISPATCH_QUEUE_SERIAL);
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
    
    
    [[MeshServiceApi sharedInstance] setCentralManager:manager]; ////
    [[MeshServiceApi sharedInstance] setMeshServiceApiDelegate:self];///////设置代理
    [[GroupModelApi sharedInstance] setGroupModelApiDelegate:self];
    [[LightModelApi sharedInstance] setLightModelApiDelegate:self];
    [[PowerModelApi sharedInstance] setPowerModelApiDelegate:self];
    
    discoveredBridges = [NSMutableArray array]; /////
    peripherals = [NSMutableSet set];

    self.state = [NSNumber numberWithInteger:1];  /////// 开关起始状态，设置为1

    self.Auuids = [NSMutableArray array];  /////////////////////
    
    self.unAssociatedUUIDArray = [NSMutableArray array]; // 2017.5.12
    
    isAssociated = NO;
    isAssociating = NO;
    isPendingAssociation = NO;
    self.uuid = nil;
    
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
        NSLog(@"Connecting to peripheral %@ with UUID : %@", peripheral, uuid); //49B11E9A-6EF3-B576-D06B-74730678B8A8

        NSLog(@"connect.command.callbackId====%@",command.callbackId);  /////////////////////BLE1720026664,根据callbackId及是否成功标标识，找到回调方法，并把处理结果传给回调方法;第二个灯163908246,716109712[
        [connectCallbacks setObject:[command.callbackId copy] forKey:[peripheral uuidAsString]]; // 把回调的uuid设为设备的uuid
        ///////////////
        for (CBPeripheral *connectedPeripheral in self.connectedPeripherals) {
            if (connectedPeripheral && connectedPeripheral.state != CBPeripheralStateConnected)
                [manager cancelPeripheralConnection:peripheral];
        }
        [self.connectedPeripherals removeAllObjects];
        
        if ([peripheral state]!= CBPeripheralStateConnected) {
            [manager connectPeripheral:peripheral options:nil];
        }

        // 测试工程BLE_Test9_3中未调试password.w页面，这里直接设置密码
        [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];
        [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES]; // 2017.5.3注释
        
        
        
        /////////////////
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

// command参数,startScan函数无参数
- (void)startScan:(CDVInvokedUrlCommand*)command {

    NSLog(@"startScan");

    discoverPeripherialCallbackId = [command.callbackId copy];
    
 //   NSArray *serviceUUIDStrings = [command.arguments objectAtIndex:0];
 //   NSLog(@"serviceUUIDStrings ====%@",serviceUUIDStrings);  ////////////输出为空。这是界面端传来的参数，因此，有此参数的目的是，可以在页面端指定service，扫描时扫描指定的外设。若不指定nil，则扫描所有外设。但是扫描的时候界面端显示了服务号，rssi，identifier等值的？
 //   NSMutableArray *serviceUUIDs = [NSMutableArray new];
    
 //   for (int i = 0; i < [serviceUUIDStrings count]; i++) {
 //       CBUUID *serviceUUID =[CBUUID UUIDWithString:[serviceUUIDStrings objectAtIndex: i]];
 //       [serviceUUIDs addObject:serviceUUID];
 //  }

 //   [manager scanForPeripheralsWithServices:serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}]; ////
	 [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}];// 2017.5.20 删除services参数
    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES]; // 2017.5.3 加   // 2017.5.13注释
    
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

/****************************************************************************/
/*								Callbacks                                   */
/****************************************************************************/

//============================================================================

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    

//    if ([peripheral.name isEqualToString:@"CSRmesh"]) {
//        [peripherals addObject:peripheral];
//    
//    
//    NSMutableDictionary *enhancedAdvertisementData = [NSMutableDictionary dictionaryWithDictionary:advertisementData]; /////
//    enhancedAdvertisementData[CSR_PERIPHERAL] = peripheral; ////
//    NSNumber *messageStatus = [[MeshServiceApi sharedInstance] processMeshAdvert:enhancedAdvertisementData RSSI:RSSI]; /////
//
//    [peripheral setAdvertisementData:advertisementData RSSI:RSSI];
//    NSLog(@"[messageStatus integerValue] ==== %u ，peripheral:%@",[messageStatus integerValue],peripheral);
//    
//    if ([messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {
//        [peripheral setIsBridgeService:@(YES)];}
//    else{
//        [peripheral setIsBridgeService:@(NO)];
//        }  ////////
//        
//    if ([messageStatus integerValue] == IS_BRIDGE || [messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {    ////////
//            if (![discoveredBridges containsObject:peripheral]) {
//                [discoveredBridges addObject:peripheral];
//            }
//        }//////
//    NSLog(@"discoverPeripherialCallbackId === %@", discoverPeripherialCallbackId);
//    if (discoverPeripherialCallbackId && [peripheral.name isEqualToString:@"CSRmesh"]) {
//        CDVPluginResult *pluginResult = nil;
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
//        NSLog(@"Discovered %@", [peripheral asDictionary]);
//        [pluginResult setKeepCallbackAsBool:TRUE];
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:discoverPeripherialCallbackId];
//        }
//}

    if ([peripheral.name isEqualToString:@"CSRmesh"]) {
        [peripherals addObject:peripheral];  //////////////原码
    } //////
//    for (CBPeripheral *peripheral in peripherals) { /////////////////////////////
    
        
        NSLog(@"peripherals ===== %@ ",peripherals);
        NSMutableDictionary *enhancedAdvertisementData = [NSMutableDictionary dictionaryWithDictionary:advertisementData]; /////
        enhancedAdvertisementData[CSR_PERIPHERAL] = peripheral; ////
        NSNumber *messageStatus = [[MeshServiceApi sharedInstance] processMeshAdvert:enhancedAdvertisementData RSSI:RSSI]; /////
        
         [peripheral setAdvertisementData:advertisementData RSSI:RSSI];
         NSLog(@"[messageStatus integerValue] ==== %lu",[messageStatus integerValue]);
        
        if ([messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {
            [peripheral setIsBridgeService:@(YES)];}
        else{
            [peripheral setIsBridgeService:@(NO)];
        }  ////////
        if ([messageStatus integerValue] == IS_BRIDGE || [messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE){    ////////
                if (![discoveredBridges containsObject:peripheral]) {
                    [discoveredBridges addObject:peripheral];
                }
            }//////
        
        if (discoverPeripherialCallbackId) {
            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[peripheral asDictionary]];
            NSLog(@"Discovered %@", [peripheral asDictionary]);
            [pluginResult setKeepCallbackAsBool:TRUE];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:discoverPeripherialCallbackId];
        }
        
//    }

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
    [self.connectedPeripherals addObject:peripheral];
/*
    if (![discoveredBridges containsObject:peripheral] && peripheral.state == CBPeripheralStateConnected) {
        [discoveredBridges addObject:peripheral];
    } //////与外设成功连接后，判断discoveredBridges是否包含这个外设，如果不包含的话，那么把外设加入到discoveredBridges数组中
 */
    // NOTE: it's inefficient to discover all services
    [peripheral discoverServices:nil];
    
    // NOTE: not calling connect success until characteristics are discovered
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"didDisconnectPeripheral");
    
    if ([self.connectedPeripherals containsObject:peripheral]) {
        [self.connectedPeripherals removeObject:peripheral];
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
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MESH_MTL_CHAR_ADVERT]]) {
            [self subscribeToMeshSimNotifyChar:peripheral :characteristic];
        }
    }
    
    [peripheral setIsBridgeService:@(YES)];
    /////////
    
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
    
//    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES]; // 2017.5.3 加
    NSLog(@"Found characteristics for service %@", service);

//    for (CBCharacteristic *characteristic in service.characteristics) {
//        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MESH_MTL_CHAR_ADVERT]]) {
//            [self subscribeToMeshSimNotifyChar:peripheral :characteristic];
//        }
//    }
//    [peripheral setIsBridgeService:@(YES)];
}  //////////
//============================================================================
// MeshSimulator Notification Charactersitic
-(void) subscribeToMeshSimNotifyChar :(CBPeripheral *) peripheral :(CBCharacteristic *) characteristic {
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
} /////////////


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
///////////////////////
    NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];
    
    [advertisementData setObject:@(NO) forKey:CBAdvertisementDataIsConnectable];
    
    advertisementData [CBAdvertisementDataIsConnectable] = @(NO);
    [advertisementData setObject:characteristic.value forKey:CSR_NotifiedValueForCharacteristic];
    [advertisementData setObject:characteristic forKey:CSR_didUpdateValueForCharacteristic];
    [advertisementData setObject:peripheral forKey:CSR_PERIPHERAL];

    [[MeshServiceApi sharedInstance] processMeshAdvert:advertisementData RSSI:nil];
///////////////////////
//    NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
//    NSString *notifyCallbackId = [notificationCallbacks objectForKey:key];
//    
//    if (notifyCallbackId) {
//        NSData *data = characteristic.value; // send RAW data to Javascript
//        
//        CDVPluginResult *pluginResult = nil;
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
//        [pluginResult setKeepCallbackAsBool:TRUE]; // keep for notification
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:notifyCallbackId];
//    }
//    
//    NSString *readCallbackId = [readCallbacks objectForKey:key];
//    
//    if(readCallbackId) {
//        NSData *data = characteristic.value; // send RAW data to Javascript
//        
//        CDVPluginResult *pluginResult = nil;
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:readCallbackId];
//        
//        [readCallbacks removeObjectForKey:key];
//    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error)
        NSLog (@"Can't subscribe for notification to %@", characteristic.UUID);
    else
        NSLog (@"Did subscribe for notification to %@", characteristic.UUID);
    
//        [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];  // 2017.4.28 加
    
    
    
//    NSString *key = [self keyForPeripheral: peripheral andCharacteristic:characteristic];
//    NSString *notificationCallbackId = [notificationCallbacks objectForKey:key];
//    NSString *stopNotificationCallbackId = [stopNotificationCallbacks objectForKey:key];
//    
//    CDVPluginResult *pluginResult = nil;
//    
//    // we always call the stopNotificationCallbackId if we have a callback
//    // we only call the notificationCallbackId on errors and if there is no stopNotificationCallbackId
//    
//    if (stopNotificationCallbackId) {
//        
//        if (error) {
//            NSLog (@"Can't subscribe for notification to %@", characteristic.UUID);
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
//        } else {
//            NSLog (@"Did subscribe for notification to %@", characteristic.UUID);
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
//        }
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:stopNotificationCallbackId];
//        [stopNotificationCallbacks removeObjectForKey:key];
//        [notificationCallbacks removeObjectForKey:key];
//        
//    } else if (notificationCallbackId && error) {
//        
//        NSLog(@"%@", error);
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:notificationCallbackId];
//    }

}

/*
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
    
}*/

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

#pragma mark - pending_Associate
- (void)didDiscoverDevice:(CBUUID *)uuid rssi:(NSNumber *)rssi
{
    NSLog(@"====================================================");
    NSLog(@"============== didDiscoverDevice ==================");
    NSLog(@"====================================================");
//    [manager stopScan];
//    
//    // inhibit or allow discovery of new CSRmehs un-associated devices.
//    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
//
    self.deviceHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:uuid]; // 2017.4.28
    
//    [[MeshServiceApi sharedInstance] associateDevice:deviceHash authorisationCode:nil];
//
    NSLog(@"didDiscoverDevice  self.uuid === %@", uuid);

    
    if (self.uuid != uuid){
        self.uuid = uuid;
    }
    
    if (![self.Auuids containsObject:uuid]) {
        [self.Auuids addObject:uuid];
    }
//    [[MeshServiceApi sharedInstance] setDeviceDiscoveryFilterEnabled:YES];
//    NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.uuid];
//    
//    [[MeshServiceApi sharedInstance] associateDevice:deviceHash authorisationCode:nil];
    
    // 2017.5.12
    if(![self.unAssociatedUUIDArray containsObject:uuid]){
        [self.unAssociatedUUIDArray addObject:uuid];
    }
    NSLog(@"self.unAssociatedUUIDArray ==== %@",self.unAssociatedUUIDArray);
    
    CDVPluginResult *pluginResult = nil;
//  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.unAssociatedUUIDArray];2017.5.16
    NSString *uuidString = [NSString stringWithFormat:@"%@",uuid];
    [pluginResult setKeepCallbackAsBool:TRUE];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:uuidString];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:getUnAssociatedDevicesCallBackId];


}

- (void)didUpdateAppearance:(NSData *)deviceHash appearanceValue:(NSData *)appearanceValue shortName:(NSData *)shortName
{
    NSLog(@"didUpdateAppearance deviceHash ================== %@,shortName: %@",deviceHash, shortName);
    self.deviceHash = deviceHash;  // 2017.4.28
}

- (void)isAssociatingDevice:(NSData *)deviceHash stepsCompleted:(NSNumber *)stepsCompleted totalSteps:(NSNumber *)totalSteps meshRequestId:(NSNumber *)meshRequestId
{
    NSLog(@"isAssociatingDevice deviceHash ================== %@",deviceHash);
    NSLog(@"stepsCompleted: %@, totalSteps: %@", stepsCompleted, totalSteps);
}

// call back
- (void)didAssociateDevice:(NSNumber *)deviceId deviceHash:(NSData *)deviceHash meshRequestId:(NSNumber *)meshRequestId
{
    NSLog(@" ====didAssociateDevice====  deviceId:%@,deviceHash:%@",deviceId, deviceHash);
    
    [[PowerModelApi sharedInstance] setPowerState:deviceId state:@(1) acknowledged:YES]; //associate成功后灯泡会灭，这里设置开启灯泡
    
    if (deviceIdCallBackId) {
        CDVPluginResult *pluginResult = nil;
        
//        NSMutableArray *deviceIdArray = [NSMutableArray array];
//        if (![deviceIdArray containsObject:deviceId]) {
//            [deviceIdArray addObject:deviceId];
//        }
//        
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:deviceIdArray];
//         NSLog(@"deviceIdCallBack  ==== deviceIdArray : %@", deviceIdArray);
//        if([deviceId isEqual:@(32769)]){
//            NSNumber *nextDeviceId = [NSNumber numberWithInteger:[deviceId integerValue]+1];
//            NSLog(@"next deviceId:%@",nextDeviceId);
//            [[MeshServiceApi sharedInstance] setNextDeviceId:nextDeviceId];
//        }
        NSString *deviceIdStr = [NSString stringWithFormat:@"%@",deviceId];  // 把associate成功获取到的number转化为string
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:deviceIdStr];
        
       NSLog(@"deviceIdCallBack  ==== deviceIdString : %@", deviceIdStr);
        //        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:deviceIdCallBackId];
    }
    
    [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
    
}

/****************************************************************************/
/*					    	Callback Function                               */
/****************************************************************************/

 //associate device,两个参数[设备的uuid, 关联的uuid]
- (void)associate:(CDVInvokedUrlCommand *)command
{
    deviceIdCallBackId = [command.callbackId copy];
    
//    NSString *Iuuid = [command.arguments objectAtIndex:0]; // 2017.5.16 注释
//    CBPeripheral *perip = [self findPeripheralByUUID:Iuuid];// 2017.5.16 注释
//    NSLog(@"需要associate 的设备是 :%@",perip);
    
    NSLog(@"associate - self.uuid ==> %@",self.uuid);  // <28482148>
//     [manager stopScan];  // 停止扫描
//    for (int i = 0;i<self.Auuids.count; i++) {
        // inhibit or allow discovery of new CSRmehs un-associated devices.
//        [[MeshServiceApi sharedInstance] setDeviceDiscoveryFilterEnabled:YES]; // 2017.4.28删
//    if(self.uuid != nil){ // 2017.5.3 加，防止uuid为空时,页面触发associate事件app闪退
    
//        NSData *deviceHash1 = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.uuid]; // 2017.4.28
//        NSData *deviceHash1 = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.uuid]; //2017.5.16注释
    
    NSString *UUIDString = [command.arguments objectAtIndex:0]; // 2017.5.16，传入参数修改为associate需要的deviceUUID
    CBUUID *device_UUID = [CBUUID UUIDWithString:UUIDString];
    
    NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:device_UUID];// 转化为deviceHash
    
    [[MeshServiceApi sharedInstance] associateDevice:deviceHash authorisationCode:nil];

    
    NSLog(@"deviceHash :%@",deviceHash);
    NSLog(@"deviceHash - self.uuid :%@",[[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.uuid]);
        //        NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.Auuids[i]];
              //    }
//    }

}

//- (void)getDevId:(CDVInvokedUrlCommand *)command
//{
//    deviceIdCallBackId = [command.callbackId copy];
//    NSString *Iuuid = [command.arguments objectAtIndex:0];
//    CBPeripheral *perip = [self findPeripheralByUUID:Iuuid];
//    NSLog(@"需要associate 的设备是 :%@, self.uuid :%@",perip,self.uuid);
//    
//    
//    // inhibit or allow discovery of new CSRmehs un-associated devices.
//    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
//    
//    NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:self.uuid];
//    [[MeshServiceApi sharedInstance] associateDevice:deviceHash authorisationCode:nil];
//}


// 获取待associate的设备的deviceUUID,返回结果是一个数组,回调结果在didDiscoverDevice方法中给出
- (void)getAssociableDevice:(CDVInvokedUrlCommand *)command
{
    getUnAssociatedDevicesCallBackId  = [command.callbackId copy];
    
    
}

// 设置进入mesh网络的密码，参数[password]
-(void)setPassword:(CDVInvokedUrlCommand *)command{
    NSString *password = [command.arguments objectAtIndex:0];
    
    [[MeshServiceApi sharedInstance]setNetworkPassPhrase:password];
    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(NSString *) getAssociationStatus {
    if (isAssociated)
        return (@"Associated");
    else if (isAssociating) {
        NSString *str;
        int stepsCompleted = [associationStepsCompleted intValue];
        int totalSteps     = [associationStepsTotal intValue]                                                               ;
        
        failedToAssociate = @(NO);
        if (stepsCompleted == 0)
            str = [NSString stringWithFormat:@"Pending"];
        else if (stepsCompleted > totalSteps) {
            str = [NSString stringWithFormat:@"Failed"];
            failedToAssociate = @(YES);
        }
        else {
            str = [NSString stringWithFormat:@"Associating %@/%@",associationStepsCompleted,associationStepsTotal];
        }
        return (str);
    }
    else if (isPendingAssociation)
        return (@"Pending");
    
    else
        return (@" ");
}

-(void) updateAssociationStatus :(NSNumber *) stepsCompleted :(NSNumber *) totalSteps {
    associationStepsCompleted = stepsCompleted;
    associationStepsTotal = totalSteps;
    isAssociating = YES;
    isPendingAssociation = NO;
}


-(BOOL) isAssociated {
    return (isAssociated);
}

-(BOOL) isAssociating {
    return (isAssociating);
}

-(BOOL) isPendingAssociation {
    return (isPendingAssociation);
}

-(BOOL) startAssociation:(NSData *)deviceHash {
    if (isAssociated)
        return (NO);
    else {
        [[MeshServiceApi sharedInstance] associateDevice:deviceHash authorisationCode:authCode];
        isAssociating = YES;
        associationStepsCompleted = [NSNumber numberWithInteger:0];
        associationStepsTotal = [NSNumber numberWithInteger:7];
    }
    return (YES);
}

-(void) didAssociateDevice :(NSNumber *) deviceIdNumber {
    isAssociated = YES;
    isAssociating = NO;
    isPendingAssociation = NO;
    self.deviceId = deviceIdNumber;
}

// 设置下一个设备的deviceId,一个参数,下一个设备的deviceId:[nextDeviceId]
- (void)setNextDeviceId:(CDVInvokedUrlCommand *)command{
//    NSInteger currentDeviceId = [[command.arguments objectAtIndex:0] integerValue];  // 字符串的整形值
//    NSNumber *nextDeviceId = [NSNumber numberWithUnsignedInteger:currentDeviceId + 1]; // 当前的deviceId + 1
//    NSString *nextDeviceIdStr = [NSString stringWithFormat:@"%@",nextDeviceId];
    NSInteger nextDevId = [[command.arguments objectAtIndex:0] integerValue]; // 2017.5.23 ，传入参数修改为下一个设备的deviceId
    NSNumber *nextDeviceId = [NSNumber numberWithUnsignedInteger:nextDevId];
    [[MeshServiceApi sharedInstance] setNextDeviceId:nextDeviceId];
    
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@",nextDeviceId]];// 将下一个设备的deviceId传出去
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}



// 设置灯泡开关，两个参数[deviceId, state]
- (void)setPower:(CDVInvokedUrlCommand *)command
{
    
    NSString *devId = [command.arguments objectAtIndex:0];
    NSLog(@"setPower - devId:%@",devId);
    NSNumber *deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]];
    
    NSString *st = [command.arguments objectAtIndex:1];
    NSLog(@"%@",st);
    
    CDVPluginResult *pluginResult = nil;
    NSNumber *powerSta;
    if ([st isEqualToString:@"true"]) {
        
        powerSta = [NSNumber numberWithInteger:1];
        [self setLEDState:powerSta withDeviceId:deviceId];
         pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"turnOn "];
        
    }else if([st isEqualToString:@"false"]){
        
        powerSta = [NSNumber numberWithInteger:0];
        [self setLEDState:powerSta withDeviceId:deviceId];
         pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"turnOff "];
        
    }else{
        
        NSString *error = [NSString stringWithFormat:@"Could not turnOn or turnOff."];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)setLEDState:(NSNumber *)state withDeviceId:(NSNumber *)deviceId
{
//    [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
//    [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];
    
    [[PowerModelApi sharedInstance] setPowerState:deviceId state:state acknowledged:YES];
    [manager stopScan];
}

// 设置灯泡亮度，两个参数 [deviceId, intensity]
- (void)setBrightness: (CDVInvokedUrlCommand *)command
{
    
    NSString *devId = [command.arguments objectAtIndex:0];
    NSNumber *deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]];

    NSString *intensity = [command.arguments objectAtIndex:1];
    float level = [intensity floatValue]; // 获取界面需要设置的亮度值（小数）

    NSLog(@"level  =====%f",level);
    
    CDVPluginResult *pluginResult = nil;
        
//        [[MeshServiceApi sharedInstance]setDeviceDiscoveryFilterEnabled:YES];
//        [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];

    [[LightModelApi sharedInstance]setLevel:deviceId level:[NSNumber numberWithFloat:level] acknowledged:YES];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"当前设置的灯泡亮度为%f",level]];
//    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"could not change brightness!"];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// 设置灯泡颜色,需要传参［deviceId, color］
- (void)setColor:(CDVInvokedUrlCommand *)command
{
   // NSString *uuid = [command.arguments objectAtIndex:0];
    
    NSString *devId = [command.arguments objectAtIndex:0];
    NSNumber *deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]];
    
    NSString *colorString = [command.arguments objectAtIndex:1];
    
    NSLog(@"十进制的颜色colorString ===== %@",colorString); // 十进制
    UIColor *color = [self getColorFromString:colorString];
    NSLog(@"十进制转换为UIColor的color ======== %@",color);

 //   CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];
    CDVPluginResult *pluginResult = nil;
    
 //   if (peripheral.state == CBPeripheralStateConnected ) {
            
            NSLog(@"discoveredBridges ====== %@",discoveredBridges);
        [self change2color:color withDeviceId:deviceId];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@",color]];
                
 //   }else{
 //           pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"could not change color!"];
  //  }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
// 改变颜色
- (void)change2color:(UIColor *)desiredColor withDeviceId:(NSNumber *)deviceId
{
//    [[MeshServiceApi sharedInstance] setDeviceDiscoveryFilterEnabled:YES];
//    [[MeshServiceApi sharedInstance]setNetworkPassPhrase:@"123"];
    
    // UIColor颜色取出R,G,B
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
    
    [[LightModelApi sharedInstance] setRgb:deviceId red:redColor green:greenColor blue:blueColor level:levelValue duration:duration acknowledged:YES];
    
    self.state = [NSNumber numberWithInteger:1];
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
    if ([colorString16 length] < 6) { // 对于转换为十六进制的，位数小于六位，在其前面补0
        
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


/* =========================================================*/
                    // 设置灯泡的groupId
//  需要传入两个参数：deviceId,groupIds(包含一个货多个groupId的数组)
/* =========================================================*/
- (void)setGroups:(CDVInvokedUrlCommand *)command
{
//  NSArray *devIdArray = [command.arguments objectAtIndex:0]; // 接收到的第一个参数deviceId是一个数组，虽然内部实际上就1个值
//  for (NSString *devId in devIdArray) {
//      deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]]; // 取数组中NSString值，转化为需要的NSNumber
//  }
    
    NSNumber *deviceId;
    NSString *devId = [command.arguments objectAtIndex:0];
    deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]]; // 取数组中NSString值，转化为需要的NSNumber
    
//    NSString *grouId = [command.arguments objectAtIndex:1]; // 2017.5.24 注释，接收的参数是包含一个或多个groupId数组
//    NSNumber *groupId = [NSNumber numberWithUnsignedInteger:[grouId integerValue]]; // 2017.5.24 注释
//    NSLog(@"deviceId :%@, groupId :%@",deviceId, groupId);
//    [[GroupModelApi sharedInstance] setModelGroupId:deviceId modelNo:@(19) groupIndex:@(0) instance:@(0) groupId:groupId]; // 2017.5.24 注释
//    [[GroupModelApi sharedInstance] setModelGroupId:deviceId modelNo:@(20) groupIndex:@(0) instance:@(0) groupId:groupId]; // 2017.5.24 注释
    
    
    // 2017.5.24 与android端统一插件;同一个灯泡可设置的分组数最大为4(硬件端的限制)，因此接收的参数为包含一个或多个groupId的数组
//    NSLog(@"class:%@",[[command.arguments objectAtIndex:1] class]); // class:__NSArrayM
    NSArray *groupIdArr = [command.arguments objectAtIndex:1];
    
    setGroupIdCallBackId = [command.callbackId copy];
    if(groupIdArr.count > 4){ // 如果同一个设备设置的分组数 > 4，返回失败
        
        NSLog(@"group's number is bigger than 4");
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"device's groupNumber is bigger than 4!"]]; // 页面js并未触发此失败返回结果
    }
    for(int i = 0; i< groupIdArr.count; i++){
        
        NSNumber *index = [NSNumber numberWithInt:i];
        [[GroupModelApi sharedInstance] setModelGroupId:deviceId modelNo:@(19) groupIndex:index instance:@(0) groupId:groupIdArr[i]];
        [[GroupModelApi sharedInstance] setModelGroupId:deviceId modelNo:@(20) groupIndex:index instance:@(0) groupId:groupIdArr[i]];
    }
    
}
// call back
- (void)didSetModelGroupId:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo groupIndex:(NSNumber *)groupIndex instance:(NSNumber *)instance groupId:(NSNumber *)groupId meshRequestId:(NSNumber *)meshRequestId
{
    NSLog(@"didSetModelGroupId");
    if (setGroupIdCallBackId) {
        CDVPluginResult *pluginResult = nil;
        NSString *g = [NSString stringWithFormat:@"设置groupId成功，grouoId为 %@",groupId];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:g];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:setGroupIdCallBackId];
    }
}


/* =========================================================*/
            // 重置灯泡的association信息
            //  需要传入两个参数：deviceId
/* =========================================================*/
- (void)resetDevice:(CDVInvokedUrlCommand *)command
{
    NSString *devId = [command.arguments objectAtIndex:0];
    NSLog(@"reset - deviceId : %@", devId);
    NSNumber *deviceId = [NSNumber numberWithUnsignedInteger:[devId integerValue]];
    
    [[ConfigModelApi sharedInstance] resetDevice:deviceId];
    
    CDVPluginResult *pluginResult = nil;
    NSString *resultString = [NSString stringWithFormat:@"重置成功,重置的deviceId 为 ：%@",deviceId];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:resultString];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
@end

