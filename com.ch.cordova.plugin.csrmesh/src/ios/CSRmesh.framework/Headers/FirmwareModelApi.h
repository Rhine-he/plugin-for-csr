//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header FirmwareModelApi is a part of the CSRmesh Api and provides a set of methods related to the Firmware Model.
 */


@protocol FirmwareModelApiDelegate <NSObject>
@optional

/*!
 * @brief didSetUpdateRequired. Invoked by the CSRmesh library to indicate success:set Device to Firmware update mode
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didSetUpdateRequired:(NSNumber *)deviceId meshRequestId:(NSNumber *)meshRequestId;


/*!
 * @brief didSetUpdateRequired. Invoked by the CSRmesh library to indicate success:set Device to Firmware update mode
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param versionMajor - (NSNumber *) unsigned Short of the major portion of the version number
 * @param versionMinor - (NSNumber *) unsigned Short of the minor portion of the version number
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetVersionInfo:(NSNumber *)deviceId versionMajor:(NSNumber *)versionMajor versionMinor:(NSNumber *)versionMinor meshRequestId:(NSNumber *)meshRequestId;

@end


@interface FirmwareModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief setUpdateRequired - Request the device to enter Firmware Update Mode. The callback didSetUpdateRequired is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didSetUpdateRequired.
 */
-(NSNumber *) setUpdateRequired:(NSNumber *)deviceId;


/*!
 * @brief getVersionInfo - Request the device software version. The callback didGetVersionInfo is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetVersionInfo.
 */
-(NSNumber *) getVersionInfo:(NSNumber *)deviceId;


// The Delegate for this object
@property (nonatomic, weak)   id<FirmwareModelApiDelegate>  firmwareModelApiDelegate;

@end
