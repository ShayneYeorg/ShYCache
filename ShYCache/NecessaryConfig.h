//
//  NecessaryConfig.h
//  ShYCache
//
//  Created by 杨淳引 on 16/10/11.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define GMLog(format, ...) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(format),  ##__VA_ARGS__] )
#else
#define GMLog(format, ...)
#endif

#define KEY_RESULT                   @"result"
#define KEY_DESC                     @"desc"
#define KEY_LAST_CHECK_TIME          @"lastCheckTime"

typedef enum _LoadType {
    Load_Type_FirstLoad = 0,//首次加载
    Load_Type_PullRefresh,//下拉刷新
    Load_Type_LoadMore//加载更多
} LoadType;

@interface NecessaryConfig : NSObject

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dic;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+ (NSString *)converDate:(NSDate *)mDate;
+ (NSDate *)converDate:(NSString *)dateStr whithFormatter:(NSString *)formatterStr;

@end

@interface GMResponse : NSObject

@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *requestString;
@property (nonatomic, strong) NSString *cacheType;
@property (nonatomic, assign) BOOL isFromDB;//是否从数据库取出
@property (nonatomic, assign) BOOL isAvailable;//上页是否失效（加载更多）
@property (nonatomic, assign) BOOL isOutOfTime;//是否已过期（基础服务数据缓存使用）
@property (nonatomic, strong) NSDictionary *jsonDic;

/**
 *  获取一个响应对象
 *
 *  @param dic 经过Json解析的字典
 *
 *  @return 响应对象
 */
+ (GMResponse *)responseWithJsonDic:(NSDictionary *)dic;

@end

@interface TestData : NSObject

@end


