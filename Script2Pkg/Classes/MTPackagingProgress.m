/*
     MTPackagingProgress.m
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

#import "MTPackagingProgress.h"
#import "Constants.h"

@interface MTPackagingProgress ()
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSURL *outputDirectoryURL;
@end

@implementation MTPackagingProgress

- (id)initWithTaskName:(NSString *)name totalUnitCount:(NSInteger)count
{
    self = [super init];
    
    if (self) {
        _name = name;
        _state = MTPackagingStateWaiting;
        _totalUnitCount = count;
        _completedUnitCount = 0;
        _error = nil;
        
        [self announce];
    }
    
    return self;
}

- (void)setCompletedUnitCount:(NSUInteger)count notify:(BOOL)notify
{
    _completedUnitCount = count;
    
    if (notify) { [self notify]; }
}

- (double)fractionCompleted
{
    return (_totalUnitCount > 0) ? (1.0 / _totalUnitCount) * _completedUnitCount : 0;
}

- (NSInteger)unitsRemaining
{
    return (_totalUnitCount > 0) ? (_totalUnitCount - _completedUnitCount) : 0;
}

- (NSString*)localizedStateString
{
    return [self localizedStringForState:_state];
}

- (NSString*)localizedStringForState:(MTPackagingState)state
{
    NSString *key = [NSString stringWithFormat:@"MTPackagingTaskState_%i", state];
    NSString *localizedString = NSLocalizedString(key, nil);

    return localizedString;
}

- (NSString*)errorDescription
{
    return (_error) ? [_error localizedDescription] : nil;
}

- (void)cancelWithState:(MTPackagingState)state error:(NSError*)error notify:(BOOL)notify
{
    if (_completedUnitCount != _totalUnitCount) {
        _error = error;
        _state = state;
        [self setCompletedUnitCount:_totalUnitCount notify:notify];
    }
}

- (void)notify
{
    // send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameProgressUpdate
                                                        object:self
                                                      userInfo:_userInfo
    ];
}

- (void)announce
{
    // send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationNameProgressAnnounce
                                                        object:self
                                                      userInfo:_userInfo
    ];
}

@end
