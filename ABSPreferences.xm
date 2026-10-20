#import "ABSPreferences.h"

@interface ABSPreferences ()
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSMutableDictionary *defaults;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *blocks;
@property (nonatomic, strong) NSMutableDictionary *lastValues;
- (void)reloaded;
@end

static void ABSPrefsReloadCallback(CFNotificationCenterRef center, void *observer,
                                   CFStringRef name, const void *object, CFDictionaryRef info) {
	ABSPreferences *prefs = (__bridge ABSPreferences *)observer;
	[prefs reloaded];
}

@implementation ABSPreferences

- (instancetype)initWithIdentifier:(NSString *)identifier {
	if ((self = [super init])) {
		_identifier = [identifier copy];
		_defaults = [NSMutableDictionary new];
		_blocks = [NSMutableDictionary new];
		_lastValues = [NSMutableDictionary new];
		// Même notification que celle envoyée par PostNotification dans Root.plist
		NSString *name = [identifier stringByAppendingString:@"/ReloadPrefs"];
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			(__bridge const void *)self, ABSPrefsReloadCallback, (__bridge CFStringRef)name,
			NULL, CFNotificationSuspensionBehaviorCoalesce);
	}
	return self;
}

- (void)registerDefaults:(NSDictionary *)defaults {
	[self.defaults addEntriesFromDictionary:defaults];
}

- (id)objectForKey:(NSString *)key {
	CFPreferencesAppSynchronize((__bridge CFStringRef)self.identifier);
	id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
		(__bridge CFStringRef)self.identifier));
	return value ?: self.defaults[key];
}

- (BOOL)boolForKey:(NSString *)key {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

- (float)floatForKey:(NSString *)key {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : 0.f;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
	CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse,
		(__bridge CFStringRef)self.identifier);
	CFPreferencesAppSynchronize((__bridge CFStringRef)self.identifier);
	// Mémorise la valeur pour ne pas se re-déclencher soi-même.
	self.lastValues[key] = @(value);
}

- (void)registerPreferenceChangeBlockForKey:(NSString *)key block:(ABSPreferencesChangeBlock)block {
	NSMutableArray *list = self.blocks[key];
	if (!list) self.blocks[key] = list = [NSMutableArray new];
	[list addObject:[block copy]];
	id current = [self objectForKey:key];
	if (current) self.lastValues[key] = current;
}

- (void)reloaded {
	for (NSString *key in [self.blocks allKeys]) {
		id value = [self objectForKey:key];
		id last = self.lastValues[key];
		if (value == last || [value isEqual:last]) continue;
		if (value) self.lastValues[key] = value; else [self.lastValues removeObjectForKey:key];
		for (ABSPreferencesChangeBlock block in [self.blocks[key] copy])
			block(key, value);
	}
}

@end
