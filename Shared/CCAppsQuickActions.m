#import "CCAppsQuickActions.h"

#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (id)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBApplication : NSObject
@property (nonatomic, copy, readonly) NSArray *dynamicApplicationShortcutItems;
@property (nonatomic, strong, readonly) id info;
@end

@interface SBApplicationInfo : NSObject
@property (nonatomic, copy, readonly) NSArray *staticApplicationShortcutItems;
@end

@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *localizedTitle;
@property (nonatomic, copy, readonly) NSString *localizedSubtitle;
@property (nonatomic, copy, readonly) NSString *bundleIdentifierToLaunch;
- (void)sb_buildIconImageWithApplicationBundleURL:(NSURL *)bundleURL
                                             image:(UIImage *__autoreleasing *)image
                                   systemImageName:(NSString *__autoreleasing *)systemImageName;
@end

@interface UIHandleApplicationShortcutAction : NSObject
- (instancetype)initWithSBSShortcutItem:(SBSApplicationShortcutItem *)shortcutItem;
@end

@interface FBSOpenApplicationOptions : NSObject
+ (instancetype)optionsWithDictionary:(NSDictionary *)dictionary;
@end

@interface FBSOpenApplicationService : NSObject
+ (instancetype)serviceWithDefaultShellEndpoint;
- (void)openApplication:(NSString *)bundleIdentifier
             withOptions:(FBSOpenApplicationOptions *)options
              completion:(void (^)(id result))completion;
@end

@interface LSApplicationWorkspace (CCAppsQuickActions)
- (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleIdentifier;
@end

static NSArray *CCAppsArrayValue(id value) {
    return [value isKindOfClass:[NSArray class]] ? value : @[];
}

NSArray *CCAppsQuickActionsForBundleIdentifier(NSString *bundleIdentifier) {
    if (bundleIdentifier.length == 0) return @[];

    NSMutableArray *combined = [NSMutableArray arrayWithCapacity:4];
    NSMutableSet<NSString *> *seenTypes = [NSMutableSet setWithCapacity:4];

    @try {
        Class controllerClass = NSClassFromString(@"SBApplicationController");
        SBApplicationController *controller = [controllerClass sharedInstance];
        SBApplication *application = [controller applicationWithBundleIdentifier:bundleIdentifier];
        for (SBSApplicationShortcutItem *item in CCAppsArrayValue(application.dynamicApplicationShortcutItems)) {
            NSString *type = item.type;
            if (type.length == 0 || item.localizedTitle.length == 0 || [seenTypes containsObject:type]) continue;
            [combined addObject:item];
            [seenTypes addObject:type];
        }

        SBApplicationInfo *applicationInfo = application.info;
        for (SBSApplicationShortcutItem *item in CCAppsArrayValue(applicationInfo.staticApplicationShortcutItems)) {
            NSString *type = item.type;
            if (type.length == 0 || item.localizedTitle.length == 0 || [seenTypes containsObject:type]) continue;
            [combined addObject:item];
            [seenTypes addObject:type];
        }
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Reading quick actions for %@ raised %@: %@",
              bundleIdentifier, exception.name, exception.reason);
        return @[];
    }

    // SpringBoard's Home Screen menu displays at most four app-provided items.
    if (combined.count > 4) {
        [combined removeObjectsInRange:NSMakeRange(4, combined.count - 4)];
    }
    return [combined copy];
}

UIImage *CCAppsQuickActionIcon(id shortcutItem, NSString *bundleIdentifier) {
    if (!shortcutItem || bundleIdentifier.length == 0) return nil;

    @try {
        SEL buildSelector = @selector(sb_buildIconImageWithApplicationBundleURL:image:systemImageName:);
        if (![shortcutItem respondsToSelector:buildSelector]) return nil;

        LSApplicationProxy *proxy = [[LSApplicationWorkspace defaultWorkspace]
            applicationProxyForIdentifier:bundleIdentifier];
        NSURL *bundleURL = proxy.bundleURL;
        if (!bundleURL) return nil;

        UIImage *image = nil;
        NSString *systemImageName = nil;
        [(SBSApplicationShortcutItem *)shortcutItem
            sb_buildIconImageWithApplicationBundleURL:bundleURL
                                                image:&image
                                      systemImageName:&systemImageName];
        if (!image && systemImageName.length > 0) {
            image = [UIImage systemImageNamed:systemImageName];
        }
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Building a quick-action icon for %@ raised %@: %@",
              bundleIdentifier, exception.name, exception.reason);
        return nil;
    }
}

BOOL CCAppsLaunchQuickAction(id shortcutItem, NSString *fallbackBundleIdentifier) {
    if (!shortcutItem) return NO;

    @try {
        SBSApplicationShortcutItem *item = shortcutItem;
        NSString *bundleIdentifier = item.bundleIdentifierToLaunch;
        if (bundleIdentifier.length == 0) bundleIdentifier = fallbackBundleIdentifier;
        if (bundleIdentifier.length == 0) return NO;

        Class actionClass = NSClassFromString(@"UIHandleApplicationShortcutAction");
        Class optionsClass = NSClassFromString(@"FBSOpenApplicationOptions");
        Class serviceClass = NSClassFromString(@"FBSOpenApplicationService");
        if (!actionClass || !optionsClass || !serviceClass) {
            NSLog(@"[CCApps] Quick-action launch services are unavailable");
            return NO;
        }

        UIHandleApplicationShortcutAction *action =
            [[actionClass alloc] initWithSBSShortcutItem:item];
        if (!action) return NO;

        NSDictionary *payload = @{
            @"__ActivateSuspended" : @(NO),
            @"__Actions" : @[action],
            @"__PromptUnlockDevice" : @(YES),
            @"__LaunchOrigin" : @"__SBLaunchOriginShortcutItem"
        };
        FBSOpenApplicationOptions *options = [optionsClass optionsWithDictionary:payload];
        FBSOpenApplicationService *service = [serviceClass serviceWithDefaultShellEndpoint];
        if (!service || !options) return NO;

        [service openApplication:bundleIdentifier withOptions:options completion:^(id result) {
            NSLog(@"[CCApps] Quick action %@ for %@ completed with %@",
                  item.type, bundleIdentifier, result);
        }];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Launching a quick action raised %@: %@",
              exception.name, exception.reason);
        return NO;
    }
}
