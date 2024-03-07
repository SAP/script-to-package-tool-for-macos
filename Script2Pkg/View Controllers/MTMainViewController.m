/*
     MTMainViewController.m
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

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MTMainViewController.h"
#import "Constants.h"
#import "MTDeveloperIdentity.h"
#import "MTPayloadFreePackage.h"
#import "MTNotarization.h"
#import "MTProgressController.h"
#import "MTSignatureValidationController.h"
#import "MTNotarizeController.h"

@interface MTMainViewController ()
@property (weak) IBOutlet NSArrayController *identitiesArrayController;
@property (weak) IBOutlet NSButton *signingCheckbox;
@property (weak) IBOutlet NSButton *notarizingCheckbox;

@property (nonatomic, strong, readwrite) NSMutableArray *devIdentitiesArray;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (assign) BOOL enableNotarization;
@property (assign) BOOL verifyingCredentials;
@end

@implementation MTMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _userDefaults = [NSUserDefaults standardUserDefaults];
    _devIdentitiesArray = [[NSMutableArray alloc] init];
    
    [_userDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kMTDefaultsPackageSign,
                                     [NSNumber numberWithInteger:0], kMTDefaultsExistingPKGHandling,
                                     [NSNumber numberWithBool:YES], kMTDefaultsSkipIfMissingScript,
                                     nil]];
    
    // get all developer identities from login keychain
    NSArray *allDevIdentities = [MTDeveloperIdentity validIdentitiesOfType:MTDeveloperIdentityTypeInstaller];

    if ([allDevIdentities count] > 0) {
        
        // check for notarytool
        [MTNotarization checkForNotarytoolWithCompletionHandler:^(BOOL exists) {

            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.enableNotarization = exists;
                
                if (exists) {
                    
                    // send a notification
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameToolsInstalled
                                                                        object:nil
                                                                      userInfo:nil
                    ];
                    
                    // if notarization is enabled, we check if we have working credentials
                    if ([self->_userDefaults boolForKey:kMTDefaultsPackageNotarize]) {
                        
                        [self checkCredentialsForNotarizationWithUserInteraction:NO completionHandler:^(BOOL success) {
                            
                            if (!success) {
                                
                                // show an alert so the user is informed why
                                // notarization has been disabled
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    NSAlert *theAlert = [[NSAlert alloc] init];
                                    [theAlert setMessageText:NSLocalizedString(@"invalidCredentialsMessageTitle", nil)];
                                    [theAlert setInformativeText:NSLocalizedString(@"invalidCredentialsMessageText", nil)];
                                    [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                                    [theAlert setAlertStyle:NSAlertStyleCritical];
                                    [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
                                });
                            }
                        }];
                    }
                    
                } else {
                    
                    // disable the notarization checkbox
                    [self->_notarizingCheckbox setToolTip:NSLocalizedString(@"notarytoolMissingTooltip", nil)];
                    [self->_userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
                    
                    // monitor kMTPackageReceiptsPath so we get informed whenever a new
                    // package (hopefully the developer tools) has been installed
                    int receiptsPath = open(kMTPackageReceiptsPath, O_EVTONLY);

                    dispatch_source_t source = dispatch_source_create(
                                                                      DISPATCH_SOURCE_TYPE_VNODE,
                                                                      receiptsPath,
                                                                      DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_DELETE,
                                                                      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                                                      );
                    
                    dispatch_source_set_event_handler(source, ^
                    {
                        [MTNotarization checkForNotarytoolWithCompletionHandler:^(BOOL exists) {
                            
                            if (exists) {
                                
                                dispatch_source_cancel(source);
                                
                                // re-enable the notarization checkbox
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.enableNotarization = YES;
                                    [self->_notarizingCheckbox setToolTip:nil];
                                });
                                
                                // send a notification
                                [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameToolsInstalled
                                                                                    object:nil
                                                                                  userInfo:nil
                                ];
                            }
                        }];
                    });

                    dispatch_source_set_cancel_handler(source, ^
                    {
                        int receiptsPath = (int)dispatch_source_get_handle(source);
                        close(receiptsPath);
                    });
                    
                    dispatch_resume(source);
                }
            });
        }];
        
        NSMutableArray *identityDictionaries = [[NSMutableArray alloc] init];
        
        for (id identityRef in allDevIdentities) {
            
            MTDeveloperIdentity *identity = [[MTDeveloperIdentity alloc] initWithIdentity:(__bridge SecIdentityRef)(identityRef)];
            NSString *teamName = [identity teamName];
            NSString *teamID = [identity teamID];
            NSString *certName = [identity certificateName];
            
            if (teamName && teamID && certName) {
                
                NSDictionary *identityDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                              teamName, kMTDeveloperTeamName,
                                              teamID, kMTDeveloperTeamID,
                                              certName, kMTDeveloperCertName,
                                              [teamName stringByAppendingFormat:@" (%@)", teamID], kMTDeveloperTeamDisplayName,
                                              nil
                ];
                
                [identityDictionaries addObject:identityDict];
            }
        }
        
        // add the identities (sorted by name)
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kMTDeveloperTeamDisplayName
                                                                                          ascending:YES
                                                                                           selector:@selector(localizedCaseInsensitiveCompare:)]];
        NSArray *sortedIdentities = [identityDictionaries sortedArrayUsingDescriptors:sortDescriptors];
        [_identitiesArrayController addObjects:sortedIdentities];
        
        // select the previously selected menu entry
        NSInteger selectionIndex = 0;
        NSString *selectedEntry = [_userDefaults stringForKey:kMTDefaultsTeamID];
        
        if (selectedEntry) {
            NSArray *filteredArray = [sortedIdentities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", selectedEntry]];
            NSDictionary *teamDict = [filteredArray firstObject];
            selectionIndex = [[_identitiesArrayController arrangedObjects] indexOfObject:teamDict];
        }
        
        if (!selectedEntry || selectionIndex == NSNotFound) {
            
            [_identitiesArrayController setSelectionIndex:0];
            [self setDevelopmentTeam:nil];
            
        } else {
            
            [_identitiesArrayController setSelectionIndex:selectionIndex];
        }
        
    } else {
        
        [_signingCheckbox setToolTip:NSLocalizedString(@"noSigningIdentityTooltip", nil)];
        [_notarizingCheckbox setToolTip:NSLocalizedString(@"signingDisabledTooltip", nil)];
        [_userDefaults setBool:NO forKey:kMTDefaultsPackageSign];
        [_userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
    }
    
    // get notified if the user dropped a script to the app icon (in Finder or Dock)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(importFiles:)
                                                 name:kMTNotificationNameFileImport
                                               object:nil
    ];
}

#pragma mark IBActions

- (IBAction)setDevelopmentTeam:(id)sender
{
    NSDictionary *selectedDevelopmentTeam = [[self->_identitiesArrayController selectedObjects] firstObject];
    NSString *teamID = [selectedDevelopmentTeam valueForKey:kMTDeveloperTeamID];
    [_userDefaults setValue:teamID forKey:kMTDefaultsTeamID];
    [_userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
}

- (IBAction)setSigning:(id)sender
{
    // as a package must be signed for notarizing, we also uncheck
    // the notarizing checkbox if signing is disabled.
    if (![_userDefaults boolForKey:kMTDefaultsPackageSign]) {
        [_userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
    }
}

- (IBAction)setNotarization:(id)sender
{
    // if enabled, check if we have the credentials for the selected
    // development team already stored in keychain. Otherwise we ask
    // the user to enter the credentials and store them into keychain.
    if ([_notarizingCheckbox state] == NSControlStateValueMixed) {
        [self checkCredentialsForNotarizationWithUserInteraction:YES completionHandler:nil];
    }
}

- (IBAction)selectFiles:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setPrompt:NSLocalizedString(@"buildButton", nil)];
    [panel setMessage:NSLocalizedString(@"openDialogMessage", nil)];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setCanCreateDirectories:NO];
    [panel setAllowedContentTypes:[NSArray arrayWithObject:UTTypeShellScript]];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        
        if (result == NSModalResponseOK) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // call the progress sheet
                [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.ProgressSegue" sender:[self buildPackageArrayFromFileURLs:[panel URLs]]];
            });
        }
    }];
}

- (IBAction)signOrNotarizeExistingPackage:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    if ([sender tag] == 1000) {
        [panel setPrompt:NSLocalizedString(@"signButton", nil)];
        [panel setMessage:NSLocalizedString(@"signDialogMessage", nil)];
    } else if ([sender tag] == 2000) {
        [panel setPrompt:NSLocalizedString(@"notarizeButton", nil)];
        [panel setMessage:NSLocalizedString(@"notarizeDialogMessage", nil)];
    }
    
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanCreateDirectories:NO];
    [panel setAllowedContentTypes:[NSArray arrayWithObject:[UTType typeWithIdentifier:@"com.apple.installer-package-archive"]]];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        
        if (result == NSModalResponseOK) {
            
            NSURL *packageURL = [[panel URLs] firstObject];
                
            // check if the package is signed
            [MTNotarization checkNotarizationOfPackageAtURL:packageURL
                                          completionHandler:^(BOOL isSigned, BOOL isExpired, BOOL isNotarized, NSString *developerTeam) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // if the package is signed and the user wants to sign an existing
                    // package, we ask the user if the existing signature should be
                    // replaced.
                    
                    if ([sender tag] == 1000) {
                                                
                        if (isSigned) {
                            
                            NSAlert *theAlert = [[NSAlert alloc] init];
                            [theAlert setMessageText:NSLocalizedString(@"alreadySignedMessageTitle", nil)];
                            [theAlert setInformativeText:NSLocalizedString(@"alreadySignedMessageText", nil)];
                            [theAlert addButtonWithTitle:NSLocalizedString(@"replaceButton", nil)];
                            [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
                            [theAlert setAlertStyle:NSAlertStyleCritical];
                            [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {

                                if (returnCode == NSAlertFirstButtonReturn) {
                                    [self signPackageAtURL:packageURL completionHandler:^(BOOL success) {
                                        [self displayDialogWithSigningSuccess:success];
                                    }];
                                }
                            }];
                            
                        } else {
                            [self signPackageAtURL:packageURL completionHandler:^(BOOL success) {
                                [self displayDialogWithSigningSuccess:success];
                            }];
                        }
                        
                    } else {
                        
                        if (isExpired) {
                            
                            NSAlert *theAlert = [[NSAlert alloc] init];
                            [theAlert setMessageText:NSLocalizedString(@"expiredSignatureMessageTitle", nil)];
                            [theAlert setInformativeText:NSLocalizedString(@"expiredSignatureMessageText", nil)];
                            [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                            [theAlert setAlertStyle:NSAlertStyleCritical];
                            [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
                            
                        } else if (isNotarized) {
                            
                            NSAlert *theAlert = [[NSAlert alloc] init];
                            [theAlert setMessageText:NSLocalizedString(@"alreadyNotarizedMessageTitle", nil)];
                            [theAlert setInformativeText:NSLocalizedString(@"alreadyNotarizedMessageText", nil)];
                            [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
                            [theAlert setAlertStyle:NSAlertStyleCritical];
                            [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
                            
                        } else {
                            
                            // if the selected package is unsigned, we first sign it
                            // and then submit it to the Apple Notary Service
                            if (!isSigned) {
                                
                                [self signPackageAtURL:packageURL completionHandler:^(BOOL success) {
                                    
                                    if (success) {

                                        // call the progress sheet
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.NotarizationSegue" sender:packageURL];
                                        });
                                        
                                    } else {
                                        [self displayDialogWithSigningSuccess:success];
                                    }
                                }];
                                
                            } else {
                                
                                // call the progress sheet
                                [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.NotarizationSegue" sender:packageURL];
                            }
                        }
                    }
                });
            }];

        }
    }];
}

- (IBAction)validateSigning:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setPrompt:NSLocalizedString(@"validateButton", nil)];
    [panel setMessage:NSLocalizedString(@"validateDialogMessage", nil)];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanCreateDirectories:NO];
    [panel setAllowedContentTypes:[NSArray arrayWithObject:[UTType typeWithIdentifier:@"com.apple.installer-package-archive"]]];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        
        if (result == NSModalResponseOK) {
                
            dispatch_async(dispatch_get_main_queue(), ^{
            
                // call the validation sheet
                [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.ValidationSegue" sender:[[panel URLs] firstObject]];
                
            });
        }
    }];
}

- (void)importFiles:(NSNotification*)notification
{
    NSArray *filePaths = [[notification userInfo] objectForKey:kMTNotificationKeyImportFiles];
    NSMutableArray *fileURLs = [[NSMutableArray alloc] init];

    for (NSString *filePath in filePaths) {
        [fileURLs addObject:[NSURL fileURLWithPath:filePath]];
    }
    
    if ([fileURLs count] > 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // call the progress sheet
            [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.ProgressSegue" sender:[self buildPackageArrayFromFileURLs:fileURLs]];
        });
    }
}

#pragma mark Build MTPayloadFreePackage array

- (NSArray*)buildPackageArrayFromFileURLs:(NSArray*)fileURLs
{
    NSString *certificateName = nil;
    NSString *teamID = nil;

    if ([_userDefaults boolForKey:kMTDefaultsPackageSign]) {
        
        // get the signing certificate name
        NSDictionary *selectedObject = [[_identitiesArrayController selectedObjects] firstObject];
        certificateName = [selectedObject valueForKey:kMTDeveloperCertName];
        
        if ([_userDefaults boolForKey:kMTDefaultsPackageNotarize]) {
            
            // get the team id
            teamID = [_userDefaults stringForKey:kMTDefaultsTeamID];
        }
    }
    
    // get the custom output path (if configured)
    NSURL *outputDirectoryURL = [_userDefaults URLForKey:kMTDefaultsPackageOutputPath];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[outputDirectoryURL path] isDirectory:&isDirectory] || !isDirectory) {
        outputDirectoryURL = nil;
        [_userDefaults removeObjectForKey:kMTDefaultsPackageOutputPath];
    }
    
    // make sure the file urls are sorted by file name
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastPathComponent"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedStandardCompare:)
                                                        ]
    ];

    NSMutableArray *packageArray = [[NSMutableArray alloc] init];
    for (NSURL *url in [fileURLs sortedArrayUsingDescriptors:sortDescriptors]) {
        
        MTPayloadFreePackage *aPackage = nil;
        
        if ([url hasDirectoryPath]) {
            aPackage = [[MTPayloadFreePackage alloc] initWithDirectoryURL:url];
        } else {
            aPackage = [[MTPayloadFreePackage alloc] initWithScriptURL:url];
        }
        
        if (![aPackage isMissingScript] || ![_userDefaults boolForKey:kMTDefaultsSkipIfMissingScript]) {
            
            if (outputDirectoryURL) { [aPackage setOutputDirectoryURL:outputDirectoryURL]; }
            [aPackage setPackageIdentifierPrefix:[_userDefaults stringForKey:kMTDefaultsPackageIdentifierPrefix]];
            [aPackage setCreatePackageReceipt:[_userDefaults boolForKey:kMTDefaultsPackageCreateReceipts]];
            [aPackage setUsesPrefixAsIdentifier:[_userDefaults boolForKey:kMTDefaultsPackagePrefixIsIdentifier]];
            [aPackage setCreateDistribution:[_userDefaults boolForKey:kMTDefaultsCreateDistribution]];
            [aPackage setSigningIdentity:certificateName];
            [aPackage setNotarizationTeamID:teamID];
            
            NSString *packageVersion = nil;
            if ([_userDefaults boolForKey:kMTDefaultsPackageVersionUseScript]) {
                
                // check the script name for a version number
                NSString *packageName = [aPackage packageName];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[-_ ]([0-9]+.*)\\.pkg$"
                                                                                       options: NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
                NSArray *matches = [regex matchesInString:packageName options:0 range:NSMakeRange(0, [packageName length])];
                NSString *verionFromScriptName = [packageName substringWithRange:[[matches firstObject] rangeAtIndex:1]];
                if ([verionFromScriptName length] > 0) { packageVersion = verionFromScriptName; }
            }
            
            if ([[_userDefaults stringForKey:kMTDefaultsPackageVersion] length] > 0 && !packageVersion) {
                packageVersion = [_userDefaults stringForKey:kMTDefaultsPackageVersion];
            }
            
            if (packageVersion) { [aPackage setPackageVersion:packageVersion]; }
            [packageArray addObject:aPackage];
        }
    }
    
    return packageArray;
}

#pragma mark Sign existing package

- (void)signPackageAtURL:(NSURL*)url completionHandler:(void (^) (BOOL success))completionHandler
{
    NSDictionary *selectedIdentity = [[_identitiesArrayController selectedObjects] firstObject];
    NSString *certificateName = [selectedIdentity valueForKey:kMTDeveloperCertName];
    
    [MTPayloadFreePackage signPackageAtURL:url
                             usingIdentity:certificateName
                         completionHandler:^(BOOL success) {
        
        if (completionHandler) { completionHandler(success); }
    }];
}

- (void)displayDialogWithSigningSuccess:(BOOL)success
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSAlert *theAlert = [[NSAlert alloc] init];
        
        if (success) {
            [theAlert setMessageText:NSLocalizedString(@"signingSuccessMessageTitle", nil)];
            [theAlert setInformativeText:NSLocalizedString(@"signingSuccessMessageText", nil)];
        } else {
            [theAlert setMessageText:NSLocalizedString(@"signingFailedMessageTitle", nil)];
            [theAlert setInformativeText:NSLocalizedString(@"signingFailedMessageText", nil)];
        }
        
        [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
        [theAlert setAlertStyle:(success) ? NSAlertStyleInformational : NSAlertStyleCritical];
        [theAlert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
    });
}

#pragma mark Check credentials for notarization

- (void)checkCredentialsForNotarizationWithUserInteraction:(BOOL)interaction
                                         completionHandler:(void (^) (BOOL success))completionHandler
{
    // we disable some interface elements during verification
    self.verifyingCredentials = YES;
            
    // get the team id
    NSString *teamID = [_userDefaults stringForKey:kMTDefaultsTeamID];
    
    if (teamID) {
        
        NSArray *invalidatedCredentials = [_userDefaults valueForKey:kMTDefaultsInvalidatedCredentials];
        
        // if the credentials have been invalidated, we don't need to check them
        if ([invalidatedCredentials containsObject:teamID]) {
            
            self.verifyingCredentials = NO;
            [self->_userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
            if (completionHandler) { completionHandler(NO); }
                
            if (interaction) {
                [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.CredentialSegue" sender:nil];
            }
            
        } else {
            
            [MTNotarization existsKeychainProfile:[kMTCredentialsPrefix stringByAppendingString:teamID]
                                completionHandler:^(BOOL exists) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.verifyingCredentials = NO;
                    [self->_userDefaults setBool:exists forKey:kMTDefaultsPackageNotarize];
                    if (completionHandler) { completionHandler(exists); }
                    
                    if (!exists && interaction) {
                        [self performSegueWithIdentifier:@"corp.sap.Script2Pkg.CredentialSegue" sender:nil];
                    }
                    
                });
            }];
        }
        
    } else if (completionHandler) { completionHandler(NO); }
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"corp.sap.Script2Pkg.ProgressSegue"] && [sender isKindOfClass:[NSArray class]]) {

        MTProgressController *destController = [segue destinationController];
        [destController setPackages:(NSArray*)sender];
        
    } else if ([[segue identifier] isEqualToString:@"corp.sap.Script2Pkg.ValidationSegue"] && [sender isKindOfClass:[NSURL class]]) {
        
        MTSignatureValidationController *destController = [segue destinationController];
        [destController setPackageURL:(NSURL*)sender];
    
    } else if ([[segue identifier] isEqualToString:@"corp.sap.Script2Pkg.NotarizationSegue"] && [sender isKindOfClass:[NSURL class]]) {
        
        MTNotarizeController *destController = [segue destinationController];
        [destController setPackageURL:(NSURL*)sender];
    }
}

#pragma mark NSMenuItemValidation

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL enableItem = [[[self view] window] isVisible];
        
    if (([item tag] == 1000 && ![_userDefaults boolForKey:kMTDefaultsPackageSign]) || ([item tag] == 2000 && ![_userDefaults boolForKey:kMTDefaultsPackageNotarize])) {
        enableItem = NO;
    }
    
    return enableItem;
}

@end



