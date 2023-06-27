/*
     MTNotarizeController.m
     Copyright 2023 SAP SE
     
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

#import "MTNotarizeController.h"
#import "MTNotarization.h"
#import "Constants.h"

@interface MTNotarizeController ()
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@end

@implementation MTNotarizeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // start the progress indicator's animation
    [_progressIndicator startAnimation:nil];
    
    NSString *teamID = [[NSUserDefaults standardUserDefaults] stringForKey:kMTDefaultsTeamID];
                                
    [MTNotarization notarizePackageAtURL:_packageURL
                    usingKeychainProfile:[kMTCredentialsPrefix stringByAppendingString:teamID]
                       completionHandler:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // close the progress sheet
            [NSApp endSheet:[[self view] window]];
            
            NSAlert *theAlert = [[NSAlert alloc] init];
            
            if (error) {
                [theAlert setMessageText:NSLocalizedString(@"notarizeFailedMessageTitle", nil)];
                [theAlert setInformativeText:NSLocalizedString(@"notarizeFailedMessageText", nil)];
            } else {
                [theAlert setMessageText:NSLocalizedString(@"notarizeSuccessMessageTitle", nil)];
                [theAlert setInformativeText:NSLocalizedString(@"notarizeSuccessMessageText", nil)];
            }
            
            [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
            [theAlert setAlertStyle:(error) ? NSAlertStyleCritical : NSAlertStyleInformational];
            [theAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
                [self dismissController:nil];
            }];

        });
    }];
    
}

@end
