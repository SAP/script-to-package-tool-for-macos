/*
     MTActivityController.m
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

#import "MTActivityController.h"
#import "MTPackagingProgress.h"
#import "MTLocalNotification.h"
#import "Constants.h"

@interface MTActivityController ()
@property (weak) IBOutlet NSArrayController *allTasksController;

@property (nonatomic, strong, readwrite) NSMutableArray *allTasks;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) MTLocalNotification *userNotification;
@end

@implementation MTActivityController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _userNotification = [[MTLocalNotification alloc] init];
    self.allTasks = [[NSMutableArray alloc] init];
    
    // get notified about new tasks
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateProgress:)
                                                 name:kMTNotificationNameProgressAnnounce
                                               object:nil
    ];
    
    // get notified if a task's progress changed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateProgress:)
                                                 name:kMTNotificationNameProgressUpdate
                                               object:nil
    ];
    
    // get notified if the users cancels the operation
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cancelRemainingOperations:)
                                                 name:kMTNotificationNameOperationsCancel
                                               object:nil
    ];
}

- (void)updateProgress:(NSNotification*)notification
{
    if ([[notification object] isKindOfClass:[MTPackagingProgress class]]) {
        
        MTPackagingProgress *taskProgress = (MTPackagingProgress*)[notification object];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self willChangeValueForKey:@"allTasks"];
                        
            if (![self->_allTasks containsObject:taskProgress]) {
                
                [self->_allTasksController addObject:taskProgress];
                
            // remove the task from activity window if it has been finished
            // successful and if the user decided not to keep all tasks
            } else if ([taskProgress state] == MTPackagingStateComplete && ![self->_userDefaults boolForKey:kMTDefaultsAlwaysKeepActivities]) {

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self->_allTasksController removeObject:taskProgress];
                });
            }

            [self didChangeValueForKey:@"allTasks"];
        });
        
        if ([self->_userDefaults boolForKey:kMTDefaultsShowNotifications]) {
            
            if ([taskProgress state] == MTPackagingStateComplete) {
                
                // notify the user about the finished package
                [self->_userNotification sendNotificationWithTitle:NSLocalizedString(@"packageSuccessNotificationTitle", nil)
                                                           message:[NSString localizedStringWithFormat:NSLocalizedString(@"packageSuccessNotificationMessage", nil), [taskProgress name]]
                                                          userInfo:[taskProgress userInfo]
                                                   replaceExisting:NO
                ];
                
                
            } else if ([taskProgress error]) {
                
                // notify the user about the failed package
                [self->_userNotification sendNotificationWithTitle:NSLocalizedString(@"packageFailNotificationTitle", nil)
                                                           message:[NSString localizedStringWithFormat:NSLocalizedString(@"packageFailNotificationMessage", nil), [taskProgress name]]
                                                          userInfo:nil
                                                   replaceExisting:NO
                ];
            }
        }
    }
}

- (IBAction)clearActivities:(id)sender
{
    // remove all finished tasks
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.fractionCompleted == 1"];
    [self->_allTasksController removeObjects:[[self->_allTasksController arrangedObjects] filteredArrayUsingPredicate:predicate]];
}

- (void)cancelRemainingOperations:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // remove all tasks that are still waiting
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.state == %d", MTPackagingStateWaiting];
        [self->_allTasksController removeObjects:[[self->_allTasksController arrangedObjects] filteredArrayUsingPredicate:predicate]];
    });
}

- (void)dealloc
{
    // remove our observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameProgressAnnounce
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameProgressUpdate
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameOperationsCancel
                                                  object:nil];
}

@end
