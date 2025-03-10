/*
     MTDeveloperIdentity.h
     Copyright 2022-2025 SAP SE
     
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

@interface MTDeveloperIdentity : NSObject

/*!
 @enum          Developer Identity Type
 @abstract      Specifies a developer identity of type application or installer.
 @constant      MTDeveloperIdentityTypeApplication A "Developer ID Application" identity.
 @constant      MTDeveloperIdentityTypeInstaller A "Developer ID Installer" identity.
*/
typedef enum {
    MTDeveloperIdentityTypeApplication = 0,
    MTDeveloperIdentityTypeInstaller   = 1
} MTDeveloperIdentityType;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithIdentity: instead.
*/
- (id)init NS_UNAVAILABLE;

/*!
 @method        initWithIdentity:
 @abstract      Initializes a MTDeveloperIdentity object with a given identity object.
 @param         identity The identity object.
 @discussion    Returns an initialized MTDeveloperIdentity object.
 */
- (id)initWithIdentity:(SecIdentityRef)identity NS_DESIGNATED_INITIALIZER;

/*!
 @method        teamID
 @abstract      Returns the developer team id associated with the MTDeveloperIdentity object.
 @discussion    Returns a string containing the team id or nil, if an error occurred.
 */
- (NSString*)teamID;

/*!
 @method        teamName
 @abstract      Returns the developer team name associated with the MTDeveloperIdentity object.
 @discussion    Returns a string containing the team name or nil, if an error occurred.
 */
- (NSString*)teamName;

/*!
 @method        certificateName
 @abstract      Returns the common name of the signing certificate associated with the MTDeveloperIdentity object.
 @discussion    Returns a string containing the certificate's common name or nil, if an error occurred.
 */
- (NSString*)certificateName;

/*!
 @method        validIdentitiesOfType:
 @abstract      Returns an the valid identities of the given type.
 @param         type The type of the developer identity.
 @discussion    Returns an array of valid identity objects matching the given type. If no valid identities are found, an
 empty array is returned.
 */
+ (NSArray*)validIdentitiesOfType:(MTDeveloperIdentityType)type;

@end

