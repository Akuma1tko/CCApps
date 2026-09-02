#import "CCAppsApplication.h"

static NSString * const CCAppsModuleIdentifierPrefix = @"com.akuma.ccapps.app.";

@implementation CCAppsApplication

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName {
    self = [super init];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _displayName = [displayName copy];
        _moduleIdentifier = [[CCAppsModuleIdentifierPrefix stringByAppendingString:bundleIdentifier] copy];
    }
    return self;
}

@end

