/*
     MTProgressController.m
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

#import "MTProgressController.h"
#import "MTPackagingProgress.h"
#import "MTOperationQueue.h"
#import "MTPayloadFreePackage.h"
#import "Constants.h"

@interface MTProgressController ()
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSButton *cancelButton;

@property (nonatomic, strong, readwrite) MTOperationQueue *operationQueue;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (assign) BOOL taskError;
@end

@implementation MTProgressController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];

    // set up our operations queue
    _operationQueue = [[MTOperationQueue alloc] init];
    [_operationQueue setMaxConcurrentOperationCount:kMTMaxConcurrentOperations];

    // set the maximum value to the number of files
    [_progressIndicator setMaxValue:[_packages count]];
}

- (void)viewDidAppear
{
    [super viewDidAppear];

    // get notified if all packages have been processed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(allOperationsDone:)
                                                 name:kMTNotificationNameOperationsDone
                                               object:nil
    ];
    
    // get notified if a task's progress changed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateProgress:)
                                                 name:kMTNotificationNameProgressUpdate
                                               object:nil
    ];

    for (MTPayloadFreePackage *aPackage in _packages) {
        
        // add script to "Recent Items"
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[aPackage scriptURL]];
        
        // package build operation
        NSBlockOperation *packageOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakPackageOperation = packageOperation;
        
        [packageOperation addExecutionBlock:^{
                            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

            [aPackage buildPackageWithCompletionHandler:^(NSError *error) {

                if (error) {
                    [aPackage cancelWithState:MTPackagingStatePKGBuildFailed error:error notify:YES];
                }
                
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if ([weakPackageOperation isCancelled]) {
                [aPackage cancelWithState:MTPackagingStateCancelled error:nil notify:YES];
            }
        }];
        
        // package notarizing operation
        NSBlockOperation *notarizeOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakNotarizeOperation = notarizeOperation;
        
        [notarizeOperation addExecutionBlock:^{

            if ([aPackage packageURL] && [aPackage notarizationTeamID]) {

                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                [aPackage notarizePackageWithCompletionHandler:^(NSError *error) {

                    if (error) {
                        [aPackage cancelWithState:MTPackagingStateNotarizingFailed error:error notify:YES];
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                
                if ([weakNotarizeOperation isCancelled]) {
                    [aPackage cancelWithState:MTPackagingStateCancelled error:nil notify:YES];
                }
            }
        }];
        
        // package copy operation
        NSBlockOperation *copyOperation = [[NSBlockOperation alloc] init];
        [copyOperation addExecutionBlock:^{

            if ([aPackage packageURL]) {
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                // copy the package back to the original location
                [aPackage movePackageByOverwritingExisting:[self->_userDefaults boolForKey:kMTDefaultsExistingPKGHandling]
                                         completionHandler:^(NSURL *packageURL, NSError *error) {
                    
                    if (error) {
                        
                        [aPackage cancelWithState:MTPackagingStateCopyPKGFailed error:error notify:YES];
                        
                    } else if ([self->_userDefaults boolForKey:kMTDefaultsDeleteScript]) {
                            [[NSFileManager defaultManager] removeItemAtURL:[aPackage scriptURL] error:nil];
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }];
        
        [notarizeOperation addDependency:packageOperation];
        [copyOperation addDependency:notarizeOperation];
        
        [_operationQueue addOperations:[NSArray arrayWithObjects:copyOperation, notarizeOperation, packageOperation, nil]
                     waitUntilFinished:NO];
    }

    // all operations have been finished
    [_operationQueue addNotificationBlock:^{
        
        // send a notification if all operations have been finished
        [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameOperationsDone
                                                            object:nil
                                                          userInfo:nil
        ];
    }];
}

- (void)updateProgress:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self->_cancelButton isEnabled] && [[notification object] isKindOfClass:[MTPackagingProgress class]]) {
            
            MTPackagingProgress *taskProgress = (MTPackagingProgress*)[notification object];
            [self->_progressIndicator incrementBy:([taskProgress completedUnitCount] > 0) ? (1.0 / [taskProgress totalUnitCount]) : 0];
            if ([taskProgress error]) { self->_taskError = YES; }
        }
    });
}

- (IBAction)cancelRemainingOperations:(id)sender
{
    [_operationQueue cancelAllOperations];
    [_cancelButton setEnabled:NO];
    [_progressLabel setStringValue:NSLocalizedString(@"stoppingProgressLabel", nil)];
    [_progressIndicator setIndeterminate:YES];
    
    // send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameOperationsCancel
                                                        object:nil
                                                      userInfo:nil
    ];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_progressIndicator startAnimation:nil];
    });
}

- (void)allOperationsDone:(NSNotification*)notification
{
    // remove operations done observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMTNotificationNameOperationsDone
                                                  object:nil];

    // disable the button
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_cancelButton setEnabled:NO];
    });
    
    // just let the progress indicator update until
    // we go ahead and dismiss the controller
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // remove update observer
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kMTNotificationNameProgressUpdate
                                                      object:nil];
        
        if (self->_taskError) {
            
            // close the progress sheet
            NSWindow *parentWindow = [[[self view] window] sheetParent];
            [parentWindow endSheet:[[self view] window]];
            
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:NSLocalizedString(@"errorMessageTitle", nil)];
            [theAlert setInformativeText:NSLocalizedString(@"errorMessageText", nil)];
            [theAlert addButtonWithTitle:NSLocalizedString(@"okButton", nil)];
            [theAlert addButtonWithTitle:NSLocalizedString(@"showWindowButton", nil)];
            [theAlert setAlertStyle:NSAlertStyleCritical];
            [theAlert beginSheetModalForWindow:parentWindow completionHandler:^(NSModalResponse returnCode) {
                
                if (returnCode == NSAlertSecondButtonReturn) {
                    
                    // show the activity window
                    for (NSWindow *aWindow in [NSApp windows]) {

                        if ([[aWindow identifier] isEqualToString:@"corp.sap.Script2Pkg.ActivityWindow"]) {
                            [aWindow makeKeyAndOrderFront:nil];
                            break;
                        }
                    }
                }
                
                [self dismissController:nil];
            }];
            
        } else {
            
            [self dismissController:nil];
        }
    });
}

@end
