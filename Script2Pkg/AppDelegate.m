/*
     AppDelegate.m
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

#import <UserNotifications/UserNotifications.h>
#import "Constants.h"
#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, strong, readwrite) NSArray *queuedImportFiles;
@property (nonatomic, strong, readwrite) NSWindowController *mainWindowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // check if we were launched because the user clicked one of our notifications
    UNNotificationResponse *notificationResponse = [[aNotification userInfo] objectForKey:NSApplicationLaunchUserNotificationKey];
    
    if (notificationResponse) {
        
        NSDictionary *userInfo = [[[[notificationResponse notification] request] content] userInfo];

        if (userInfo) {
            
            NSString *packagePath = [userInfo objectForKey:kMTNotificationKeyPackagePath];
            
            if (packagePath) {
                
                // show the file in Finder
                NSArray *urls = [NSArray arrayWithObject:[NSURL URLWithString:packagePath]];
                [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
            }
        }
        
        [NSApp terminate:self];
        
        
    } else {
        
        // make sure we are frontmost
        [NSApp activateIgnoringOtherApps:YES];
        
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        _mainWindowController = [storyboard instantiateControllerWithIdentifier:@"corp.sap.Script2Pkg.MainController"];
        [_mainWindowController showWindow:self];
        [[_mainWindowController window] makeKeyWindow];
        
        // have we been launched by double-clicking an export file?
        if ([_queuedImportFiles count]) {
            [self importFilesWithPaths:_queuedImportFiles];
            _queuedImportFiles = nil;
        }
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames
{
    if (_mainWindowController) {
        [self importFilesWithPaths:filenames];
    } else {
        _queuedImportFiles = filenames;
    }

    [NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

- (void)importFilesWithPaths:(NSArray*)importFiles
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameFileImport
                                                        object:importFiles
                                                      userInfo:nil
    ];
}

@end
