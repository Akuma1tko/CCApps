// CCSupport provider interface, Copyright (c) 2018-2024 Lars Froeder.
// Distributed under the MIT License. Source:
// https://github.com/opa334/CCSupport/blob/master/CCSModuleProvider.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CCSModuleProvider
@required
- (NSUInteger)numberOfProvidedModules;
- (NSString *)identifierForModuleAtIndex:(NSUInteger)index;
- (id)moduleInstanceForModuleIdentifier:(NSString *)identifier;
- (NSString *)displayNameForModuleIdentifier:(NSString *)identifier;
@optional
- (NSSet *)supportedDeviceFamiliesForModuleWithIdentifier:(NSString *)identifier;
- (NSSet *)requiredDeviceCapabilitiesForModuleWithIdentifier:(NSString *)identifier;
- (NSSet *)requiredDeviceIncapabilitiesForModuleWithIdentifier:(NSString *)identifier;
- (NSString *)associatedBundleIdentifierForModuleWithIdentifier:(NSString *)identifier;
- (NSString *)associatedBundleMinimumVersionForModuleWithIdentifier:(NSString *)identifier;
- (NSUInteger)visibilityPreferenceForModuleWithIdentifier:(NSString *)identifier;
- (UIImage *)settingsIconForModuleIdentifier:(NSString *)identifier;
- (BOOL)providesListControllerForModuleIdentifier:(NSString *)identifier;
- (id)listControllerForModuleIdentifier:(NSString *)identifier;
@end

