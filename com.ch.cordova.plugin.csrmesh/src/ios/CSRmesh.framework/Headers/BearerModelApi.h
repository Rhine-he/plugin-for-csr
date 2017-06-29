//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header BearerModelApi is a part of the CSRmesh Api and provides a set of methods related to the Bearer Model.
 */


@protocol BearerModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetBearerState delegate. Invoked by the CSRmesh library upon receiving a State message fron the device
 * @param deviceId - The ID assigned by the library to this device
 * @param bearerRelayActive -  Unsigned Short Integer of the Bitfield of active relay bearers with bits mapped as follows
 *  Bit 0 = le_advertising
 *  Bit 1 = le_gatt_server
 *  Bit 2 = udp_ip_4
 *  Bit 3 = udp_ip_6
 *  Bit 4 = tcp_ip
 *  Bit 5 = wifi_beacon_bearer
 * @param bearerEnabled -  Unsigned Short Integer of the Bitfield of enabled bearers with bits mapps as follows
 *  Bit 0 = le_advertising
 *  Bit 1 = le_gatt_server
 *  Bit 2 = udp_ip_4
 *  Bit 3 = udp_ip_6
 *  Bit 4 = tcp_ip
 *  Bit 5 = wifi_beacon_bearer
 * @param promiscuous -  (NSNumber *) Unsigned Short Integer of the bitfield where each bit determines if the given bearer promiscuity is enabled. Enabled in this context means that the bearer can relay all traffic it receives even if it does not match any known NetworkKeys
 * Bit 0 = le_advertising
 * Bit 1 = le_gatt_server
 */
-(void) didGetBearerState:(NSNumber *)deviceId bearerRelayActive:(NSNumber *)bearerRelayActive bearerEnabled:(NSNumber *)bearerEnabled promiscuous:(NSNumber *)promiscuous meshRequestId:(NSNumber *)meshRequestId;

@end



@interface BearerModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the AttentionModelApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;


    // Bearer Api Methods
/*!
 * @brief getState - Request the state from the given device. As this is an asynchronous process, the request will be returned via the didGetBearerState delegate call.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 */
-(NSNumber *) getState:(NSNumber *)deviceId;

/*!
 * @brief setState - Set the device Bearer and Relay state to the values given. The delegate didGetBearerState will be invoked upon successful completion of this request.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param bearerRelayActive -  (NSNumber *)  Unsigned Short Integer of the Bitfield of active relay bearers with bits mapped as follows
 * Bit 0 = le_advertising
 * Bit 1 = le_gatt_server
 * Bit 2 = udp_ip_4
 * Bit 3 = udp_ip_6
 * Bit 4 = tcp_ip
 * Bit 5 = wifi_beacon_bearer
 * @param bearerEnabled - (NSNumber *) Unsigned Short Integer of the Bitfield of enabled bearers with bits mapps as follows
 * Bit 0 = le_advertising
 * Bit 1 = le_gatt_server
 * Bit 2 = udp_ip_4
 * Bit 3 = udp_ip_6
 * Bit 4 = tcp_ip
 * Bit 5 = wifi_beacon_bearer
 * @param promiscuous -  (NSNumber *) Unsigned Short Integer of the bitfield where each bit determines if the given bearer promiscuity is enabled. Enabled in this context means that the bearer can relay all traffic it receives even if it does not match any known NetworkKeys
 * Bit 0 = le_advertising
 * Bit 1 = le_gatt_server
 */
-(NSNumber *) setState:(NSNumber *)deviceId bearerRelayActive:(NSNumber *)bearerRelayActive bearerEnabled:(NSNumber *)bearerEnabled promiscuous:(NSNumber *)promiscuous;

    // The Delegate for this object
@property (nonatomic, weak)   id<BearerModelApiDelegate>  bearerModelApiDelegate;



@end
