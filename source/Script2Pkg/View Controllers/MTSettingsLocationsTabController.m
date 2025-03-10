/*
     MTSettingsLocationsTabController.m
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

#import "MTSettingsLocationsTabController.h"
#import "Constants.h"

@interface MTSettingsLocationsTabController ()
@property (weak) IBOutlet NSPopUpButton *packagePathButton;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@end

@implementation MTSettingsLocationsTabController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    // check if the user has selected a different output path
    // for the packages and update our popup button accordingly
    NSURL *outputURL = [_userDefaults URLForKey:kMTDefaultsPackageOutputPath];
    
    if (outputURL) {
        NSMenu *menu = [_packagePathButton menu];
        [menu insertItemWithTitle:[outputURL lastPathComponent] action:nil keyEquivalent:@"" atIndex:2];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:3];
        [_packagePathButton selectItemAtIndex:2];
    }
}

- (IBAction)setPackageLocation:(id)sender
{
    // the user choosed "Same as script"
    if ([_packagePathButton selectedTag] == 1000) {
        
        [_userDefaults removeObjectForKey:kMTDefaultsPackageOutputPath];
        [self resetMenu];
        
    // the user choosed "Other…"
    } else if ([_packagePathButton selectedTag] == 1002) {
        
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:NO];
        [panel setPrompt:NSLocalizedString(@"selectButton", nil)];
        [panel setCanChooseDirectories:YES];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanCreateDirectories:YES];
        [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
            
            if (result == NSModalResponseOK) {
                
                NSURL *outputURL = [[panel URLs] firstObject];
                [self->_userDefaults setURL:outputURL forKey:kMTDefaultsPackageOutputPath];
                [self resetMenu];
                
                NSMenu *menu = [self->_packagePathButton menu];
                [menu insertItemWithTitle:[outputURL lastPathComponent] action:nil keyEquivalent:@"" atIndex:2];
                [menu insertItem:[NSMenuItem separatorItem] atIndex:3];
                [self->_packagePathButton selectItemAtIndex:2];
                
            } else {
                
                if ([self->_userDefaults URLForKey:kMTDefaultsPackageOutputPath]) {
                    [self->_packagePathButton selectItemAtIndex:2];
                } else {
                    [self->_packagePathButton selectItemAtIndex:0];
                }
            }
        }];
    }
}

- (void)resetMenu
{
    NSMenu *menu = [_packagePathButton menu];
    
    for (NSMenuItem *menuItem in [menu itemArray]) {
        if ([menuItem tag] < 1000 || [menuItem tag] > 1002) {
            [menu removeItem:menuItem];
        }
    }
}

@end
