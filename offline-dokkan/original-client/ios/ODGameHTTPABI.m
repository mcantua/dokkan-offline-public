#import "ODGameHTTPABI.h"
#import <objc/runtime.h>
#include <string.h>

BOOL ODVerifySuppliedGameHTTPABI(NSError **error) {
    // Exact observed encodings: research/ios-runtime-contracts.json, main executable
    // SHA256 9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610.
    // A loader must separately pin that original file. Matching ABI is not a
    // substitute for an executable hash or current response-contract evidence.
    Class cls = NSClassFromString(@"HttpAsynConnection");
    const struct { const char *name, *type; } methods[] = {
        {"startRequest:", "v24@0:8@16"},
        {"responseData", "@16@0:8"},
        {"setResponseData:", "v24@0:8@16"},
        {"responseCode", "q16@0:8"},
        {"connection:didReceiveResponse:", "v32@0:8@16@24"},
        {"connection:didReceiveData:", "v32@0:8@16@24"},
        {"connection:didFailWithError:", "v32@0:8@16@24"},
        {"connectionDidFinishLoading:", "v24@0:8@16"},
    };
    BOOL matches = cls != Nil;
    for (size_t i = 0; matches && i < sizeof(methods)/sizeof(methods[0]); ++i) {
        Method method = class_getInstanceMethod(cls, sel_registerName(methods[i].name));
        const char *type = method ? method_getTypeEncoding(method) : NULL;
        matches = type && strcmp(type, methods[i].type) == 0;
    }
    const struct { const char *name, *type; ptrdiff_t offset; } ivars[] = {
        {"responseData", "@\"NSMutableData\"", 40}, {"responseCode", "q", 56},
    };
    for (size_t i = 0; matches && i < sizeof(ivars)/sizeof(ivars[0]); ++i) {
        Ivar ivar = class_getInstanceVariable(cls, ivars[i].name);
        const char *type = ivar ? ivar_getTypeEncoding(ivar) : NULL;
        matches = type && strcmp(type, ivars[i].type) == 0 &&
                  ivar_getOffset(ivar) == ivars[i].offset;
    }
    if (!matches && error) {
        *error = [NSError errorWithDomain:@"OfflineDokkanTransport" code:1
            userInfo:@{NSLocalizedDescriptionKey: @"ORIGINAL_CLIENT_ABI_MISMATCH"}];
    }
    return matches;
}
