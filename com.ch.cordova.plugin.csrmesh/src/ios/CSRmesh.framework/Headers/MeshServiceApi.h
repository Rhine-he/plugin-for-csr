//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


/*!
 * @header MeshServiceApi Class is a part of the CSRmesh Api and provides a set of methods to Initialise the CSRmesh system, Discover a Bridge Device, Discover and Associate Mesh Devices.
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define CSR_NotifiedValueForCharacteristic  @"CSR_NotifiedValueForCharacteristic"
#define CSR_didUpdateValueForCharacteristic @"CSR_didUpdateValueForCharacteristic"
#define CSR_PERIPHERAL                      @"CSR_PERIPHERAL"

@protocol MeshServiceApiDelegate <NSObject>
@optional
/*!
 * @brief didAssociate delegate. invoked by the CSRmesh library upon successful Association of a device.
 * @param deviceId - The ID assigned by the library to this device
 * @param deviceHash - The deviceHash belonging to the device, this is used to pair up devices which were instructed to Associate using the method associateDevice.
 * @param meshRequestId - The ID returned from the associateDevice Api call.
 */
-(void) didAssociateDevice:(NSNumber *)deviceId deviceHash:(NSData *)deviceHash meshRequestId:(NSNumber *)meshRequestId;

/*!
 * @brief isAssociatingDevice delegate. Invoked by the CSRmesh library. Provides an indication of progress.
 * @param deviceHash - The device under Association
 * @param stepsCompleted - The number of steps completed
 * @param totalSteps - The total number of steps
 * @param meshRequestId - The ID returned from the associateDevice Api call.
 * @warning If the stepsCompleted > totalSteps this indicates failed to Associate
 */
-(void) isAssociatingDevice:(NSData *)deviceHash stepsCompleted:(NSNumber *)stepsCompleted totalSteps:(NSNumber *)totalSteps meshRequestId:(NSNumber *)meshRequestId;

/*!
 * @brief didDiscoverDevice delegate. Invoked by the CSRmesh library.
 * @param uuid - The CBUUID of the Un-Associated Mesh Device
 * @param rssi - The signal strength at the receiver.
 */
-(void) didDiscoverDevice:(CBUUID *)uuid rssi:(NSNumber *)rssi;


/*!
 * @brief setScannerEnabled delegate. Invoked by the CSRmesh library.
 * @param enabled - NSNumber boolValue of the request from the Library to change the state of the Scanner. If this delegate is not implemented then the CSRmesh Library will control the scanner directly. This is conditional on the Application having first made a call to setCentralManager to pass the CBCentralManager handle to the Library.
 */
-(void) setScannerEnabled:(NSNumber *)enabled;

/*!
 * @brief didUpdateAppearance delegate. Invoked by the CSRmesh library.
 * @param deviceHash - NSData. This is the lowest 31-bits of the SHA-256 of the DeviceUUID of New Device.
 * @param appearanceValue - NSData. The Appearance field is a 24-bit value that is composed of an “organization” and an “organization appearance”. The following organizations are defined:
 * 0x00 = Bluetooth SIG
 * For the Bluetooth SIG organization, the organization appearance is from the assigned numbers for the Appearance Characteristic Value.
 * @param shortName - NSData. The ShortName field is the first 9-octets of the name of this device. This is set by the manufacturer of the device.
 */
-(void) didUpdateAppearance:(NSData *)deviceHash appearanceValue:(NSData *)appearanceValue shortName:(NSData *)shortName;


/*!
 * @brief didTimeoutMessage delegate. Invoked by the CSRmesh library to indicate loss of acknowledgement. Each of the acknowledged Api methods when called returns a meshRequestId. The same meshRequestId is used in this callback to indicate a loss of acknowledgement for the given messageId within the given timeout. The timeout can be computed as the (number_of_retries x retry_interval)
 * @param meshRequestId - NSNumber. This is an int32 and is the ID of method call made into the library.
 */
-(void) didTimeoutMessage:(NSNumber *)meshRequestId;


