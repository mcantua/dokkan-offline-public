#import <Foundation/Foundation.h>
#include <stdbool.h>
#include <stdint.h>

/* Private source-version-specific read-only probe. These process pointers never
   cross the native service boundary or enter files/JavaScript. */
typedef struct {
    uintptr_t image, application, director;
    bool paused, stopped;
} ODDuoEngineState;
/* Implemented in Objective-C; preserve its C symbol for Objective-C++ callers. */
#ifdef __cplusplus
extern "C" {
#endif
FOUNDATION_EXPORT BOOL ODDuoInspectPinnedEngine(id originalAppController, ODDuoEngineState *result);
#ifdef __cplusplus
}
#endif
