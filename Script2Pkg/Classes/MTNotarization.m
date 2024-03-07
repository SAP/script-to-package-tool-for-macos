/*
     MTNotarization.m
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

#import "MTNotarization.h"
#import "Constants.h"

@implementation MTNotarization

+ (void)installCommandLineTools
{
    [NSTask launchedTaskWithLaunchPath:kMTxcodeselectPath
                             arguments:[NSArray arrayWithObject:@"--install"]
    ];
}

+ (void)checkForNotarytoolWithCompletionHandler:(void (^) (BOOL exists))completionHandler
{
    NSTask *notarizeTask = [[NSTask alloc] init];
    [notarizeTask setExecutableURL:[NSURL fileURLWithPath:kMTxcrunPath]];
    [notarizeTask setArguments:[NSArray arrayWithObjects:
                                @"notarytool",
                                @"--version",
                                nil
                               ]
    ];
    [notarizeTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [notarizeTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    [notarizeTask setTerminationHandler:^(NSTask* task){
        
        BOOL success = ([task terminationStatus] == 0) ? YES : NO;
        if (completionHandler) { completionHandler(success); }
    }];
    
    [notarizeTask launch];
}

+ (void)storeNotarizationCredentialsForTeamID:(NSString*)teamID account:(NSString*)account password:(NSString*)password completionHandler:(void (^) (BOOL success))completionHandler
{
    if (teamID && account && password) {
        
        NSTask *notarizeTask = [[NSTask alloc] init];
        [notarizeTask setExecutableURL:[NSURL fileURLWithPath:kMTxcrunPath]];
        [notarizeTask setArguments:[NSArray arrayWithObjects:
                                    @"notarytool",
                                    @"store-credentials",
                                    [kMTCredentialsPrefix stringByAppendingString:teamID],
                                    @"--team-id",
                                    teamID,
                                    @"--apple-id",
                                    account,
                                    @"--password",
                                    password,
                                    nil
                                   ]
        ];
        [notarizeTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [notarizeTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        [notarizeTask setTerminationHandler:^(NSTask* task){
            
            BOOL success = ([task terminationStatus] == 0) ? YES : NO;
            if (completionHandler) { completionHandler(success); }
            
        }];
        
        [notarizeTask launch];
        
    } else if (completionHandler) {
        
        completionHandler(NO);
    }
}

+ (void)existsKeychainProfile:(NSString*)profileName completionHandler:(void (^) (BOOL exists))completionHandler
{
    if (profileName) {
        
        NSTask *notarizeTask = [[NSTask alloc] init];
        [notarizeTask setExecutableURL:[NSURL fileURLWithPath:kMTxcrunPath]];
        [notarizeTask setArguments:[NSArray arrayWithObjects:
                                    @"notarytool",
                                    @"info",
                                    @"--keychain-profile",
                                    profileName,
                                    @"00000000-0000-0000-0000-000000000000",
                                    nil
                                   ]
        ];
        [notarizeTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        NSPipe *errorPipe = [[NSPipe alloc] init];
        [notarizeTask setStandardError:errorPipe];
        [notarizeTask setTerminationHandler:^(NSTask* task){
            
            BOOL success = NO;
            NSData *returnData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
            
            if (returnData) {
                NSString *consoleMsg = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                if (![consoleMsg containsString:@"password"]) { success = YES; }
            }
            
            if (completionHandler) { completionHandler(success); }
            
        }];
        
        [notarizeTask launch];
        
    } else if (completionHandler) {
        
        completionHandler(NO);
    }
}

+ (void)notarizePackageAtURL:(NSURL*)url usingKeychainProfile:(NSString*)profileName completionHandler:(void (^) (NSError *error))completionHandler
{
    if (profileName) {
        
        NSTask *notarizeTask = [[NSTask alloc] init];
        [notarizeTask setExecutableURL:[NSURL fileURLWithPath:kMTxcrunPath]];
        [notarizeTask setArguments:[NSArray arrayWithObjects:
                                    @"notarytool",
                                    @"submit",
                                    @"--wait",
                                    @"--keychain-profile",
                                    profileName,
                                    [url path],
                                    nil
                                   ]
        ];
        NSPipe *stdoutPipe = [[NSPipe alloc] init];
        [notarizeTask setStandardOutput:stdoutPipe];
        [notarizeTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        [notarizeTask setTerminationHandler:^(NSTask* task){
            
            NSError *error = nil;
            NSData *returnData = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
            
            if (returnData) {
                
                NSString *consoleMsg = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                NSRange range = [consoleMsg rangeOfString:@"status:.*Accepted" options:NSRegularExpressionSearch];
                
                if (range.location != NSNotFound) {
                    
                    // staple the ticket to the package
                    NSTask *stapleTask = [[NSTask alloc] init];
                    [stapleTask setExecutableURL:[NSURL fileURLWithPath:kMTxcrunPath]];
                    [stapleTask setArguments:[NSArray arrayWithObjects:
                                              @"stapler",
                                              @"staple",
                                              [url path],
                                              nil
                                             ]
                    ];
                    [stapleTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
                    [stapleTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
                    [stapleTask launch];
                    [stapleTask waitUntilExit];
                    
                    if ([stapleTask terminationStatus] != 0) {
                                        
                        NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Stapling failed", NSLocalizedDescriptionKey, nil];
                        error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
                    }
                    
                } else {
                    
                    NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Notarization failed", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
                }
                
            } else {
                
                NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Notarization failed", NSLocalizedDescriptionKey, nil];
                error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
            }
            
            if (completionHandler) { completionHandler(error); }
        }];
        
        [notarizeTask launch];

    } else if (completionHandler) {
        
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:@"Notarization failed! No keychain profile defined", NSLocalizedDescriptionKey, nil];
        NSError *error = [NSError errorWithDomain:kMTScript2PkgErrorDomain code:0 userInfo:errorDetail];
        
        completionHandler(error);
    }
}

+ (void)checkNotarizationOfPackageAtURL:(NSURL*)url completionHandler:(void (^) (BOOL isSigned, BOOL isExpired, BOOL isNotarized, NSString *developerTeam))completionHandler
{
    NSTask *checkTask = [[NSTask alloc] init];
    [checkTask setExecutableURL:[NSURL fileURLWithPath:kMTspctlPath]];
    [checkTask setArguments:[NSArray arrayWithObjects:
                             @"-a",
                             @"-vv",
                             @"-t",
                             @"install",
                             [url path],
                             nil
                            ]
    ];
    NSPipe *errorPipe = [[NSPipe alloc] init];
    [checkTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [checkTask setStandardError:errorPipe];
    [checkTask setTerminationHandler:^(NSTask* task){
        
        BOOL isSigned = NO;
        BOOL isExpired = NO;
        BOOL isNotarized = NO;
        NSString *devTeam = nil;
        
        NSData *returnData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        
        if (returnData) {
            
            NSString *consoleMsg = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)=(.+)"
                                                                                   options: NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            NSArray *matches = [regex matchesInString:consoleMsg options:0 range:NSMakeRange(0, [consoleMsg length])];
            
            for (NSTextCheckingResult *match in matches) {
                
                if ([match numberOfRanges] == 3) {
                    
                    NSString *optionName = [consoleMsg substringWithRange:[match rangeAtIndex:1]];
                    NSString *optionValue = [consoleMsg substringWithRange:[match rangeAtIndex:2]];
                    
                    if ([optionName isEqualToString:@"source"]) {
                        
                        if ([optionValue isEqualToString:@"Notarized Developer ID"]) {
                            
                            isNotarized = YES;
                            isSigned = YES;
                            
                        } else if (![optionValue isEqualToString:@"no usable signature"]) {
                            
                            isSigned = YES;
                        }
                        
                    } else if ([optionName isEqualToString:@"origin"]) {
                        
                        devTeam = optionValue;
                    }
                }
            }
            
            // check if the signing cert has been expired
            if (isSigned) {
                
                NSTask *certCheckTask = [[NSTask alloc] init];
                [certCheckTask setExecutableURL:[NSURL fileURLWithPath:kMTpkgutilPath]];
                [certCheckTask setArguments:[NSArray arrayWithObjects:@"--check-signature", [url path], nil]];
                NSPipe *stdoutPipe = [[NSPipe alloc] init];
                [certCheckTask setStandardOutput:stdoutPipe];
                [certCheckTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
                [certCheckTask launch];
                [certCheckTask waitUntilExit];
                
                NSData *returnData = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
                
                if (returnData) {
                    
                    NSString *consoleMsg = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                    NSRange range = [consoleMsg rangeOfString:@"Status:.*expired" options:NSRegularExpressionSearch];
                    if (range.location != NSNotFound) { isExpired = YES; }
                }
            }
        }
        
        if (completionHandler) { completionHandler(isSigned, isExpired, isNotarized, devTeam); }
    }];
    
    [checkTask launch];
}

@end
