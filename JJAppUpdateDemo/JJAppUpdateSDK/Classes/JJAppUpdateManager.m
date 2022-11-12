//
//  JJAppUpdateManager.m
//  JJAppUpdateSDK
//
//  Created by Liujiajie on 2022/11/12.
//

#import "JJAppUpdateManager.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const JJAppUpdateNetErrorMessage = @"网络异常，请稍后重试";

#define JJDynamicCast(x, c) ((c *)(JJDynamicCastOrNil(x, [c class])))

@interface JJAppUpdateManager ()

@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation JJAppUpdateManager

- (void)requestAppUpdateInfo:(RequestCompletionBlock)completion {
    NSURL *url = [NSURL URLWithString:@"https://domain/path"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    // 需要进行加密，例如 MD5 + 加盐（不过这个应该是公司网络库的基础能力，不需要业务方额外做）
    request.HTTPBody = [[self commonParams] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request.copy completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            JJBLOCK_INVOKE(completion, YES, JJAppUpdateNetErrorMessage, NO, nil);
            return;
        }
        
        // 数据解析前需要对加密数据进行解密（应该由网络库SDK内部完成，业务无感知）
        NSError *jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:&jsonError];
        if (jsonError) {
            JJBLOCK_INVOKE(completion, YES, JJAppUpdateNetErrorMessage, NO, nil);  // 没必要把具体的错误细节暴露给用户
            return;
        }
        
        NSNumber *status = JJDynamicCast(jsonDict[@"has_update"], NSNumber);
        if (status && status.intValue != 0) {
            NSString *message = JJDynamicCast(jsonDict[@"message"], NSString);
            JJBLOCK_INVOKE(completion, YES, message ?: JJAppUpdateNetErrorMessage, NO, nil);
            return;
        }
        
        NSNumber *hasUpdate = JJDynamicCast(jsonDict[@"has_update"], NSNumber);
        if (hasUpdate) {
            JJBLOCK_INVOKE(completion, NO, nil, hasUpdate.boolValue, JJDynamicCast(jsonDict[@"open_url"], NSString));
            return;
        }
        
        JJBLOCK_INVOKE(completion, NO, nil, NO, nil);
        return;
    }];
    [task resume];
    self.task = task;
}

- (void)doUpdateWithURLString:(NSString *)url {
    if (isEmptyString(url)) {
        url = @"https://apps.apple.com/cn/app/tao-bao-taobao-for-iphone/id387682726";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (NSString *)commonParams {
    // 这里存储了一些通用参数，例如device_id、user_id、app_id、设备平台（iOS or Android）等
    NSMutableString *commonParams = [NSMutableString string];
//    [commonParams appendFormat:@"&appid=%@", kJJAppID];
    return commonParams.copy;
}

#pragma mark - Helper

BOOL isEmptyString(NSString *string) {
    if (!string || ![string isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    return string.length == 0;
}

__attribute__((noinline)) id JJDynamicCastOrNil(id x, Class clz) {
    return ([x isKindOfClass:clz] ? x : nil);
}

@end