@end


enum {
    NOT_MESH = 0,
    IS_BRIDGE,
    DID_ABSORB_MESSAGE,
    IS_BRIDGE_DISCOVERED_SERVICE
};


typedef enum {
    CSR_SCAN_LISTEN_MODE = 0,
    CSR_SCAN_NOTIFICATION_LISTEN_MODE,
    CSR_NOTIFICATION_LISTEN_MODE,
} BleListenMode;


@interface MeshServiceApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;


    // Mesh Service Api Method
/*!
 * @brief setCentralManager. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @param centralManager - The id of the CBCentralManager object. This make sit possible for the library to control the state of the Scanner. Limiting the use of the scanner is a way of saving battery power.
 */
-(void) setCentralManager:(CBCentralManager *)centralManager;

/*!
 * @brief getDeviceHashFromUuid. Convert the given CBUUID to a deviceHash.
 * @param uuid - The id of the CBCentralManager object. This make sit possible for the library to control the state of the Scanner. Limiting the use of the scanner is a way of saving battery power.
 * @return NSData * - The deviceHash in little endian format.
 * @warning - The uuid is converted to little Endian Format, the device hash is computed and this is also converted to little endian format before it is returned.
 */
-(NSData *) getDeviceHashFromUuid:(CBUUID *)uuid;


/*!
 * @brief getAuthorizationCode. Extract and return the Authorisation code from the given Short Code.
 * @param shortCode - NSString object of the shortcode.
 * @return NSData * - The authorisationCode or nil if the short code was invalid.
 */
-(NSData *) getAuthorizationCode:(NSString *)shortCode;

/*!
 * @brief getDeviceHashFromShortCode. Extract and return the device hash from the given Short Code.
 * @param shortCode - NSString object of the shortcode.
 * @return NSData * - The deviceHash or nil if the short code was invalid.
 */
-(NSData *) getDeviceHashFromShortCode:(NSString *)shortCode;


/*!
 * @brief associateDevice. En-queues the given mesh device for Association. The requets is queued because only one device at a time is allowed to be in the association state. As this is an asynchronous process, the two delegates, isAssociatingDevice and didAssociateDevice are provided for feedback on the Associaiton progress.
 * @param deviceHash - NSData object of the deviceHash.
 * @param authorisationCode - NSData object of the Authorisation code. Note this is optional and must be set to nil if authorisation code is not provided.
 * @return NSNumber - The id of the Api call. Will be returned by didTimeout or didAssociateDevice
 */
-(NSNumber *) associateDevice:(NSData *)deviceHash authorisationCode:(NSData *)authorisationCode;


/*!
 * @brief processMeshAdvert. The given CSRmesh advertisment is decrypted and a value is returned that indicates how the CSRmesh Library processed the advert.
 * @param advertisment - (NSDictionary *) object of the advertisment scanned by the CBCentralManager.
 * @param RSSI - (NSNumber *) object of the signal strength.
 * @return (NSNumber *) - A value that can be interpreted as follows :-
 *  0 - Advertisment not related to CSRmesh
 *  1 - This is an advertisment from a Bridge Device
 *  2 - A valid CSRmesh advertisment from a CSRmesh device that was consumed by the CSRmesh Library
 */
-(NSNumber *) processMeshAdvert:(NSDictionary *)advertisment RSSI:(NSNumber *)RSSI;


/*!
 * @brief setContinuousLeScanEnabled. Continuous scan should be used to receive asynchronous data from a mesh device and should be used sparingly so as to preserve battery power.
 * @param enabled - (BOOL) 
 *  YES = set continuous scan.
 *  NO = disable continuous scan.
 */
-(void) setContinuousLeScanEnabled:(BOOL)enabled;


