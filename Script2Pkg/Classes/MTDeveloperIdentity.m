/*
     MTDeveloperIdentity.m
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

#import "MTDeveloperIdentity.h"
#import "Constants.h"

@interface MTDeveloperIdentity ()
@property (assign) SecIdentityRef identity;
@end

@implementation MTDeveloperIdentity

- (id)initWithIdentity:(SecIdentityRef)identity
{
    self = [super init];
    
    if (self) {
        _identity = identity;
    }
    
    return self;
}

- (NSString*)teamID
{
    NSString *returnValue = nil;
    
    if (_identity) {
        
        SecCertificateRef cert = NULL;
        SecIdentityCopyCertificate(_identity, &cert);
        
        if (cert) {
            returnValue = [self valueOfSubjectProperty:kSecOIDOrganizationalUnitName inCertificate:cert];
            CFRelease(cert);
        }
    }
    
    return returnValue;
}

- (NSString*)teamName
{
    NSString *returnValue = nil;
    
    if (_identity) {
        
        SecCertificateRef cert = NULL;
        SecIdentityCopyCertificate(_identity, &cert);
        
        if (cert) {
            returnValue = [self valueOfSubjectProperty:kSecOIDOrganizationName inCertificate:cert];
            CFRelease(cert);
        }
    }
    
    return returnValue;
}

- (NSString*)certificateName
{
    NSString *returnValue = nil;
    
    if (_identity) {
        
        SecCertificateRef cert = NULL;
        SecIdentityCopyCertificate(_identity, &cert);
        
        if (cert) {
            
            CFStringRef value = NULL;
            SecCertificateCopyCommonName(cert, &value);
            if (value) { returnValue = CFBridgingRelease(value); }
            
            CFRelease(cert);
        }
    }
    
    return returnValue;
}

- (NSString*)valueOfSubjectProperty:(CFStringRef)property inCertificate:(SecCertificateRef)certificate
{
    NSString *returnValue = nil;
    
    if (certificate) {
        
        CFMutableArrayRef keys = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
        CFArrayAppendValue(keys, kSecOIDX509V1SubjectName);
        
        CFDictionaryRef values = SecCertificateCopyValues(certificate, keys, NULL);
        
        if (values) {
            
            CFDictionaryRef subjectDict = CFDictionaryGetValue(values, kSecOIDX509V1SubjectName);
            CFArrayRef subjectValues = CFDictionaryGetValue(subjectDict, kSecPropertyKeyValue);
            
            for (int index = 0; index < CFArrayGetCount(subjectValues); index++) {
                
                CFDictionaryRef dict = (CFDictionaryRef) CFArrayGetValueAtIndex(subjectValues, index);
                CFStringRef label = CFDictionaryGetValue(dict, kSecPropertyKeyLabel);
                
                if (kCFCompareEqualTo == CFStringCompare(label, property, 0)) {
                    CFStringRef value = CFDictionaryGetValue(dict, kSecPropertyKeyValue);
                    
                    if (value) {
                        returnValue = (__bridge NSString *)(value);
                        break;
                    }
                }
            }
            
            CFRelease(values);
        }
    }
    
    return returnValue;
}

+ (NSArray*)validIdentitiesOfType:(MTDeveloperIdentityType)type
{
    CFArrayRef items = NULL;
    NSMutableArray *identities = [[NSMutableArray alloc] init];
    NSString *identityType = (type == MTDeveloperIdentityTypeInstaller) ? @"Developer ID Installer:" : @"Developer ID Application:";
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassIdentity, (__bridge id)kSecClass,
                           identityType, (__bridge id)kSecMatchSubjectStartsWith,
                           [NSNumber numberWithBool:YES], (__bridge id)kSecAttrCanSign,
                           [NSNumber numberWithBool:YES], (__bridge id)kSecReturnRef,
                           (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                           nil];
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&items);

    if (status == errSecSuccess) {
        
        if (items) {
            
            [identities addObjectsFromArray:CFBridgingRelease(items)];
        }
    }
        
    return identities;
}

@end
