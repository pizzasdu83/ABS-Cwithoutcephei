// Remplaçant minimal de HBPreferences (Cephei) — aucune dépendance externe.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ABSPreferencesChangeBlock)(NSString *key, id<NSCopying> _Nullable value);

@interface ABSPreferences : NSObject
- (instancetype)initWithIdentifier:(NSString *)identifier;
- (void)registerDefaults:(NSDictionary *)defaults;
- (nullable id)objectForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)registerPreferenceChangeBlockForKey:(NSString *)key block:(ABSPreferencesChangeBlock)block;
@end

NS_ASSUME_NONNULL_END
