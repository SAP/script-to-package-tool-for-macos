/*
     MTLocalNotification.m
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

#import "MTLocalNotification.h"
#import "Constants.h"

@implementation MTLocalNotification

- (void)sendNotificationWithTitle:(NSString*)title message:(NSString*)message userInfo:(NSDictionary*)userInfo replaceExisting:(BOOL)replaceExisting;
{
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    [content setTitle:title];
    [content setBody:message];
    [content setSound:[UNNotificationSound defaultSound]];
    [content setUserInfo:userInfo];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                          content:content
                                                                          trigger:nil
    ];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center setDelegate:self];
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
                              if (granted) {
                                  
                                  // remove existing notifications
                                  if (replaceExisting) {
                                      [center removeAllDeliveredNotifications];
                                      [NSThread sleepForTimeInterval:.5];
                                  }

                                  [center addNotificationRequest:request
                                           withCompletionHandler:^(NSError * _Nullable error) {
                                               
                                               if (error) {
                                                   NSLog(@"SAPCorp: %@", error.localizedDescription);
                                               }
                                           }];
                              }
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter*)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    NSDictionary *userInfo = [[[[response notification] request] content] userInfo];

    if (userInfo) {
        
        NSString *packagePath = [userInfo objectForKey:kMTNotificationKeyPackagePath];
        
        if (packagePath) {
            
            // show the file in Finder
            NSArray *urls = [NSArray arrayWithObject:[NSURL URLWithString:packagePath]];
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
        }
    }
    
    completionHandler();
}

@end
