#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** An explicit allowlist, not a recursive copy/redaction of internal reports.
 * No filesystem paths, raw requests, player data, opaque context or save IDs
 * escape. Only an explicit fixed route/template vocabulary can be shared.
 * Exporting a report is not an assertion that gameplay has been verified. */
FOUNDATION_EXPORT NSDictionary *ODDuoShareableDiagnosticReport(NSDictionary * _Nullable report);
NS_ASSUME_NONNULL_END
