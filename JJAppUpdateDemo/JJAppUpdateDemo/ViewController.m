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

@property(nonatomic, strong) UIButton *downloadButtonError;
@property(nonatomic, strong) UIButton *downloadButtonNo;
@property(nonatomic, strong) UIButton *downloadButtonYes;

@property(nonatomic, strong) JJAppUpdateManager *updateManager;

@property(nonatomic, assign) BOOL mockHasError;
@property(nonatomic, assign) BOOL mockHasUpdate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupViews];
}

#pragma mark - Action

- (void)handleDownloadAction:(UIButton *)button {
    [self p_makeDebugDataByButton:button];
    
    @weakify(self);
    [self.updateManager requestAppUpdateInfo:^(BOOL hasError, NSString * _Nullable message, BOOL hasUpdate, NSString * _Nullable url) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            {
                [self p_showDebugDialog];
                return;
            }
            
            if (hasError) {
                [self.view makeToast:message ?: JJAppUpdateNetErrorMessage];
                return;
            }
            
            if (!hasUpdate) {
                [self.view makeToast:@"已是最新版本"];
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
    [self.view addSubview:self.downloadButtonError];
    [self.downloadButtonError mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(200, 80));
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(100);
    }];
    
    [self.view addSubview:self.downloadButtonNo];
    [self.downloadButtonNo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.centerX.equalTo(self.downloadButtonError);
        make.top.equalTo(self.downloadButtonError.mas_bottom).offset(100);
    }];
    
    [self.view addSubview:self.downloadButtonYes];
    [self.downloadButtonYes mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.centerX.equalTo(self.downloadButtonNo);
        make.top.equalTo(self.downloadButtonNo.mas_bottom).offset(100);
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

- (void)p_makeDebugDataByButton:(UIButton *)button {
    if (button == self.downloadButtonError) {
        self.mockHasError = YES;
    }
    
    if (button == self.downloadButtonNo) {
        self.mockHasError = NO;
        self.mockHasUpdate = NO;
    }
    
    if (button == self.downloadButtonYes) {
        self.mockHasError = NO;
        self.mockHasUpdate = YES;
    }
}

- (void)p_showDebugDialog {
    if (self.mockHasError) {
        [self.view makeToast:JJAppUpdateNetErrorMessage];
    } else if (!self.mockHasUpdate) {
        [self.view makeToast:@"已是最新版本"];
    } else {
        @weakify(self);
        [self p_showUpdateAlert:^{
            @strongify(self);
            [self.updateManager doUpdateWithURLString:@""];
        }];
    }
}

#pragma mark - Getter

- (JJAppUpdateManager *)updateManager {
    if (!_updateManager) {
        _updateManager = [[JJAppUpdateManager alloc] init];
    }
    return _updateManager;
}

- (UIButton *)downloadButtonError {
    if (!_downloadButtonError) {
        _downloadButtonError = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"下载（模拟网络错误）" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.backgroundColor = [UIColor blueColor];
            button.layer.cornerRadius = 6;
            [button addTarget:self action:@selector(handleDownloadAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _downloadButtonError;
}

- (UIButton *)downloadButtonNo {
    if (!_downloadButtonNo) {
        _downloadButtonNo = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"下载（模拟无更新）" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.backgroundColor = [UIColor blueColor];
            button.layer.cornerRadius = 6;
            [button addTarget:self action:@selector(handleDownloadAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _downloadButtonNo;
}

- (UIButton *)downloadButtonYes {
    if (!_downloadButtonYes) {
        _downloadButtonYes = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"下载（模拟有更新）" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.backgroundColor = [UIColor blueColor];
            button.layer.cornerRadius = 6;
            [button addTarget:self action:@selector(handleDownloadAction:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _downloadButtonYes;
}

@end
