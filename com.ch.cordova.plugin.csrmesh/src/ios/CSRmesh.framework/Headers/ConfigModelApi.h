//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header ConfigModelApi is a part of the CSRmesh Api and provides a set of methods related to the Config Model.
 */

#define kCSR_UUID_LOW               @"CSR_UUID_LOW"
#define kCSR_UUID_HIGH              @"CSR_UUID_HIGH"
#define kCSR_MODEL_LOW              @"CSR_MODEL_LOW"
#define kCSR_MODEL_HIGH             @"CSR_MODEL_HIGH"
#define kCSR_VENDOR_IDENTIFIER      @"CSR_VENDOR_IDENTIFIER"
#define kCSR_PRODUCT_IDENTIFIER     @"CSR_PRODUCT_IDENTIFIER"
#define kCSR_VERSION_NUMBER         @"CSR_VERSION_NUMBER"
#define kCSR_APPEARANCE             @"CSR_APPEARANCE"
#define kCSR_LAST_ETAG              @"CSR_LAST_ETAG"


enum  {
    CSR_UUID_low = 0,
    CSR_UUID_high,
    CSR_Model_low,
    CSR_Model_high,
    CSR_VID_PID_Version,
    CSR_Appearance,
    CSR_LastETag,
};


@protocol ConfigModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetDeviceInfo delegate. Invoked by the CSRmesh library upon receiving the request to getInfo
 * @param deviceId - The ID assigned by the library to this device
 * @param info - (NSDictionary *) of the information requested
 * kCSR_UUID_LOW - NSData of lower 64-bits of the UUID
 * kCSR_UUID_HIGH - NSData of the higher 64-bits of the UUID
 * kCSR_MODEL_LOW - NSData of the lower 64-bits of the bit encoded Models
 * kCSR_MODEL_HIGH - NSData of the higher 64-bits of the bit encoded Models
 * kCSR_VENDOR_IDENTIFIER - The VendorIdentifier is a 16-bit unsigned integer. This shall use the same enumerations as the existing Bluetooth SIG Company Identification assigned numbers
 * kCSR_PRODUCT_IDENTIFIER - The ProductIdentifier is a 16-bit unsigned integer allocated by the Vendor
 * kCSR_VERSION_NUMBER - The VersionNumber is a 32-bit unsigned integer allocated per product by the vendor. Each new version of the device shall have a different VersionNumber. A new version is defined as any change to the software, hardware or firmware of a device, even if this change is meant to have no material impact to the behavior of the device.
 * kCSR_APPEARANCE - The Appearance is a 24-bit unsigned integer using the same the Bluetooth SIG GAP Appearance characteristic values.
 * kCSR_LAST_ETAG - The LastETag is a 64-bit unsigned integer that shall be set to a different value each time the device has a change in its configuration. This value is a read only value, and can be used to quickly determine if a device has changed the configuration of a device without another device reading the full configuration. The configuration is defined as any change to the device such that the device behavior changes - for example, changing Groups or the interval for sending Sensor broadcast data
 *
 * @param infoType - (NSNumber *) Unsigned Char encoded with the type of information requested as follows
 */
-(void) didGetDeviceInfo:(NSNumber *)deviceId info:(NSDictionary *)info infoType:(NSNumber *)infoType meshRequestId:(NSNumber *)meshRequestId;


/*!
 * @brief didResetDevice delegate. Invoked by the CSRmesh library upon successful device reset
 * @param deviceId - The ID assigned by the library to this device
 */
-(void) didResetDevice:(NSNumber *)deviceId deviceHash:(NSData *)deviceHash;

@end


@interface ConfigModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the AttentionModelApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;

/*!
 * @brief getInfo - Request low level info from device
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param infoType - The type of Info
 *  0 - UUID_low,
 *  1 - UUID_high,
 *  2 - Model_low,
 *  3 - Model_high,
 *  4 - VID_PID_Version,
 *  5 - Appearance,
 *  6 - LastETag
 *  ff - UnknownInfoType
 * @return meshRequestId - The id of the message.
 */
-(NSNumber *) getInfo:(NSNumber *)deviceId infoType:(NSNumber *)infoType;


/*!
 * @brief resetDevice - Request the device to delete its Association information
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 */
-(void) resetDevice:(NSNumber *)deviceId;


// The Delegate for this object
@property (nonatomic, weak)   id<ConfigModelApiDelegate>  configModelApiDelegate;



@end
