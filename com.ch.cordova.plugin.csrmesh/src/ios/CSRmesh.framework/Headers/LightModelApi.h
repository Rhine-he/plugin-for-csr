//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>
/*!
 * @header LightModelApi is a part of the CSRmesh Api and provides a set of methods related to the Light Model.
 */



@protocol LightModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetLightState. An acknowledgement to the request to getState, setColorTemperature, setRgb, setLevel
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param red - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param green - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param blue - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param level - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param powerState - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param colorTemperature - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param supports - (NSNumber *) unsigned char wrapped in an NSNumber. Support Bits
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId;

@end



@interface LightModelApi : NSObject


    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief getState - Request the light state. The callback didGetLightState is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetLightState.
 */
-(NSNumber *) getState:(NSNumber *)deviceId;


/*!
 * @brief setColorTemperature - Set the colour temperature.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param temperature - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param duration - (NSNumber *) unsigned 16-bit wrapped in NSNumber and represents time in millieseconds over which the temperature will fade.
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetLightState.
 */
-(NSNumber *) setColorTemperature:(NSNumber *)deviceId temperature:(NSNumber *)temperature duration:(NSNumber *)duration;


/*!
 * @brief setRgb - Set the colour.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param red - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param green - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param blue - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param level - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param duration - (NSNumber *) unsigned 16-bit wrapped in NSNumber and represents time in millieseconds over which the temperature will fade.
 * @param acknowledged - (BOOL) set to YES to acknowledge receipt. The callback didGetLightState will be invoked on success otherwise MeshServiceApi:didTimeoutMessage
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetLightState.
 */
-(NSNumber *) setRgb:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level duration:(NSNumber *)duration acknowledged:(BOOL)acknowledged;


/*!
 * @brief setLevel - Set the Intensity.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param level - (NSNumber *) unsigned char wrapped in an NSNumber.
 * @param acknowledged - (BOOL) set to YES to acknowledge receipt. The callback didGetLightState will be invoked on success otherwise MeshServiceApi:didTimeoutMessage
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetLightState.
 */
-(NSNumber *) setLevel:(NSNumber *)deviceId level:(NSNumber *)level acknowledged:(BOOL)acknowledged;


    // The Delegate for this object
@property (nonatomic, weak)   id<LightModelApiDelegate>  lightModelApiDelegate;



@end
