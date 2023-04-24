/*
     MTPayloadFreePackage.m
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

#import "MTPayloadFreePackage.h"
#import "MTNotarization.h"
#import "Constants.h"

@interface MTPayloadFreePackage ()
@property (nonatomic, strong, readwrite) NSURL *packageURL;
@property (nonatomic, strong, readwrite) NSURL *buildDirectoryURL;
@property (nonatomic, strong, readwrite) NSString *notarizationTeamID;
@property (nonatomic, strong, readwrite) MTPackagingProgress *packagingProgress;
@property (assign) NSInteger completedUnitCount;
@end

@implementation MTPayloadFreePackage

- (id)initWithScriptURL:(NSURL *)url
{
    self = [super init];
    
    if (self) {
        _scriptURL = url;
        
        NSString *scriptName = [[url lastPathComponent] stringByDeletingPathExtension];
        _packageName = [scriptName stringByAppendingString:@".pkg"];
        _outputDirectoryURL = [_scriptURL URLByDeletingLastPathComponent];
        _completedUnitCount = 0;
        
        _packagingProgress = [[MTPackagingProgress alloc] initWithTaskName:scriptName totalUnitCount:4];
    }
    
    return self;
}

- (NSURL*)createBuildDirectoryWithError:(NSError**)error
{
    NSURL *buildDirURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                                inDomain:NSUserDomainMask
                                                       appropriateForURL:_scriptURL
                                                                  create:YES
                                                                   error:error
    ];
    
    if (!*error) {
        
        NSURL *scriptsDirURL = [buildDirURL URLByAppendingPathComponent:@"scripts"];
        [[NSFileManager defaultManager] createDirectoryAtURL:scriptsDirURL
                                 withIntermediateDirectories:NO
                                                  attributes:nil
                                                       error:error
        ];
    }
    
    return (*error) ? nil : buildDirURL;
}

- (void)setNotarizationTeamID:(NSString *)teamID
{
    _notarizationTeamID = teamID;
    [_packagingProgress setTotalUnitCount:(teamID) ? 6 : 4];
}

- (NSError*)deleteBuildDirectory
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:_buildDirectoryURL error:&error];
    
    return error;
}

- (void)buildPackageWithCompletionHandler:(void (^) (NSError *error))completionHandler
{
    NSError *error = nil;
    [_packagingProgress setState:MTPackagingStatePKGBuild];
    [_packagingProgress setCompletedUnitCount:++_completedUnitCount notify:YES];
    
    if (_scriptURL) {
        
        // create the build directory
        _buildDirectoryURL = [self createBuildDirectoryWithError:&error];

        if (_buildDirectoryURL) {
            
            NSURL *scriptsDirURL = [_buildDirectoryURL URLByAppendingPathComponent:@"scripts"];
            
            // copy the postinstall script to the temp directory and rename the script
            [[NSFileManager defaultManager] copyItemAtURL:_scriptURL
                                                    toURL:[scriptsDirURL URLByAppendingPathComponent:@"postinstall"]
                                                    error:&error];
            
            if (!error) {
                
                // set the launch arguments
                NSString *packageIdentifier = (_packageIdentifierPrefix) ? _packageIdentifierPrefix : kMTPackageIdentifierPrefix;
                if (!_usesPrefixAsIdentifier) { packageIdentifier = [packageIdentifier stringByAppendingFormat:@".%@", [[NSUUID UUID] UUIDString]]; }

                NSMutableArray *launchArguments = [NSMutableArray arrayWithObjects:
                                                   @"--identifier",
                                                   packageIdentifier,
                                                   @"--version",
                                                   ([_packageVersion length] > 0) ? _packageVersion : @"1.0.0",
                                                   @"--scripts",
                                                   [scriptsDirURL path],
                                                   nil
                ];
                
                // if the user needs a package receipt, we have
                //  to build the package in a different way
                if (_createPackageReceipt) {
                    
                    NSURL *emptyDirURL = [_buildDirectoryURL URLByAppendingPathComponent:@"empty"];
                    [[NSFileManager defaultManager] createDirectoryAtURL:emptyDirURL
                                             withIntermediateDirectories:NO
                                                              attributes:nil
                                                                   error:nil
                    ];
                    
                    [launchArguments addObject:@"--root"];
                    [launchArguments addObject:[emptyDirURL path]];
                    
                } else {
                    
                    [launchArguments addObject:@"--nopayload"];
                }

                // add signing information
                if (_signingIdentity) {
                    [launchArguments addObject:@"--sign"];
                    [launchArguments addObject:_signingIdentity];
                }
                    
                // add the output path
                _packageURL = [_buildDirectoryURL URLByAppendingPathComponent:_packageName];
                [launchArguments addObject:[_packageURL path]];

                NSTask *pkgbuildTask = [[NSTask alloc] init];
                [pkgbuildTask setExecutableURL:[NSURL fileURLWithPath:kMTpkgbuildPath]];
                [pkgbuildTask setArguments:launchArguments];
                [pkgbuildTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
                [pkgbuildTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
                [pkgbuildTask launch];
                [pkgbuildTask waitUntilExit];
                
                if ([pkgbuildTask terminationStatus] != 0) {

                    NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Package creation failed!", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
                    _packageURL = nil;
                    
                    // delete the build directory
                    [self deleteBuildDirectory];
                    
                } else {
                    [_packagingProgress setCompletedUnitCount:++_completedUnitCount notify:YES];
                }

            }
        }
        
    } else {
        
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Script url has not been specified", NSLocalizedDescriptionKey, nil];
        error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
    }
    
    if (completionHandler) { completionHandler(error); }
}

- (void)notarizePackageWithCompletionHandler:(void (^) (NSError *error))completionHandler
{
    NSError *error = nil;
    [_packagingProgress setState:MTPackagingStateNotarizing];
    [_packagingProgress setCompletedUnitCount:++_completedUnitCount notify:YES];

    if (_packageURL) {
        
        if (_notarizationTeamID) {

            [MTNotarization notarizePackageAtURL:_packageURL
                            usingKeychainProfile:[@"Script2Pkg." stringByAppendingString:_notarizationTeamID]
                               completionHandler:^(NSError *error) {
                
                if (!error) { [self->_packagingProgress setCompletedUnitCount:++self->_completedUnitCount notify:YES]; }
                if (completionHandler) { completionHandler(error); }
            }];
            
        } else {
            
            NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"No team id specified for notarization", NSLocalizedDescriptionKey, nil];
            error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
            if (completionHandler) { completionHandler(error); }
        }
        
    } else {
        
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Package has not been built yet", NSLocalizedDescriptionKey, nil];
        error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
        if (completionHandler) { completionHandler(error); }
    }
}

- (void)movePackageByOverwritingExisting:(BOOL)overwrite completionHandler:(void (^) (NSURL *packageURL, NSError *error))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSError *error = nil;
        NSURL *finalPackageURL = nil;
        
        [self->_packagingProgress setState:MTPackagingStateCopyPKG];
        [self->_packagingProgress setCompletedUnitCount:++self->_completedUnitCount notify:YES];
    
        if (self->_packageURL && self->_outputDirectoryURL) {
        
            BOOL isDirectory = NO;
            finalPackageURL = [self->_outputDirectoryURL URLByAppendingPathComponent:self->_packageName];
            
            // the file already exists ...
            if ([[NSFileManager defaultManager] fileExistsAtPath:[finalPackageURL path] isDirectory:&isDirectory] && !isDirectory) {
                
                if (overwrite) {
                    
                    // delete the file
                    [[NSFileManager defaultManager] removeItemAtURL:finalPackageURL
                                                              error:&error
                    ];
                    
                } else {
                    
                    // rename the new package
                    NSInteger counter = 2;
                    NSString *newPackageName = nil;
                    
                    while ([[NSFileManager defaultManager] fileExistsAtPath:[finalPackageURL path] isDirectory:&isDirectory] && !isDirectory && counter < 1000) {
                        
                        newPackageName = [[self->_packageName stringByDeletingPathExtension] stringByAppendingFormat:@" %ld.%@", (long)counter++, [self->_packageName pathExtension]];
                        finalPackageURL = [self->_outputDirectoryURL URLByAppendingPathComponent:newPackageName];
                    }
                    
                    [self setPackageName:newPackageName];
                }
            }
            
            if (!error) {
                                
                [[NSFileManager defaultManager] moveItemAtURL:self->_packageURL
                                                        toURL:finalPackageURL
                                                        error:&error
                ];
            }
            
            if (!error) {
                
                // update the package's url
                [self setPackageURL:finalPackageURL];
                [self->_packagingProgress setUserInfo:[NSDictionary dictionaryWithObject:[[self->_outputDirectoryURL URLByAppendingPathComponent:self->_packageName] absoluteString] forKey:kMTNotificationKeyPackagePath]];
                
                // delete the build folder
                error = [self deleteBuildDirectory];
                
            } else {
                
                finalPackageURL = nil;
            }
                        
        } else {
            
            NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Package has not been built yet", NSLocalizedDescriptionKey, nil];
            error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
        }
        
        if (!error) {
            [self->_packagingProgress setState:MTPackagingStateComplete];
            [self->_packagingProgress setCompletedUnitCount:++self->_completedUnitCount notify:YES];
        }
        
        if (completionHandler) { completionHandler(finalPackageURL, error); }
    });
}

- (void)cancelWithState:(MTPackagingState)state error:(NSError*)error notify:(BOOL)notify
{
    _packageURL = nil;
    [self deleteBuildDirectory];
    
    [_packagingProgress cancelWithState:state error:error notify:notify];
}



@end
