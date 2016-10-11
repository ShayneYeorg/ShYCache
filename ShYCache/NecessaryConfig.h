//
//  NecessaryConfig.h
//  ShYCache
//
//  Created by 杨淳引 on 16/10/11.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GMResponse;

#ifdef DEBUG
#define GMLog(format, ...) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(format),  ##__VA_ARGS__] )
#else
#define GMLog(format, ...)
#endif

#define KEY_RESULT                   @"result"
#define KEY_DESC                     @"desc"
#define KEY_CREATE_TIME              @"createTime"
#define KEY_LAST_CHECK_TIME          @"lastCheckTime"

#define LOCAL_TYPE_INTERFACE         @"local_type_interface"
#define SERVER_TYPE_INTERFACE        @"server_type_interface"

#define RESPONSE_CODE_SUCCEED        @"000" //业务成功
#define RESPONSE_CODE_NO_CHANGE      @"101" //暂无数据变更

typedef void (^ResponseBlock)(GMResponse *gmResponse);
typedef enum _LoadType {
    Load_Type_FirstLoad = 0, //首次进入加载
    Load_Type_PullRefresh,   //下拉刷新数据
    Load_Type_LoadMore       //上拉加载更多
} LoadType;

@interface NecessaryConfig : NSObject

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+ (NSString *)converDate:(NSDate *)mDate;
+ (NSDate *)converDate:(NSString *)dateStr whithFormatter:(NSString *)formatterStr;

@end

@interface GMResponse : NSObject

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, assign) BOOL isFromDB; //是否从数据库取出
@property (nonatomic, assign) BOOL isOutOfTime; //是否已过期（local类型缓存使用）
@property (nonatomic, strong) NSDictionary *jsonDic;

+ (GMResponse *)responseWithJsonDic:(NSDictionary *)dic;

@end

@interface TestData : NSObject

+ (void)checkDataWithInterfaceId:(NSString *)interfaceId loadType:(LoadType)loadTpye callback:(ResponseBlock)resultBlock;

@end


