/*
     MTOperationQueue.m
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

#import "MTOperationQueue.h"

@implementation MTOperationQueue

- (void)addNotificationBlock:(void (^) (void))block
{
    if (block) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self waitUntilAllOperationsAreFinished];
            dispatch_async(dispatch_get_main_queue(), ^{ block(); });
        });
    }
}

@end
