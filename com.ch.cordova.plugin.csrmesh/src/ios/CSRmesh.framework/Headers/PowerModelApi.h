//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header PowerModelApi is a part of the CSRmesh Api and provides a set of methods related to the Power Model.
 */


@protocol PowerModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetPowerState. An acknowledgement to the request to getState, setPowerState
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param state - (NSNumber *) The current power state (0=Off, 1=On, 2=Standby, 3=On from Standby)
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId;

@end


@interface PowerModelApi : NSObject

// init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
* @brief getState - Request the power state. The callback didGetPowerState is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
* @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
* @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
*/
-(NSNumber *) getState:(NSNumber *)deviceId;


/*!
 * @brief setPowerState - Set the power state. The callback didGetPowerState is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param state - (NSNumber *) The desired power state (0=Off, 1=On, 2=Standby, 3=On from Standby)
 * @param acknowledged - (BOOL) set to YES to acknowledge receipt. The callback didGetPowerState will be invoked on success otherwise MeshServiceApi:didTimeoutMessage
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) setPowerState:(NSNumber *)deviceId state:(NSNumber *)state acknowledged:(BOOL)acknowledged;


    // The Delegate for this object
@property (nonatomic, weak)   id<PowerModelApiDelegate>  powerModelApiDelegate;

@end
