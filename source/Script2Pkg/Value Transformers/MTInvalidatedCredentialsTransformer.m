/*
     MTInvalidatedCredentialsTransformer.m
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

#import "MTInvalidatedCredentialsTransformer.h"
#import "MTDeveloperIdentity.h"

@implementation MTInvalidatedCredentialsTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    BOOL allowInvalidation = NO;
    NSArray *invalidatedCredentials = (NSArray*)value;

    if ([invalidatedCredentials count] > 0) {
        
        // check if all developer identities are in the list
        // of invalidated identities. If not, allow invalidation
        NSArray *allDevIdentities = [MTDeveloperIdentity validIdentitiesOfType:MTDeveloperIdentityTypeInstaller];
        
        for (id identityRef in allDevIdentities) {
            
            MTDeveloperIdentity *identity = [[MTDeveloperIdentity alloc] initWithIdentity:(__bridge SecIdentityRef)(identityRef)];
            NSString *teamID = [identity teamID];
            if (teamID && ![invalidatedCredentials containsObject:teamID]) {
                allowInvalidation = YES;
                break;
            }
        }
        
    } else {
        
        allowInvalidation = YES;
    }
    
    return [NSNumber numberWithBool:allowInvalidation];
}

@end
