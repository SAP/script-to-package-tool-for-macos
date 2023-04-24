/*
     MTNotarization.h
     Copyright 2022-2023 SAP SE
     
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
 @abstract This class contains convenience methods for notarizing macOS installer packages.
 */

@interface MTNotarization : NSObject

/*!
 @method        installCommandLineTools
 @abstract      Asks macOS to install the Command Line Tools for Xcode.
 @discussion    Runs @c xcode-select with the @c --install argument to trigger the installation of the Command Line Tools for Xcode.
 */
+ (void)installCommandLineTools;

/*!
 @method        checkForNotarytoolWithCompletionHandler:
 @abstract      Checks if @c notarytool exists.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c xcrun with the @c notarytool @c --version arguments to check if @c notarytool is available.
 */
+ (void)checkForNotarytoolWithCompletionHandler:(void (^) (BOOL exists))completionHandler;

/*!
 @method        storeNotarizationCredentialsForTeamID:account:password:completionHandler:
 @abstract      Stores the given credentials in the user's keychain.
 @param         teamID The developer team id.
 @param         account An Apple ID associated with the given developer team.
 @param         password An app-specific password associated with the given Apple ID.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c xcrun with the @c notarytool @c store-credentials arguments to save authentication credentials for the Apple notary service to the user's keychain.
 */
+ (void)storeNotarizationCredentialsForTeamID:(NSString*)teamID
                                      account:(NSString*)account
                                     password:(NSString*)password
                            completionHandler:(void (^) (BOOL success))completionHandler;

/*!
 @method        existsKeychainProfile:completionHandler:
 @abstract      Checks if saved credentials with the given profile name exist in the user's keychain.
 @param         profileName The name of the profle.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c xcrun with the @c notarytool @c info arguments together with the given profile name and a dummy submission id to check if the profile exists in the user's keychain.
 */
+ (void)existsKeychainProfile:(NSString*)profileName
            completionHandler:(void (^) (BOOL exists))completionHandler;

/*!
 @method        notarizePackageAtURL:usingKeychainProfile:completionHandler:
 @abstract      Submits the macOS installer package located at the given url to the Apple Notary Service. The given
 profile from the user's keychain is used for authentication.
 @param         url A file url specifying the storage location of the installer package.
 @param         profileName The name of the keychain profile.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c xcrun with the @c notarytool @c info arguments together with the given profile name and a dummy submission id to check if the profile exists in the user's keychain.
 */
+ (void)notarizePackageAtURL:(NSURL*)url
        usingKeychainProfile:(NSString*)profileName
           completionHandler:(void (^) (NSError *error))completionHandler;

/*!
 @method        checkNotarizationOfPackageAtURL:completionHandler:
 @abstract      Checks the signature and notarization of the given package.
 @param         url A file url specifying the storage location of the installer package.
 @param         completionHandler The completion handler to call when the request is complete.
 @discussion    Runs @c spctl and @c pkgutil @c to check if the package has been signed and notarized and if the package signature has been expired or not.
 */
+ (void)checkNotarizationOfPackageAtURL:(NSURL*)url
                      completionHandler:(void (^) (BOOL isSigned, BOOL isExpired, BOOL isNotarized, NSString *developerTeam))completionHandler;

@end
