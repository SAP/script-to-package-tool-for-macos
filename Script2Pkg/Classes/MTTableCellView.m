/*
     MTTableCellView.m
     Copyright 2022-2024 SAP SE
     
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

#import "MTTableCellView.h"
#import "MTPackagingProgress.h"
#import "Constants.h"

@implementation MTTableCellView

- (IBAction)showPackage:(id)sender
{
    MTPackagingProgress *packagingProgress = (MTPackagingProgress*)[self objectValue];
    NSDictionary *userInfo = [packagingProgress userInfo];
    NSString *packagePath = [userInfo objectForKey:kMTNotificationKeyPackagePath];
    
    if (packagePath) {

        // show the file in Finder
        NSArray *urls = [NSArray arrayWithObject:[NSURL URLWithString:packagePath]];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
    }
}

@end
