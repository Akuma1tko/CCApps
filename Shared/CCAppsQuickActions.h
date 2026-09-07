#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// Returns the app-defined Home Screen quick actions currently cached by
/// SpringBoard. Management actions such as Remove App are never included.
FOUNDATION_EXPORT NSArray *CCAppsQuickActionsForBundleIdentifier(NSString *bundleIdentifier);

/// Returns the icon SpringBoard builds for a quick action when available.
FOUNDATION_EXPORT UIImage *CCAppsQuickActionIcon(id shortcutItem,
                                                 NSString *bundleIdentifier);

/// Launches an app through the selected Home Screen quick action.
FOUNDATION_EXPORT BOOL CCAppsLaunchQuickAction(id shortcutItem,
                                               NSString *fallbackBundleIdentifier);
