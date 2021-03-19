#import "FfFlutterClientSdkPlugin.h"
#if __has_include(<ff_flutter_client_sdk/ff_flutter_client_sdk-Swift.h>)
#import <ff_flutter_client_sdk/ff_flutter_client_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ff_flutter_client_sdk-Swift.h"
#endif

@implementation FfFlutterClientSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFfFlutterClientSdkPlugin registerWithRegistrar:registrar];
}
@end
