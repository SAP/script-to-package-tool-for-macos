/*
     MTSignatureValidationController.m
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

#import "MTSignatureValidationController.h"
#import "MTNotarization.h"

@interface MTSignatureValidationController ()
@property (weak) IBOutlet NSImageView *packageIconView;
@property (nonatomic, strong, readwrite) NSString *signingText;
@property (nonatomic, strong, readwrite) NSString *notarizingText;
@property (nonatomic, strong, readwrite) NSString *packageName;
@property (assign) BOOL showProgress;
@end

@implementation MTSignatureValidationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.packageName = [_packageURL lastPathComponent];
    self.showProgress = YES;
    
    [MTNotarization checkNotarizationOfPackageAtURL:_packageURL
                                  completionHandler:^(BOOL isSigned, BOOL isExpired, BOOL isNotarized, NSString *developerTeam) {

        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (isSigned && [developerTeam length] > 0) {
                
                self.signingText = [NSString localizedStringWithFormat:NSLocalizedString(@"pkgSignedBy", nil), developerTeam];
                
                if (isNotarized) {
                    
                    [self->_packageIconView setImage:[NSImage imageNamed:@"shippingbox.circle.fill.green"]];
                    [self->_packageIconView setToolTip:NSLocalizedString(@"pkgIsNotarizedDescription", nil)];
                    self.notarizingText = NSLocalizedString(@"pkgIsNotarized", nil);
                    
                } else if ([developerTeam isEqualToString:@"Software Update"]) {
                    
                    [self->_packageIconView setImage:[NSImage imageNamed:@"shippingbox.circle.fill.green"]];
                    [self->_packageIconView setToolTip:NSLocalizedString(@"pkgIsNotarizedDescription", nil)];
                    self.notarizingText = NSLocalizedString(@"pkgByApple", nil);
                    
                } else {
                    
                    [self->_packageIconView setImage:[NSImage imageNamed:@"shippingbox.circle.fill.gold"]];
                    [self->_packageIconView setToolTip:NSLocalizedString(@"pkgIsSignedDescription", nil)];
                    self.notarizingText = NSLocalizedString(@"pkgNotNotarized", nil);
                }
                
                if (isExpired) {
                    
                    [self->_packageIconView setImage:[NSImage imageNamed:@"shippingbox.circle.fill.orange"]];
                    [self->_packageIconView setToolTip:NSLocalizedString(@"pkgExpiredDescription", nil)];
                    self.signingText = NSLocalizedString(@"pkgExpired", nil);
                }
                
            } else {
                
                [self->_packageIconView setImage:[NSImage imageNamed:@"shippingbox.circle.fill.orange"]];
                [self->_packageIconView setToolTip:NSLocalizedString(@"pkgNotSignedDescription", nil)];
                self.signingText = NSLocalizedString(@"pkgNotSigned", nil);
                self.notarizingText = NSLocalizedString(@"pkgNotNotarized", nil);
            }
                
            self.showProgress = NO;
        });
    }];    
}

@end
