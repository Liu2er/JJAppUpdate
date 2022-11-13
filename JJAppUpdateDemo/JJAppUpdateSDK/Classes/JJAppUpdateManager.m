//
//  JJAppUpdateManager.m
//  JJAppUpdateSDK
//
//  Created by Liujiajie on 2022/11/12.
//

#import "JJAppUpdateManager.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const JJAppUpdateNetErrorMessage = @"网络异常，请稍后重试";
NSString * const JJAppUpdateResultNO = @"已是最新版本";

#define JJDynamicCast(x, c) ((c *)(JJDynamicCastOrNil(x, [c class])))

@interface JJAppUpdateManager ()

@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation JJAppUpdateManager

- (void)requestAppUpdateInfo:(RequestCompletionBlock)completion {
    // 利用 Mac 自带的 apachectl 命令开启一个本地服务，手机与电脑处于同一网络时可通过 Mac 的 IP 地址直接访问该服务上的资源
    NSURL *url = [NSURL URLWithString:@"http://192.168.0.145/appupdate.json"];
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
        
        NSDictionary *extraDict = JJDynamicCast(jsonDict[@"extra"], NSDictionary);
        
        NSNumber *status = JJDynamicCast(jsonDict[@"status"], NSNumber);
        if (status && status.intValue != 0) {
            NSString *message = JJDynamicCast(extraDict[@"message"], NSString);
            JJBLOCK_INVOKE(completion, YES, message ?: JJAppUpdateNetErrorMessage, NO, nil);
            return;
        }
        
        NSNumber *hasUpdate = JJDynamicCast(extraDict[@"has_update"], NSNumber);
        if (hasUpdate) {
            JJBLOCK_INVOKE(completion, NO, nil, hasUpdate.boolValue, JJDynamicCast(extraDict[@"open_url"], NSString));
            return;
        }
        
        JJBLOCK_INVOKE(completion, NO, nil, NO, nil);
        return;
    }];
    [task resume];
    self.task = task;
}

- (void)doUpdateWithURLString:(NSString *)url {
    // 如果是直接安装新包，新包打开时理应有 SSO 校验和定位校验，进一步增进安装包的安全性
    if (isEmptyString(url)) {
        url = @"https://apps.apple.com/cn/app/tao-bao-taobao-for-iphone/id387682726";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (NSString *)commonParams {
    // 这里存储了一些通用参数，例如device_id、user_id、app_id、设备平台（iOS or Android）等
    NSMutableString *commonParams = [NSMutableString stringWithFormat:@"app_id=%@", @"1128"];
    [commonParams appendFormat:@"&device_id=%@", @"1825627186151208"];
    /*
     * 还有些其它参数
     */
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
