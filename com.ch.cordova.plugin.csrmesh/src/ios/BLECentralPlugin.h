//
//  BLECentralPlugin.h
//  BLE_Test3
//
//  Created by heyun on 16/12/22.
//
//

#ifndef BLECentralPlugin_h
#define BLECentralPlugin_h

#import <Cordova/CDV.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheral+Extensions.h"
#import <CSRmesh/MeshServiceApi.h>

@interface BLECentralPlugin : CDVPlugin <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSString *discoverPeripherialCallbackId;
    NSMutableDictionary *connectCallbacks;
    NSMutableDictionary *readCallbacks;
    NSMutableDictionary *writeCallbacks;
    NSMutableDictionary *notificationCallbacks;
    NSMutableDictionary *stopNotificationCallbacks;
    NSMutableDictionary *connectCallbackLatches;
    NSString *deviceIdCallBackId;
    NSString *setGroupIdCallBackId;
    NSString *getUnAssociatedDevicesCallBackId;
}

@property (strong, nonatomic) CBCentralManager *manager;
@property (strong, nonatomic) NSMutableArray *discoveredBridges;////
@property (nonatomic ,strong) NSMutableSet  *peripherals;

- (void)scan:(CDVInvokedUrlCommand *)command;
- (void)startScan:(CDVInvokedUrlCommand *)command;
- (void)stopScan:(CDVInvokedUrlCommand *)command;

- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;

//- (void)read:(CDVInvokedUrlCommand *)command;
//- (void)write:(CDVInvokedUrlCommand *)command;
//- (void)writeWithoutResponse:(CDVInvokedUrlCommand *)command;

//- (void)startNotification:(CDVInvokedUrlCommand *)command;
//- (void)stopNotification:(CDVInvokedUrlCommand *)command;

- (void)isEnabled:(CDVInvokedUrlCommand *)command;
- (void)isConnected:(CDVInvokedUrlCommand *)command;

//- (void)close:(CDVInvokedUrlCommand*)command;
//- (void)open:(CDVInvokedUrlCommand*)command;
- (void)setPower:(CDVInvokedUrlCommand *)command;
- (void)setColor:(CDVInvokedUrlCommand *)command;
@end

#endif

