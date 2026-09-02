#import "CCAppsAppCatalog.h"

#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>

#import "CCAppsApplication.h"

@interface LSApplicationRecord : NSObject
@property (nonatomic, copy, readonly) NSArray<NSString *> *appTags;
@property (nonatomic, readonly, getter=isLaunchProhibited) BOOL launchProhibited;
@end

@interface LSApplicationProxy (CCAppsPrivate)
@property (nonatomic, copy, readonly) NSString *localizedName;
@property (nonatomic, copy, readonly) NSString *applicationType;
@property (nonatomic, copy, readonly) NSArray<NSString *> *appTags;
- (LSApplicationRecord *)correspondingApplicationRecord;
@end

@interface LSApplicationWorkspace (CCAppsPrivate)
- (void)enumerateApplicationsOfType:(NSUInteger)type
                              block:(void (^)(LSApplicationProxy *application))block;
@end

@interface CCAppsAppCatalog ()
@property (nonatomic, copy, readwrite) NSArray<CCAppsApplication *> *applications;
@property (nonatomic, copy) NSDictionary<NSString *, CCAppsApplication *> *applicationsByModuleIdentifier;
@end

static BOOL CCAppsTagsContainHidden(NSArray *tags) {
    for (id value in tags) {
        if ([value isKindOfClass:[NSString class]] &&
            [(NSString *)value rangeOfString:@"hidden" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static NSArray<LSApplicationProxy *> *CCAppsInstalledApplicationProxies(void) {
    LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
    if (!workspace) {
        return @[];
    }

    NSMutableArray<LSApplicationProxy *> *proxies = [NSMutableArray array];
    @try {
        if ([workspace respondsToSelector:@selector(enumerateApplicationsOfType:block:)]) {
            // LaunchServices uses 0 for user apps and 1 for system apps.
            [workspace enumerateApplicationsOfType:0 block:^(LSApplicationProxy *application) {
                if (application) [proxies addObject:application];
            }];
            [workspace enumerateApplicationsOfType:1 block:^(LSApplicationProxy *application) {
                if (application) [proxies addObject:application];
            }];
        } else if ([workspace respondsToSelector:@selector(allInstalledApplications)]) {
            [proxies addObjectsFromArray:workspace.allInstalledApplications ?: @[]];
        }
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] LaunchServices enumeration raised %@: %@", exception.name, exception.reason);
    }
    return proxies;
}

static BOOL CCAppsProxyIsVisibleAndLaunchable(LSApplicationProxy *proxy) {
    @try {
        NSString *bundleIdentifier = proxy.bundleIdentifier ?: proxy.applicationIdentifier;
        if (bundleIdentifier.length == 0 ||
            [bundleIdentifier hasPrefix:@"com.apple.webapp"] ||
            proxy.isPlaceholder || proxy.isWatchKitApp || proxy.isLaunchProhibited) {
            return NO;
        }

        if ([proxy respondsToSelector:@selector(isInstalled)] && !proxy.isInstalled) {
            return NO;
        }

        NSArray *recordTags = nil;
        BOOL recordLaunchProhibited = NO;
        if ([proxy respondsToSelector:@selector(correspondingApplicationRecord)]) {
            LSApplicationRecord *record = [proxy correspondingApplicationRecord];
            recordTags = record.appTags;
            recordLaunchProhibited = record.isLaunchProhibited;
        }
        NSArray *proxyTags = [proxy respondsToSelector:@selector(appTags)] ? proxy.appTags : nil;
        if (recordLaunchProhibited || CCAppsTagsContainHidden(proxyTags) || CCAppsTagsContainHidden(recordTags)) {
            return NO;
        }

        NSURL *bundleURL = proxy.bundleURL;
        if (!bundleURL || ![bundleURL.pathExtension.lowercaseString isEqualToString:@"app"] ||
            ![bundleURL checkResourceIsReachableAndReturnError:nil]) {
            return NO;
        }

        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        NSArray *springBoardTags = [bundle objectForInfoDictionaryKey:@"SBAppTags"];
        if (CCAppsTagsContainHidden(springBoardTags) ||
            [[bundle objectForInfoDictionaryKey:@"LSBackgroundOnly"] boolValue]) {
            return NO;
        }

        NSString *packageType = [bundle objectForInfoDictionaryKey:@"CFBundlePackageType"];
        return packageType.length == 0 || [packageType isEqualToString:@"APPL"];
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Ignoring an application record that raised %@: %@", exception.name, exception.reason);
        return NO;
    }
}

static NSString *CCAppsDisplayNameForProxy(LSApplicationProxy *proxy) {
    NSString *displayName = nil;
    @try {
        displayName = proxy.localizedName;
        if (displayName.length == 0) displayName = proxy.localizedShortName;

        if (displayName.length == 0 && proxy.bundleURL) {
            NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
            displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            if (displayName.length == 0) displayName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
            if (displayName.length == 0) displayName = [bundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
        }
    } @catch (__unused NSException *exception) {
        displayName = nil;
    }
    return displayName.length > 0 ? displayName : (proxy.bundleIdentifier ?: proxy.applicationIdentifier);
}

@implementation CCAppsAppCatalog

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSMutableDictionary<NSString *, CCAppsApplication *> *applicationsByBundleIdentifier = [NSMutableDictionary dictionary];

    for (LSApplicationProxy *proxy in CCAppsInstalledApplicationProxies()) {
        @autoreleasepool {
            if (!CCAppsProxyIsVisibleAndLaunchable(proxy)) continue;

            NSString *bundleIdentifier = proxy.bundleIdentifier ?: proxy.applicationIdentifier;
            if (applicationsByBundleIdentifier[bundleIdentifier]) continue;

            CCAppsApplication *application = [[CCAppsApplication alloc]
                initWithBundleIdentifier:bundleIdentifier
                             displayName:CCAppsDisplayNameForProxy(proxy)];
            applicationsByBundleIdentifier[bundleIdentifier] = application;
        }
    }

    NSArray<CCAppsApplication *> *applications = [applicationsByBundleIdentifier.allValues
        sortedArrayUsingComparator:^NSComparisonResult(CCAppsApplication *left, CCAppsApplication *right) {
            NSComparisonResult nameResult = [left.displayName localizedCaseInsensitiveCompare:right.displayName];
            if (nameResult != NSOrderedSame) return nameResult;
            return [left.bundleIdentifier compare:right.bundleIdentifier options:NSCaseInsensitiveSearch];
        }];

    NSMutableDictionary *byModuleIdentifier = [NSMutableDictionary dictionaryWithCapacity:applications.count];
    for (CCAppsApplication *application in applications) {
        byModuleIdentifier[application.moduleIdentifier] = application;
    }

    self.applications = applications;
    self.applicationsByModuleIdentifier = byModuleIdentifier;
    NSLog(@"[CCApps] Discovered %lu launchable apps in %.1f ms",
          (unsigned long)applications.count,
          (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
    return self;
}

- (CCAppsApplication *)applicationForModuleIdentifier:(NSString *)moduleIdentifier {
    return moduleIdentifier.length > 0 ? self.applicationsByModuleIdentifier[moduleIdentifier] : nil;
}

@end
