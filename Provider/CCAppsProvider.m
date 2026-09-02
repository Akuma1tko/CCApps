#import "CCAppsProvider.h"

#import "../Module/CCAppsModule.h"
#import "../Shared/CCAppsApplication.h"
#import "../Shared/CCAppsAppCatalog.h"
#import "../Shared/CCAppsIconLoader.h"

@interface CCAppsProvider ()
@property (nonatomic, strong) CCAppsAppCatalog *catalog;
@end

@implementation CCAppsProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _catalog = [[CCAppsAppCatalog alloc] init];
    }
    return self;
}

- (NSUInteger)numberOfProvidedModules {
    return self.catalog.applications.count;
}

- (NSString *)identifierForModuleAtIndex:(NSUInteger)index {
    if (index >= self.catalog.applications.count) {
        return nil;
    }
    return self.catalog.applications[index].moduleIdentifier;
}

- (id)moduleInstanceForModuleIdentifier:(NSString *)identifier {
    CCAppsApplication *application = [self.catalog applicationForModuleIdentifier:identifier];
    if (!application) {
        NSLog(@"[CCApps] Refusing unknown module identifier: %@", identifier);
        return nil;
    }

    return [[CCAppsModule alloc] initWithBundleIdentifier:application.bundleIdentifier
                                              displayName:application.displayName];
}

- (NSString *)displayNameForModuleIdentifier:(NSString *)identifier {
    CCAppsApplication *application = [self.catalog applicationForModuleIdentifier:identifier];
    return application.displayName ?: @"CCApps";
}

- (NSString *)associatedBundleIdentifierForModuleWithIdentifier:(NSString *)identifier {
    return [self.catalog applicationForModuleIdentifier:identifier].bundleIdentifier;
}

- (UIImage *)settingsIconForModuleIdentifier:(NSString *)identifier {
    CCAppsApplication *application = [self.catalog applicationForModuleIdentifier:identifier];
    return application ? CCAppsIconForBundleIdentifier(application.bundleIdentifier) : nil;
}

@end
