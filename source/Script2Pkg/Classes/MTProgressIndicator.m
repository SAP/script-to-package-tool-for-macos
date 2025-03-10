/*
     MTProgressIndicator.m
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

#import "MTProgressIndicator.h"

@interface MTProgressIndicator ()
@property (weak) IBOutlet NSLayoutConstraint *heightConstraint;
@property (assign) CGFloat indicatorHeight;
@end


@implementation MTProgressIndicator

- (void)setDoubleValue:(double)doubleValue
{
    if (doubleValue > [self doubleValue]) {
        
        [super setDoubleValue:doubleValue];
        
        if ([self isHidden] && doubleValue < [self maxValue]) {
            
            [self setHidden:NO];
            
        } else if (![self isHidden] && doubleValue >= [self maxValue]) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setHidden:YES];
            });
        }
    }
}

- (void)setHidden:(BOOL)hidden
{
    if ([self isHidden] && !hidden) {
        
        [_heightConstraint setConstant:_indicatorHeight];
        
    } else if (![self isHidden] && hidden) {
        
        _indicatorHeight = [_heightConstraint constant];
        [_heightConstraint setConstant:0];
    }

    [super setHidden:hidden];

}

@end
