/*
     MTLocalNotification.h
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

#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

@interface MTLocalNotification : NSObject <UNUserNotificationCenterDelegate>

/*!
 @method        sendNotificationWithTitle:message:userInfo:replaceExisting:
 @abstract      Sends a notification to the user notificatiion center.
 @param         title The title of the notification.
 @param         message The notification body (the message).
 @param         userInfo An optional dictionary containing custom data to associate with the notification.
 @param         replaceExisting A boolean specifying if existing notification should be removed or not.
 */
- (void)sendNotificationWithTitle:(NSString*)title
                          message:(NSString*)message
                         userInfo:(NSDictionary*)userInfo
                  replaceExisting:(BOOL)replaceExisting;

@end
