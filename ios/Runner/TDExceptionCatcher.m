#import "TDExceptionCatcher.h"

@implementation TDExceptionCatcher

+ (BOOL)tryBlock:(NS_NOESCAPE void (^)(void))block
          error:(NSString * _Nullable * _Nullable)error {
  @try {
    block();
    return YES;
  } @catch (NSException *exception) {
    if (error != nil) {
      *error = exception.reason ?: @"Unknown TrustDecision exception";
    }
    return NO;
  }
}

@end
