//
// Copyright Cambridge Silicon Radio Limited 2014 - 2015
//


#import <Foundation/Foundation.h>

/*!
 * @header AttentionModelApi is a part of the CSRmesh Api and provides a set of methods related to the Attention Model.
 *
 */



@protocol AttentionModelApiDelegate <NSObject>
@optional

/*!
 * @brief didGetState delegate. Invoked by the CSRmesh library upon receiving a state message fron the device
 * @param deviceId The ID assigned by the library to this device
 * @param state The attract attention state of the device.
 *  YES = attracting attention
 *  NO = not attracting attention
 * @param meshRequestId The ID assigned to the Api call that triggered this callback.
 */
-(void) didGetState:(NSNumber *)deviceId state:(BOOL)state meshRequestId:(NSNumber *)meshRequestId;

@end


@interface AttentionModelApi : NSObject

    // init
/*!
 * @brief sharedInstance. This method must be called upon the first use of the AttentionModelApi as it creates and initialises singleton object and returns a handle to it so that the same can be used to invoke instance methods.
 * @return id - The id of the singleton object.
 */
+ (id) sharedInstance;
-(id) init;


    // Attention Api Method
    // Flash the Light in Red at 50% duty cycle
    // duration is in milliseconds
/*!
 * @brief setState - If attractAttention is set to YES then the LED will flash at duty cycle of 50% and at a rate set by duration.
 * @param deviceId - (NSNumber *) The ID of this device. Refer to the delegate MeshServiceApi.didAssociateDevice
 * @param attractAttention - Enable or Disable attract attention
 * @param duration - (NSNumber *) Unsigned Short Value of the duration in milliseconds
 * @return meshRequestId - The id of the message.
 */
-(NSNumber *) setState:(NSNumber *)deviceId attractAttention:(BOOL)attractAttention duration:(NSNumber *)duration;


// The Delegate for this object
@property (nonatomic, weak)   id<AttentionModelApiDelegate>  attentionModelApiDelegate;


@end
