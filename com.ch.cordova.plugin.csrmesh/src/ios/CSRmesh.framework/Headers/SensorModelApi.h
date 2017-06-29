//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header SensorModelApi is a part of the CSRmesh Api and provides a set of methods related to the Sensor Model.
 */


@protocol SensorModelApiDelegate <NSObject>
@optional


/*!
 * @brief didGetSensorTypes. An acknowledgement to the request to get the Sensor Types
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensorTypesArray - (NSArray *) Array of unsigned short NSNumber values that represent the sensor types.
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetSensorTypes:(NSNumber *)deviceId sensorTypesArray:(NSArray *)sensorTypesArray meshRequestId:(NSNumber *)meshRequestId;

/*!
 * @brief didSetSensorState. An acknowledgement to the request to set the Sensor State
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensorType - (NSNumber *) The sensor Type as an unsigned short NSNumber.
 * @param repeatInterval - (NSNumber *) The repeat Interval as an unsigned char.
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetSensorState:(NSNumber *)deviceId sensorType:(NSNumber *)sensorType repeatInterval:(NSNumber *)repeatInterval  meshRequestId:(NSNumber *)meshRequestId;

/*!
 * @brief didGetSensorValue. An acknowledgement to the request to set the Sensor State. Provides the value for up to 2 sensor types. The value is of variable length from 0 to 4 octets
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensors - (NSDictionary) - The key is the NSNumber of the sensor Type as an unsigned short and the Value is the float of the sensor value wrapped in an NSNumber.
 * Temperature value will be of type float in units of kelvin and in steps of 1/32 or 0.03125
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetSensorValue:(NSNumber *)deviceId sensors:(NSDictionary *)sensors meshRequestId:(NSNumber *)meshRequestId;

@end


@interface SensorModelApi : NSObject

/*!
 * @enum  SensorTypes
 *        Pass as an unsigned short in an NSNumber object
 * @const   CSR_INTERNAL_AIR_TEMPERATURE The internal air temperature
 * @const   CSR_EXTERNAL_AIR_TEMPERATURE The External air temperature
 * @const   CSR_DESIRED_AIR_TEMPERATURE The desired air temperature
 */
enum SensorTypes {
    CSR_INTERNAL_AIR_TEMPERATURE=1,
    CSR_EXTERNAL_AIR_TEMPERATURE=2,
    CSR_DESIRED_AIR_TEMPERATURE=3
};


// init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the SensorModelApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief getTypes - request the Sensor Types that follow from the given given sensor. The callback didGetSensorTypes is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param firstType - (NSNumber *) The first sensor type as an unsigned short.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) getTypes:(NSNumber *)deviceId firstType:(NSNumber *)firstType;

/*!
 * @brief setState - Set the given sensor to the given state. The callback didSetSensorState is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensorType - (NSNumber *) The sensor type as an unsigned short.
 * @param repeatInterval - (NSNumber *) The sensor repeat interval state as an unsigned char.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) setState :(NSNumber *)deviceId sensorType:(NSNumber *)sensorType repeatInterval:(NSNumber *)repeatInterval;

/*!
 * @brief getState - Get the state for the given sensor. The callback didSetSensorState is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensorType - (NSNumber *) The sensor type as an unsigned short wrapped up in an NSNumber.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) getState:(NSNumber *)deviceId sensorType:(NSNumber *)sensorType;

/*!
 * @brief setValue - Write the given value to the given sensor. Up to two sensors can be written to in one command. If ack is YES then the meshRequestId will be returned, otherwise nil will be returned. The callback didGetSensorValue is invoked upon success, if ack is set to YES. The MeshServiceApi:didTimeoutMessage is invoked on failure, if ack is set to YES.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensors - (NSDictionary) - The key is the NSNumber of the sensor Type as an unsigned short and the Value is the NSNumber of the sensor value of size one to four octets.
 * Temperature value should be in Kelvin and of type float wrapped in an NSNumber.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) setValue:(NSNumber *)deviceId sensors:(NSDictionary *)sensors acknowledge:(NSNumber *)ack;


/*!
 * @brief getValue - Read the value for the given sensor(s). A read request for up to two sensors can be made in one command. The callback didGetSensorValue is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param sensorType1 - (NSNumber *) The first sensor type as an unsigned short wrapped up in an NSNumber.
 * @param sensorType2 - (NSNumber *) The second sensor type as an unsigned short wrapped up in an NSNumber. This is optional and may be nil.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetPowerState.
 */
-(NSNumber *) getValue:(NSNumber *)deviceId sensorType1:(NSNumber *)sensorType1 sensorType2:(NSNumber *)sensorType2;


// The Delegate for this object
@property (nonatomic, weak)   id<SensorModelApiDelegate>  sensorModelApiDelegate;


// response from Library
-(void) sensorValueResponse :(NSNumber *)deviceId sensorData:(NSData *)sensorData meshRequestId:(NSNumber *)meshRequestId;


@end

