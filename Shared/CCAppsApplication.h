#import <Foundation/Foundation.h>

@interface CCAppsApplication : NSObject

@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

