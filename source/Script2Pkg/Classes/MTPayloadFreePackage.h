/*
     MTPayloadFreePackage.h
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

#import "MTPackagingProgress.h"

/*!
 @abstract This class contains convenience methods for building macOS installer packages.
 */

@interface MTPayloadFreePackage : NSObject

/*!
 @property      packageName
 @abstract      A property to store the name of the installer package (include file name extension).
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *packageName;

/*!
 @property      packageIdentifierPrefix
 @abstract      A property to store a prefix for the package identifier.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *packageIdentifierPrefix;

/*!
 @property      packageVersion
 @abstract      A property to store the package version.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *packageVersion;

/*!
 @property      scriptURL
 @abstract      A read-only property returning a file url specifying the script's storage location.
 @discussion    The value of this property is NSURL.
*/
@property (nonatomic, strong, readonly) NSURL *scriptURL;

/*!
 @property      signingIdentity
 @abstract      A property to store the name of the signing identity.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readwrite) NSString *signingIdentity;

/*!
 @property      outputDirectoryURL
 @abstract      A property to store the url of the output directory the package should be written to.
 @discussion    The value of this property is NSURL.
*/
@property (nonatomic, strong, readwrite) NSURL *outputDirectoryURL;

/*!
 @property      usesPrefixAsIdentifier
 @abstract      A property to specify if the package identifier prefix should be used as the full package identifier.
 @discussion    The value of this property is Boolean.
*/
@property (assign) BOOL usesPrefixAsIdentifier;

/*!
 @property      createPackageReceipt
 @abstract      A property to specify if the installer package should leave a receipt after installation.
 @discussion    The value of this property is Boolean.
*/
@property (assign) BOOL createPackageReceipt;

/*!
 @property      createDistribution
 @abstract      A property to specify if a distribution should be created instead of a component package .
 @discussion    The value of this property is Boolean.
*/
@property (assign) BOOL createDistribution;

/*!
 @property      notarizationTeamID
 @abstract      A read-only property returning the developer team id used for notarization.
 @discussion    The value of this property is NSString.
*/
@property (nonatomic, strong, readonly) NSString *notarizationTeamID;

/*!
 @property      packageURL
 @abstract      A read-only property returning the file url to the location where the package has been written to.
 @discussion    The value of this property is NSURL.
*/
@property (nonatomic, strong, readonly) NSURL *packageURL;

/*!
 @property      buildDirectoryURL
 @abstract      A read-only property returning the url of the temporary build directoy.
 @discussion    The value of this property is NSURL.
*/
@property (nonatomic, strong, readonly) NSURL *buildDirectoryURL;

/*!
 @property      packagingProgress
 @abstract      A read-only property returning the current state of the packaging process.
 @discussion    The value of this property is MTPackagingProgress.
*/
@property (nonatomic, strong, readonly) MTPackagingProgress *packagingProgress;

/*!
 @property      isDirectoryBased
 @abstract      A read-only property returning if the package is based on a single script or a scripts directory.
 @discussion    The value of this property is Boolean.
*/
@property (readonly) BOOL isDirectoryBased;

/*!
 @method        init
 @discussion    The init method is not available. Please use initWithScriptURL: instead.
*/
- (id)init NS_UNAVAILABLE;

/*!
 @method        initWithScriptURL:
 @abstract      Initializes a MTPayloadFreePackage object with the given script url.
 @param         url The file url specifying the script's storage location.
 @discussion    Returns an initialized MTPayloadFreePackage object.
 */
- (id)initWithScriptURL:(NSURL*)url NS_DESIGNATED_INITIALIZER;

/*!
 @method        initWithDirectoryURL:
 @abstract      Initializes a MTPayloadFreePackage object with the given directory url.
 @param         url The file url specifying the directory's storage location.
 @discussion    Returns an initialized MTPayloadFreePackage object.
 */
- (id)initWithDirectoryURL:(NSURL*)url;

/*!
 @method        setNotarizationTeamID:
 @abstract      Set the developer team id for notarization to the given value.
 @param         teamID The developer team id to be used for notarization.
 */
- (void)setNotarizationTeamID:(NSString *)teamID;

/*!
 @method        buildPackageWithCompletionHandler:
 @abstract      Build a macOS installer package from the MTPayloadFreePackage object.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c pkgbuild to build the package.
 */
- (void)buildPackageWithCompletionHandler:(void (^) (NSError *error))completionHandler;

/*!
 @method        notarizePackageWithCompletionHandler:
 @abstract      Notarizes a macOS installer package previously created from a MTPayloadFreePackage object.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c xcrun with the @c notarytool argument to submit the package to the Apple Notary Service.
 */
- (void)notarizePackageWithCompletionHandler:(void (^) (NSError *error))completionHandler;

/*!
 @method        movePackageByOverwritingExisting:completionHandler:
 @abstract      Moves a package previously created from a MTPayloadFreePackage object to its final storage location.
 @param         overwrite A boolean specifying if an existing package with the same name should be overwritten or
 if the new package should be renamed.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Moves the package to the outputDirectoryURL. The complete url to the package is provided to the
 completion handler. If an error occurs, the package url returns nil and an NSError object is provided to the completion handler.
 */
- (void)movePackageByOverwritingExisting:(BOOL)overwrite completionHandler:(void (^) (NSURL *packageURL, NSError *error))completionHandler;

/*!
 @method        cancelWithState:error:notify:
 @abstract      Cancels package creation and optionally sends out a notification with name
 kMTNotificationNameProgressUpdate to inform other processes.
 @param         state The current state of the packaging process.
 @param         error The error that lead to cancelling the packaging process.
 @param         notify A boolean specifying if a notification should be sent or not.
 */
- (void)cancelWithState:(MTPackagingState)state error:(NSError*)error notify:(BOOL)notify;

/*!
 @method        isMissingScript
 @abstract      Returns if the directory-based package misses scripts.
 @discussion    If the source directory of a directory-based package neither contains a file @b preinstall nor @b postinstall, this method
 returns YES. Otherwise returns NO. The method also returns NO for packages based on a single script.
 */
- (BOOL)isMissingScript;

/*!
 @method        signPackageAtURL:usingIdentity:completionHandler:
 @abstract      Signs the given installer package using the given identity.
 @param         url A file url specifying the storage location of the installer package.
 @param         identity The name of the identity to use for signing the package.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c productsign with the @c --sign argument to sign the package.
 */
+ (void)signPackageAtURL:(NSURL*)url usingIdentity:(NSString*)identity completionHandler:(void (^) (BOOL success))completionHandler;

@end

