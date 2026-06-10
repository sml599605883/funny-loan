#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDExceptionCatcher : NSObject

+ (BOOL)tryBlock:(NS_NOESCAPE void (^)(void))block
          error:(NSString * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
