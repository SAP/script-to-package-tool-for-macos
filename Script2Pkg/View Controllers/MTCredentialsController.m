/*
     MTCredentialsController.m
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

#import "MTCredentialsController.h"
#import "MTDeveloperIdentity.h"
#import "MTNotarization.h"
#import "Constants.h"

@interface MTCredentialsController ()
@property (weak) IBOutlet NSTextField *dialogBoxText;
@property (weak) IBOutlet NSTextField *appleIDTextField;
@property (weak) IBOutlet NSTextField *appPasswordTextField;
@property (weak) IBOutlet NSTextField *appSpecificPWText;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSLayoutConstraint *accountErrorHeight;

@property (nonatomic, strong, readwrite) NSString *teamID;
@property (assign) BOOL verifyingCredentials;
@end

@implementation MTCredentialsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // get the selected team id
    _teamID = [[NSUserDefaults standardUserDefaults] stringForKey:kMTDefaultsTeamID];
    
    [_dialogBoxText setStringValue:[NSString localizedStringWithFormat:NSLocalizedString(@"credentialsDialogText", nil), _teamID]];
    [_accountErrorHeight setConstant:0];
    
    // make the link in our text field clickable
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:[_appSpecificPWText attributedStringValue]];
        
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *allMatches = [linkDetector matchesInString:[finalString string] options:0 range:NSMakeRange(0, [[finalString string] length])];
    
    for (NSTextCheckingResult *match in [allMatches reverseObjectEnumerator]) {
        [finalString addAttribute:NSLinkAttributeName value:[match URL] range:[match range]];
    }
   
    [_appSpecificPWText setAttributedStringValue:finalString];
}

- (IBAction)closeWindow:(id)sender
{
    if ([sender tag] == 1) {
        
        [[[self view] window] makeFirstResponder:nil];

        self.verifyingCredentials = YES;
        [_accountErrorHeight setConstant:0];
        [_continueButton setEnabled:NO];
        
        // try to store the credentials
        [MTNotarization storeNotarizationCredentialsForTeamID:_teamID
                                                      account:[_appleIDTextField stringValue]
                                                     password:[_appPasswordTextField stringValue]
                                            completionHandler:^(BOOL success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (success) {
                    
                    // set notarization
                    [[NSUserDefaults standardUserDefaults] setBool:success forKey:kMTDefaultsPackageNotarize];
                    
                    // remove the team id from invalidated credentials array (if needed)
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    NSArray *invalidatedCredentials = [userDefaults valueForKey:kMTDefaultsInvalidatedCredentials];
                    
                    if ([invalidatedCredentials containsObject:self->_teamID]) {
                        
                        if ([invalidatedCredentials count] > 1) {
                            
                            NSMutableArray *mutableCredentials = [invalidatedCredentials mutableCopy];
                            [mutableCredentials removeObject:self->_teamID];
                            [userDefaults setValue:mutableCredentials forKey:kMTDefaultsInvalidatedCredentials];
                            
                        } else {
                            
                            [userDefaults removeObjectForKey:kMTDefaultsInvalidatedCredentials];
                        }
                    }
                    
                    [self dismissController:self];
                    
                } else {
                    
                    self.verifyingCredentials = NO;
                    [self->_accountErrorHeight setConstant:26];
                    [self->_continueButton setEnabled:YES];
                }
                
            });
        }];
        
    } else {

        // set notarization
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kMTDefaultsPackageNotarize];
        [self dismissController:self];
    }
}

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    if ([[_appleIDTextField stringValue] length] > 0 && [[_appPasswordTextField stringValue] length] > 0) {
        [_continueButton setEnabled:YES];
    } else {
        [_continueButton setEnabled:NO];
    }
    
    if ([_accountErrorHeight constant] > 0) { [_accountErrorHeight setConstant:0]; }
}

@end
