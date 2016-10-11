//
//  ViewController.m
//  ShYCache
//
//  Created by 杨淳引 on 16/10/11.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import "ViewController.h"
#import "ShYCacheManage.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *localInterfaceDisplayField;
@property (weak, nonatomic) IBOutlet UITextView *serverInterfaceDisplayField;
@property (weak, nonatomic) IBOutlet UIButton *firstLoadBtn;
@property (weak, nonatomic) IBOutlet UIButton *refreshLoadBtn;

@end

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [ShYCacheManage createAllTables];
}

#pragma mark - Interface

- (void)checkData:(NSString *)interfaceId loadType:(LoadType)loadType {
    __weak typeof(self) weakSelf = self;
    [TestData checkDataWithInterfaceId:interfaceId loadType:loadType callback:^(GMResponse *gmResponse) {
        if (gmResponse) {
            if ([gmResponse.code isEqualToString:RESPONSE_CODE_SUCCEED]) {
                //成功获取数据
                [weakSelf parseData:gmResponse interfaceId:interfaceId];
                
            } else if ([gmResponse.code isEqualToString:RESPONSE_CODE_NO_CHANGE]) {
                //接口告知数据无更新(只有Server类型接口会有此类型返回数据)
                GMLog(@"%@接口数据无更新，本地继续展示缓存数据", interfaceId);
                
            } else {
                GMLog(@"接口数据出错");
            }
            
        } else {
            GMLog(@"接口数据出错");
        }
    }];
}

- (void)parseData:(GMResponse *)gmResponse interfaceId:(NSString *)interfaceId {
    NSString *displayStr;
    if (gmResponse.isFromDB) {
        displayStr = [NSString stringWithFormat:@"数据来源：本地缓存\n产生时间：%@", gmResponse.jsonDic[KEY_CREATE_TIME]];
        
    } else {
        displayStr = [NSString stringWithFormat:@"数据来源：服务器\n产生时间：%@", gmResponse.jsonDic[KEY_CREATE_TIME]];
        //更新缓存
        [ShYCacheManage forceUpdateResponse:gmResponse interfaceId:interfaceId];
    }
    
    if ([interfaceId isEqualToString:LOCAL_TYPE_INTERFACE]) {
        self.localInterfaceDisplayField.text = displayStr;
        
    } else if ([interfaceId isEqualToString:SERVER_TYPE_INTERFACE]) {
        self.serverInterfaceDisplayField.text = displayStr;
        
    } else {
        GMLog(@"接口数据出错");
    }
    
    [self ableAllBtns];
}

#pragma mark - Button Action

- (IBAction)firstLoadData:(id)sender {
    GMLog(@"first load");
    [self enableAllBtns];
    [self checkData:LOCAL_TYPE_INTERFACE loadType:Load_Type_FirstLoad];
    [self checkData:SERVER_TYPE_INTERFACE loadType:Load_Type_FirstLoad];
}

- (IBAction)refreshLoadData:(id)sender {
    GMLog(@"refresh load");
    [self enableAllBtns];
    [self checkData:LOCAL_TYPE_INTERFACE loadType:Load_Type_PullRefresh];
    [self checkData:SERVER_TYPE_INTERFACE loadType:Load_Type_PullRefresh];
}

#pragma mark - Private

- (void)enableAllBtns {
    self.firstLoadBtn.userInteractionEnabled = NO;
    self.refreshLoadBtn.userInteractionEnabled = NO;
}

- (void)ableAllBtns {
    self.firstLoadBtn.userInteractionEnabled = YES;
    self.refreshLoadBtn.userInteractionEnabled = YES;
}

@end
