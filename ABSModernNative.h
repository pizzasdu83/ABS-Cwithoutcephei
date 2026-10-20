// Private compatibility adapter; original tweak by Jonas Schiefner. GPL-3.0.
#import <Foundation/Foundation.h>
@class ABSPreferences;

#ifdef __cplusplus
extern "C" {
#endif
void initModernNative(ABSPreferences *preferences);
#ifdef __cplusplus
}
#endif
