//
//  JJAppUpdateManager.h
//  JJAppUpdateSDK
//
//  Created by Liujiajie on 2022/11/12.
//

#import <Foundation/Foundation.h>

#define JJBLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

typedef void(^RequestCompletionBlock)(BOOL hasError, NSString * _Nullable message, BOOL hasUpdate, NSString * _Nullable url);

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const JJAppUpdateNetErrorMessage;
FOUNDATION_EXTERN NSString * const JJAppUpdateResultNO;

@interface JJAppUpdateManager : NSObject

- (void)requestAppUpdateInfo:(RequestCompletionBlock)completion;
- (void)doUpdateWithURLString:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
