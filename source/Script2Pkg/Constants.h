/*
    Constants.h
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

#define kMTpkgbuildPath                         @"/usr/bin/pkgbuild"
#define kMTxcrunPath                            @"/usr/bin/xcrun"
#define kMTxcodeselectPath                      @"/usr/bin/xcode-select"
#define kMTspctlPath                            @"/usr/sbin/spctl"
#define kMTpkgutilPath                          @"/usr/sbin/pkgutil"
#define kMTproductsignPath                      @"/usr/bin/productsign"
#define kMTproductbuildPath                     @"/usr/bin/productbuild"
#define kMTPackageReceiptsPath                  "/Library/Receipts/InstallHistory.plist"
#define kMTGitHubURL                            @"https://github.com/SAP/script-to-package-tool-for-macos"
#define kMTDeveloperTeamDisplayName             @"name"
#define kMTDeveloperTeamName                    @"org"
#define kMTDeveloperTeamID                      @"id"
#define kMTDeveloperCertName                    @"cert"

#define kMTDefaultsTeamID                       @"TeamID"
#define kMTDefaultsPackageSign                  @"SignPackages"
#define kMTDefaultsPackageNotarize              @"NotarizePackages"
#define kMTDefaultsShowActivityWindow           @"ShowActivityWindow"
#define kMTDefaultsAlwaysKeepActivities         @"AlwaysKeepActivities"
#define kMTDefaultsInvalidatedCredentials       @"InvalidatedCredentials"
#define kMTDefaultsPackageOutputPath            @"PackageOutputPath"
#define kMTDefaultsPackageIdentifierPrefix      @"PackageIdentifierPrefix"
#define kMTDefaultsSettingsSelectedTab          @"SettingsSelectedTab"
#define kMTDefaultsExistingPKGHandling          @"ExistingPackageHandling"
#define kMTDefaultsShowNotifications            @"ShowNotifications"
#define kMTDefaultsActivityWindowOnTop          @"ActivityWindowOnTop"
#define kMTDefaultsDeleteScript                 @"DeleteScriptOnSuccess"
#define kMTDefaultsPackageVersion               @"PackageVersion"
#define kMTDefaultsPackageCreateReceipts        @"CreatePackageReceipts"
#define kMTDefaultsPackageVersionUseScript      @"UseScriptVersion"
#define kMTDefaultsPackagePrefixIsIdentifier    @"PrefixIsIdentifier"
#define kMTDefaultsSkipIfMissingScript          @"SkipIfMissingScript"
#define kMTDefaultsCreateDistribution           @"CreateDistribution"

#define kMTNotificationKeyPackagePath           @"packagePath"
#define kMTNotificationKeyImportFiles           @"importFiles"

#define kMTMaxConcurrentOperations              10
#define kMTScript2PkgErrorDomain                @"corp.sap.Script2Pkg.ErrorDomain"
#define kMTPackageIdentifierPrefix              @"corp.sap.Script2Pkg"
#define kMTCredentialsPrefix                    @"Script2Pkg."

#define kMTNotificationNameFileImport           @"corp.sap.Script2Pkg.importFileNotification"
#define kMTNotificationNameOperationsCancel     @"corp.sap.Script2Pkg.operationsCancelNotification"
#define kMTNotificationNameOperationsDone       @"corp.sap.Script2Pkg.operationsDoneNotification"
#define kMTNotificationNameProgressAnnounce     @"corp.sap.Script2Pkg.progressAnnounceNotification"
#define kMTNotificationNameProgressUpdate       @"corp.sap.Script2Pkg.progressUpdateNotification"
#define kMTNotificationNameToolsInstalled       @"corp.sap.Script2Pkg.toolsInstalledNotification"
