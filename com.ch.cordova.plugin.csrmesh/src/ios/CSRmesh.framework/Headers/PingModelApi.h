//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header PingModelApi is a part of the CSRmesh Api and provides a set of methods related to the Ping Model. 
 */


@protocol PingModelApiDelegate <NSObject>
@optional


/*!
 * @brief didPing. An acknowledgement to the request to ping
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param arbitaryData - (NSData *) data received, 4 octets.
 * @param TTLAtRx - (NSData *) Time to Live, TTL, value at device, 1 octet
 * @param RSSIAtRx - (NSData *) RSSI of received signal at device, 1 octet
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didPing :(NSNumber *)deviceId arbitaryData:(NSData *)arbitaryData TTLAtRx:(NSData *)TTLAtRx RSSIAtRx:(NSData *)RSSIAtRx meshRequestId:(NSNumber *)meshRequestId;
@end

@interface PingModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief ping - ping the device with some data. The callback didPing is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param data - (NSData *) Data, up to 250 octets.
 * @param rspTTL - (NSNumber *) 1 octet wrapped in NSNumber.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) ping :(NSNumber *)deviceId data:(NSData *)data rspTTL:(NSNumber *)rspTTL;

// The Delegate for this object
@property (nonatomic, weak)   id<PingModelApiDelegate>  pingModelApiDelegate;

@end
