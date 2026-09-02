#import <ControlCenterUIKit/CCUIContentModule-Protocol.h>

@interface CCAppsModule : NSObject <CCUIContentModule>

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
