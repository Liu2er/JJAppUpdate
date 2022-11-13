//
//  ViewController.m
//  JJAppUpdateDemo
//
//  Created by Liujiajie on 2022/11/12.
//

#import "ViewController.h"
#import <JJAppUpdateSDK/JJAppUpdateManager.h>
#import <Masonry/Masonry.h>
#import <Toast/Toast.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface ViewController ()

@property(nonatomic, strong) UIButton *downloadButton;

@property(nonatomic, strong) JJAppUpdateManager *updateManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupViews];
}

#pragma mark - Action

- (void)handleDownloadAction:(UIButton *)button {
    @weakify(self);
    [self.updateManager requestAppUpdateInfo:^(BOOL hasError, NSString * _Nullable message, BOOL hasUpdate, NSString * _Nullable url) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (hasError) {
                [self.view makeToast:message ?: JJAppUpdateNetErrorMessage];
                return;
            }
            
            if (!hasUpdate) {
                [self.view makeToast:JJAppUpdateResultNO];
                return;
            }
            
            [self p_showUpdateAlert:^{
                @strongify(self);
                [self.updateManager doUpdateWithURLString:url];
            }];
        });
    }];
}

#pragma mark - Private

- (void)p_setupViews {
    [self.view addSubview:self.downloadButton];
    [self.downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(200, 80));
        make.center.equalTo(self.view);
    }];
}

- (void)p_showUpdateAlert:(void(^)(void))updateAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:@"发现新版本"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"去更新"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        JJBLOCK_INVOKE(updateAction);
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Getter

- (JJAppUpdateManager *)updateManager {
    if (!_updateManager) {
        _updateManager = [[JJAppUpdateManager alloc] init];
    }
    return _updateManager;
}

- (UIButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"下载" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.backgroundColor = [UIColor blueColor];
            button.layer.cornerRadius = 6;
            [button addTarget:self action:@selector(handleDownloadAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _downloadButton;
}

@end
