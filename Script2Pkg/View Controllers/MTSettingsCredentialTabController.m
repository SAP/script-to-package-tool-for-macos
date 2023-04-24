/*
     MTSettingsCredentialTabController.m
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

#import "MTSettingsCredentialTabController.h"
#import "MTDeveloperIdentity.h"
#import "Constants.h"

@interface MTSettingsCredentialTabController ()

@end

@implementation MTSettingsCredentialTabController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)invalidateCredentials:(id)sender
{
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert setMessageText:NSLocalizedString(@"invalidateCredentialsMessageTitle", nil)];
    [theAlert setInformativeText:NSLocalizedString(@"invalidateCredentialsMessageText", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"invalidateButton", nil)];
    [theAlert addButtonWithTitle:NSLocalizedString(@"cancelButton", nil)];
    [theAlert setAlertStyle:NSAlertStyleCritical];
    [theAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == NSAlertFirstButtonReturn) {
            
            // invalidate all credentials
            NSMutableArray *invalidatedCredentials = [[NSMutableArray alloc] init];
            NSArray *allDevIdentities = [MTDeveloperIdentity validIdentitiesOfType:MTDeveloperIdentityTypeInstaller];
            
            for (id identityRef in allDevIdentities) {
                        
                MTDeveloperIdentity *identity = [[MTDeveloperIdentity alloc] initWithIdentity:(__bridge SecIdentityRef)(identityRef)];
                NSString *teamID = [identity teamID];
                if (teamID) { [invalidatedCredentials addObject:teamID]; }
            }
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setValue:invalidatedCredentials forKey:kMTDefaultsInvalidatedCredentials];
            [userDefaults setBool:NO forKey:kMTDefaultsPackageNotarize];
        }
    }];
}

@end
