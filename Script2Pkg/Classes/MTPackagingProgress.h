/*
     MTPackagingProgress.h
     Copyright 2022-2024 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import <Foundation/Foundation.h>

/*!
 @abstract A class for tracking packaging progress.
 */

@interface MTPackagingProgress : NSObject

/*!
 @enum          Packaging State
 @abstract      Specifies the different states of the packaging process.
 @constant      MTPackagingStateWaiting The package is waiting for packaging.
 @constant      MTPackagingStatePKGBuild The package is being built.
 @constant      MTPackagingStateNotarizing The package is being notarized.
 @constant      MTPackagingStateCopyPKG The package is copied to the final location.
 @constant      MTPackagingStatePKGBuildFailed Building the package failed.
 @constant      MTPackagingStateNotarizingFailed Notarization of the package failed.
 @constant      MTPackagingStateCopyPKGFailed The package could not be copied to the final location.
 @constant      MTPackagingStateCancelled Packaging has been cancelled.
 @constant      MTPackagingStateComplete The packaging process has been completed.
*/
typedef enum {
    MTPackagingStateWaiting          = 0,
    MTPackagingStatePKGBuild         = 1,
    MTPackagingStateNotarizing       = 2,
    MTPackagingStateCopyPKG          = 3,
    MTPackagingStatePKGBuildFailed   = 4,
    MTPackagingStateNotarizingFailed = 5,
    MTPackagingStateCopyPKGFailed    = 6,
    MTPackagingStateCancelled        = 7,
    MTPackagingStateComplete         = 8
} MTPackagingState;

/*!
 @property      name
 @abstract      A property to store the name of the task.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *name;

/*!
 @property      userInfo
 @abstract      A property to store arbitrary information associated with the package.
 @discussion    The value of this property is NSDictionary.
*/
@property (nonatomic, strong, readwrite) NSDictionary *userInfo;

/*!
 @property      totalUnitCount
 @abstract      A property to store the total number of work units for the package.
 @discussion    The value of this property is NSUInteger.
*/
@property (assign) NSUInteger totalUnitCount;

/*!
 @property      completedUnitCount
 @abstract      A read-only property that returns the number of completed work units for the package.
 @discussion    The value of this property is NSUInteger.
*/
@property (readonly) NSUInteger completedUnitCount;

/*!
 @property      state
 @abstract      A property to store the current state of the packaging process.
 @discussion    The value of this property is MTPackagingState.
*/
@property (assign) MTPackagingState state;

/*!
 @property      error
 @abstract      A property that returns the underlying error (if any) that occurred during packaging.
 @discussion    The value of this property is NSError.
*/
@property (nonatomic, strong, readonly) NSError *error;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithTaskName:totalUnitCount: instead.
*/
- (id)init NS_UNAVAILABLE;

/*!
 @method        initWithTaskName:totalUnitCount:
 @abstract      Initializes a MTPackagingProgress object with the given task name and total number or work units.
 @param         name The task name.
 @param         count The total number of work units for this task.
 @discussion    Returns an initialized MTPackagingProgress object.
 */
- (id)initWithTaskName:(NSString *)name totalUnitCount:(NSInteger)count NS_DESIGNATED_INITIALIZER;

/*!
 @method        setCompletedUnitCount:notify:
 @abstract      Sets the number of completet work units to the given value and optionally sends
 out a notification with name kMTNotificationNameProgressUpdate to inform other processes.
 @param         count The number of completed work units for this task.
 @param         notify A boolean specifying if a notification should be sent or not.
 */
- (void)setCompletedUnitCount:(NSUInteger)count notify:(BOOL)notify;

/*!
 @method        cancelWithState:error:notify:
 @abstract      Cancels progress tracking and optionally sends out a notification with name
 kMTNotificationNameProgressUpdate to inform other processes.
 @param         state The current state of the packaging process.
 @param         error The error that lead to cancelling the packaging process.
 @param         notify A boolean specifying if a notification should be sent or not.
 */
- (void)cancelWithState:(MTPackagingState)state error:(NSError*)error notify:(BOOL)notify;

/*!
 @method        unitsRemaining
 @abstract      Returns the remaining number of work units.
 */
- (NSInteger)unitsRemaining;

/*!
 @method        fractionCompleted
 @abstract      Returns the fraction of the work units that has been completed.
 */
- (double)fractionCompleted;

/*!
 @method        localizedStateString
 @abstract      Returns a string that contains a localized text describing the current state of the packaging process.
 */
- (NSString*)localizedStateString;

/*!
 @method        errorDescription
 @abstract      Returns a text description for the error stored in the error property or nil, if no error description is available.
 */
- (NSString*)errorDescription;

@end
