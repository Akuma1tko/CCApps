#import <Foundation/Foundation.h>

@class CCAppsApplication;

@interface CCAppsAppCatalog : NSObject

@property (nonatomic, copy, readonly) NSArray<CCAppsApplication *> *applications;

- (CCAppsApplication *)applicationForModuleIdentifier:(NSString *)moduleIdentifier;

@end

