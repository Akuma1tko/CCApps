#import <Foundation/Foundation.h>

/// Requests an app launch by bundle identifier. Returns NO only when the
/// request cannot be submitted through the currently available API.
FOUNDATION_EXPORT BOOL CCAppsLaunchApplication(NSString *bundleIdentifier);
