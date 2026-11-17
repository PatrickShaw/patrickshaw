#import <AppKit/AppKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static BOOL applicationMatches(NSURL *applicationURL, NSString *bundleIdentifier) {
    NSString *actualIdentifier = [NSBundle bundleWithURL:applicationURL].bundleIdentifier;
    return actualIdentifier != nil &&
        [actualIdentifier caseInsensitiveCompare:bundleIdentifier] == NSOrderedSame;
}

static int verifyHandler(UTType *contentType, NSString *bundleIdentifier) {
    NSURL *handler = [NSWorkspace.sharedWorkspace URLForApplicationToOpenContentType:contentType];
    if (handler != nil && applicationMatches(handler, bundleIdentifier)) {
        return EXIT_SUCCESS;
    }
    fprintf(stderr, "%s resolves to %s, expected %s\n",
        contentType.identifier.UTF8String,
        handler != nil ? handler.path.UTF8String : "no application",
        bundleIdentifier.UTF8String);
    return EXIT_FAILURE;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        BOOL checkOnly = argc == 4 && strcmp(argv[1], "--check") == 0;
        if ((!checkOnly && argc != 3) || (argc == 3 && strcmp(argv[1], "--check") == 0)) {
            fprintf(stderr, "Usage: %s [--check] bundle-id extension\n", argv[0]);
            return EXIT_FAILURE;
        }
        int argumentOffset = checkOnly ? 2 : 1;
        NSString *bundleIdentifier = [NSString stringWithUTF8String:argv[argumentOffset]];
        NSString *extension = [NSString stringWithUTF8String:argv[argumentOffset + 1]];
        if ([extension hasPrefix:@"."]) {
            extension = [extension substringFromIndex:1];
        }
        UTType *contentType = extension.length == 0 ? nil : [UTType typeWithFilenameExtension:extension];
        if (contentType == nil) {
            fprintf(stderr, "Invalid filename extension: %s\n", argv[argumentOffset + 1]);
            return EXIT_FAILURE;
        }
        NSURL *applicationURL = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleIdentifier];
        if (applicationURL == nil) {
            fprintf(stderr, "Application is not registered: %s\n", bundleIdentifier.UTF8String);
            return EXIT_FAILURE;
        }
        if (checkOnly) {
            return verifyHandler(contentType, bundleIdentifier);
        }
        NSURL *currentHandler = [NSWorkspace.sharedWorkspace URLForApplicationToOpenContentType:contentType];
        if (currentHandler != nil && applicationMatches(currentHandler, bundleIdentifier)) {
            return EXIT_SUCCESS;
        }

        // duti's legacy setter can report success while Launch Services keeps the old app.
        // Wait for the supported API to finish, then check the effective handler.
        [NSWorkspace.sharedWorkspace setDefaultApplicationAtURL:applicationURL
                                             toOpenContentType:contentType
                                             completionHandler:^(NSError *error) {
            if (error != nil) {
                fprintf(stderr, "Could not associate .%s with %s: %s\n",
                    extension.UTF8String, bundleIdentifier.UTF8String,
                    error.localizedDescription.UTF8String);
                exit(EXIT_FAILURE);
            }
            exit(verifyHandler(contentType, bundleIdentifier));
        }];
        [[NSRunLoop mainRunLoop] run];
    }
    return EXIT_FAILURE;
}
