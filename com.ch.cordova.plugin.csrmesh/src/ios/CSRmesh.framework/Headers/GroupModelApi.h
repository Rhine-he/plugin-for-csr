//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header GroupModelApi is a part of the CSRmesh Api and provides a set of methods related to the Group Model.
 */


@protocol GroupModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetNumModelGroupIds. Invoked by the CSRmesh library to indicate success:get Number of Model Group IDs
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param modelNo - (NSNumber *) The model number for which this calback is made.
 * @param numberOfModelGroupIds - (NSNumber *) The number of Group indexes supported by this model
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetNumModelGroupIds:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo numberOfModelGroupIds:(NSNumber *)numberOfModelGroupIds meshRequestId:(NSNumber *)meshRequestId;


/*!
 * @brief didSetModelGroupId. Invoked by the CSRmesh library to indicate success:set Model Group ID
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param modelNo - (NSNumber *) The model number
 * @param groupIndex - (NSData *) The offset of the groupID in the table of Group indexes supported by the model
 * @param instance - (NSNumber *) The model instance
 * @param groupId - (NSNumber *) The group ID is an unsigned 16-bit number.
 * @param meshRequestId - (NSNumber *) The ID assigned to the Api call that triggered this callback.
 */
-(void) didSetModelGroupId:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo groupIndex:(NSNumber *)groupIndex instance:(NSNumber *)instance groupId:(NSNumber *)groupId meshRequestId:(NSNumber *)meshRequestId;

@end



@interface GroupModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the MershServiceApi as it creates and initialises a singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;


/*!
 * @brief getNumModelGroupIds - Request the Total number of Group Ids for a Model. The callback didGetNumModelGroupIds is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param modelNo - (NSNumber *) The Model number for the Group IDs request
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetNumModelGroupIds.
 */
-(NSNumber *) getNumModelGroupIds:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo;


/*!
 * @brief setModelGroupId - Set Group Id for a Model, group index and model instance. The callback didSetModelGroupId is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param modelNo - (NSNumber *) The Model number for the Group IDs request
 * @param groupIndex - (NSNumber *) A number of Group IDs can be stored in a model instance, this is determined by a call to
 * @param instance - (NSNumber *) The model instance for this device for which the Group ID for the given group index is set
 * @param groupId - (NSNumber *) The groupId to be set for the given Model, intance and Group index
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetNumModelGroupIds.
 */
-(NSNumber *) setModelGroupId:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo groupIndex:(NSNumber *)groupIndex instance:(NSNumber *)instance groupId:(NSNumber *)groupId;


/*!
 * @brief getModelGroupId - Get Group Id for a Model and group index. The callback didSetModelGroupId is invoked upon success. The MeshServiceApi:didTimeoutMessage is invoked on failure.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param modelNo - (NSNumber *) The Model number for the Group IDs request
 * @param groupIndex - (NSNumber *) A number of Group IDs can be stored in a model instance, this is determined by a call to
 * @return meshRequestId - (NSNumber *) The id of the request. Pair up with the id returned in didGetNumModelGroupIds.
 */
-(NSNumber *) getModelGroupId:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo groupIndex:(NSNumber *)groupIndex;

// The Delegate for this object
@property (nonatomic, weak)   id<GroupModelApiDelegate>  groupModelApiDelegate;


@end
