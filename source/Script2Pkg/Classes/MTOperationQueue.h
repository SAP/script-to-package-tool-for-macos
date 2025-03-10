/*
     MTOperationQueue.h
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

#import <Foundation/Foundation.h>

/*!
 @abstract This is a sub class of NSOperationQueue that adds a method that allows to add a notification block that is called
 as soon as all operations have been finished. In contrast to the NSOperationQueue's addBarrierBlock: method, this method
 is also called if the queue became empty because all operations have been cancelled.
 */

@interface MTOperationQueue : NSOperationQueue

/*!
 @method        addNotificationBlock:
 @abstract      Invokes a block when the queue finished all operations.
 @param         block The block to execute.
 */
- (void)addNotificationBlock:(void (^) (void))block;

@end

