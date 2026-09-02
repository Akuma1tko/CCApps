THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:16.5:15.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCAppsProvider
CCAppsProvider_BUNDLE_EXTENSION = bundle
CCAppsProvider_FILES = \
	Provider/CCAppsProvider.m \
	Module/CCAppsModule.m \
	Module/CCAppsModuleViewController.m \
	Shared/CCAppsApplication.m \
	Shared/CCAppsAppCatalog.m \
	Shared/CCAppsIconLoader.m \
	Shared/CCAppsLauncher.m
CCAppsProvider_CFLAGS = -fobjc-arc -Wall -Wextra
CCAppsProvider_FRAMEWORKS = UIKit
CCAppsProvider_PRIVATE_FRAMEWORKS = ControlCenterUIKit FrontBoardServices MobileCoreServices
CCAppsProvider_INSTALL_PATH = /Library/ControlCenter/CCSupport_Providers

include $(THEOS_MAKE_PATH)/bundle.mk