/*!
 * @brief connectBridge. After a connection is made to a Bridge Device, this method should be called so that the CSRmesh Library can use the Bridge to send data over the Mesh network.
 * @param bridge - (CBPeripheral *) The conected peripheral
 * @param bridgeNotification - (NSNumber *) BleListenMode enum (CSR_SCAN_LISTEN_MODE, CSR_SCAN_NOTIFICATION_LISTEN_MODE, CSR_NOTIFICATION_LISTEN_MODE
 */
-(void) connectBridge:(CBPeripheral *)bridge enableBridgeNotification:(NSNumber *)bridgeNotification;


/*!
 * @brief disconnectBridge. Inform the CSRmesh Library that the given bridge was disconnected.
 * @param bridge - (CBPeripheral *) The conected peripheral
 */
-(void) disconnectBridge:(CBPeripheral *)bridge;


/*!
 * @brief setDeviceDiscoveryFilterEnabled. Commands the CSRmesh Library to inhibit or allow the discovery of new CSRmesh un-associated devices. If allowed, the delegate didDiscoverDevice shall be invoked for each device advertisment received from an unassociated device.
 * @param enabled - (BOOL)
 *  YES = Allow
 *  NO = Inhibit
 */
-(void) setDeviceDiscoveryFilterEnabled:(BOOL)enabled;


/*!
 * @brief setNetworkPassPhrase. Set the Network key that will be used when associating mesh devices. The network key for Devices already associated will not be changed.
 * @param passPhrase - (NSString *) The pass phrase that will be used to generate a netowrk key.
 */
-(void) setNetworkPassPhrase:(NSString *)passPhrase;


/*!
 * @brief setNextDeviceId. Set the deviceId that will be assigned to the next associated device. 
 * @param deviceId - (NSNumber *) Unsigned short value
 * @warning - care should be taken to avoid using the same deviceId for more than one device as this may corrupted messages received from the devices that share the same deviceId
 */
-(void) setNextDeviceId:(NSNumber *)deviceId;


/*!
 * @brief setControllerAddress. Assign the given ID to the host.
 * @param hostId - (NSNumber *) Unsigned short value (0000 - FFFF)
 * @warning - care should be taken to avoid using the same hostId as the DeviceIds or GroupIds.
 */
-(void) setControllerAddress:(NSNumber *)hostId;


/*!
 * @brief getControllerAddress. Retrieves the ID of the host.
 * @return NSNumber - The Unsigned Short ID of the host as an NSNumber object.
 */
-(NSNumber *) getControllerAddress;


/*!
 * @brief setResendInterval. Set the mesh packet resend interval
 * @param timeInterval - (NSNumber *) int milliseconds (maximum=60000)
 * @warning - The new resend interval will always be set for the next command to be sent. Also as there is no persistence in the CSRmesh library, please set this value on App start up.
 */
-(void) setResendInterval:(NSNumber *)timeInterval;

/*!
 * @brief setRetryCount. mesh packet retry count.
 * @param retryCount - (NSNumber *) int retryCount
 * @warning - The new Retry count will always be set for the Next Command to be sent. Also as there is no persistence in the CSRmesh library, please set this value on App start up.
 */
-(void) setRetryCount:(NSNumber *)retryCount;

/*!
 * @brief setAttentionPreAssociation. Attaract attention on/off
 * @param deviceHash - NSData. This is the lowest 31-bits of the SHA-256 of the DeviceUUID of New Device.
 * @param attentionState - NSNumber. This is an NSNumber containing the BOOL value of the desired state. YES=attract Attention
 * @param duration - NSNumber. This is an NSNumber containing the 16-bit duration in milliseconds
 */
-(void) setAttentionPreAssociation:(NSData *)deviceHash attentionState:(NSNumber *)attentionState withDuration:(NSNumber *) duration;

/*!
 * @brief killTransaction. Abort an acknowledged mesh request.
 * @param meshRequestId - NSNumber meshReqeustId
 * @return success or failure
 */
-(BOOL) killTransaction:(NSNumber *)meshRequestId;




    // The Delegate for this object
@property (nonatomic, weak)   id<MeshServiceApiDelegate>  meshServiceApiDelegate;


@end
