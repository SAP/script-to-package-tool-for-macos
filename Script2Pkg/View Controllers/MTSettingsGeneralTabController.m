/*
     MTSettingsGeneralTabController.m
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

#import "MTSettingsGeneralTabController.h"
#import "MTNotarization.h"
#import "Constants.h"

@interface MTSettingsGeneralTabController ()
@property (weak) IBOutlet NSTextField *toolsTextField;

@property (assign) BOOL developerToolsInstalled;
@end

@implementation MTSettingsGeneralTabController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // get notified if the developer tools have been installed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(devToolsInstallationHandler)
                                                 name:kMTNotificationNameToolsInstalled
                                               object:nil
    ];
}

- (void)devToolsInstallationHandler
{
    // remove our observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameToolsInstalled
                                                  object:nil
    ];
    
    // make sure our ui elements are updated
    dispatch_async(dispatch_get_main_queue(), ^{
        self.developerToolsInstalled = YES;
        [self.toolsTextField setStringValue:NSLocalizedString(@"commandLineToolsInstalledText", nil)];
    });
}

- (IBAction)setActivityWindowAlwaysOnTop:(id)sender
{
    NSButton *onTopCheckbox = (NSButton*)sender;
    
    if (onTopCheckbox) {

        for (NSWindow *aWindow in [NSApp windows]) {
    
            if ([[aWindow identifier] isEqualToString:@"corp.sap.Script2Pkg.ActivityWindow"]) {
                [aWindow setHidesOnDeactivate:([onTopCheckbox state] == NSControlStateValueOn) ? NO : YES];
                break;
            }
        }
    }
}

- (IBAction)installCommandLineTools:(id)sender
{
    [MTNotarization installCommandLineTools];
}

- (void)dealloc
{
    // remove our observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameToolsInstalled
                                                  object:nil
    ];
}

@end
