#import <Foundation/Foundation.h>
#import "ABSRootListController.h"
#import <dlfcn.h>
#import <spawn.h>
extern char **environ;

@interface FBSSystemService : NSObject
+ (instancetype)sharedService;
- (void)sendActions:(NSSet *)actions withResult:(id)result;
@end
@interface SBSRelaunchAction : NSObject
+ (instancetype)actionWithReason:(NSString *)reason options:(NSUInteger)options targetURL:(NSURL *)url;
@end
#import <Preferences/PSSpecifier.h>

@implementation ABSRootListController

- (NSArray*)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		// Modern controlled disablement must reach SpringBoard before a respring
		// can discard its in-memory restoration state. Keep the legacy UI/path.
		if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17) {
			for (PSSpecifier *specifier in _specifiers) {
				if ([[specifier propertyForKey:@"key"] isEqualToString:@"enabled"])
					[specifier setProperty:@"com.jschiefner.advancedbrightnesssliderpreferences/ReloadPrefs"
					                 forKey:@"PostNotification"];
			}
		}
	}

	return _specifiers;
}

-(void)respring {
	dlopen("/System/Library/PrivateFrameworks/FrontBoardServices.framework/FrontBoardServices", RTLD_LAZY);
	dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY);
	Class serviceClass = NSClassFromString(@"FBSSystemService");
	Class actionClass = NSClassFromString(@"SBSRelaunchAction");
	if (serviceClass && actionClass) {
		// 4 = SBSRelaunchActionOptionsFadeToBlackTransition
		id action = [actionClass actionWithReason:@"RestartRenderServer" options:4 targetURL:nil];
		[[serviceClass sharedService] sendActions:[NSSet setWithObject:action] withResult:nil];
		return;
	}
	// Plan B : sbreload (rootless puis rootful)
	const char *paths[] = {"/var/jb/usr/bin/sbreload", "/usr/bin/sbreload"};
	for (int i = 0; i < 2; i++) {
		pid_t pid;
		char *argv[] = {(char *)paths[i], NULL};
		if (posix_spawn(&pid, paths[i], NULL, NULL, argv, environ) == 0) return;
	}
}

-(void)openGithub {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/0chium/AdvancedBrightnessSlider-Continued"] options:@{} completionHandler:nil];
}

-(void)openSupport {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/0chium/AdvancedBrightnessSlider-Continued/issues"] options:@{} completionHandler:nil];
}

-(void)openUpstream {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/jschiefner/advanced-brightness-slider-tweak/"] options:@{} completionHandler:nil];
}

-(void)openPaypal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/JonasSchiefner"] options:@{} completionHandler:nil];
}

@end
