//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header ActuatorModelApi is a part of the CSRmesh Api and provides a set of methods related to the Actuator Model.
 */


@protocol ActuatorModelApiDelegate <NSObject>
@optional


/*!
 * @brief didGetActuatorTypes. An acknowledgement to the request to get the Actuator Types
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param actuatorTypesArray - (NSArray *) Array of unsigned short NSNumber values that represent the Actuator types.
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetActuatorTypes :(NSNumber *)deviceId actuatorTypesArray:(NSArray *)actuatorTypesArray meshRequestId:(NSNumber *)meshRequestId;

/*!
 * @brief didGetActuatorValue. An acknowledgement to the request to set the Actuator State
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param actuatorType - (NSNumber *) The actuator Type as an unsigned short NSNumber.
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetActuatorValueAck :(NSNumber *)deviceId actuatorType:(NSNumber *)actuatorType  meshRequestId:(NSNumber *)meshRequestId;


@end


@interface ActuatorModelApi : NSObject


// init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the ActuatorModelApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief getTypes - request the Actuator Types that follow from the given given Actuator. The callback didGetActuatorTypes is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param firstType - (NSNumber *) The first actuator type as an unsigned short.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) getTypes :(NSNumber *)deviceId firstType:(NSNumber *)firstType;


/*!
 * @brief setValue - Write the given value to the given actuator. If ack is YES then the meshRequestId will be returned, otherwise nil will be returned. The callback didGetActuatorValue is invoked upon success, if ack is set to YES. The MeshServiceApi:didTimeoutMessage is invoked on failure, if ack is set to YES.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param actuatorType - (NSNumber *) The actuator type as an unsigned short wrapped up in an NSNumber.
 * @param actuatorValue - (NSData *) The value for an actuator as double wrapped in NSNumber. For temperature units are kelvin.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) setValue:(NSNumber *)deviceId actuatorType:(NSNumber *)actuatorType actuatorValue:(NSNumber *)actuatorValue acknowledge:(NSNumber *)ack;


// The Delegate for this object
@property (nonatomic, weak)   id<ActuatorModelApiDelegate>  actuatorModelApiDelegate;


@end

