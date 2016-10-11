//
//  NecessaryConfig.m
//  ShYCache
//
//  Created by 杨淳引 on 16/10/11.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import "NecessaryConfig.h"
#import "ShYCacheManage.h"

@implementation NecessaryConfig

+ (NSString *)converDate:(NSDate *)mDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *str = [formatter stringFromDate:mDate];
    return str;
}

+ (NSDate *)converDate:(NSString *)dateStr whithFormatter:(NSString *)formatterStr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:formatterStr];
    NSDate *tDate=[formatter dateFromString:dateStr];
    return tDate;
}

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dic {
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    return nil;
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

@end

@implementation GMResponse

- (id)init {
    if (self=[super init]) {
        self.code = @"";
        self.desc = @"";
        self.isFromDB = NO;
        self.isOutOfTime = NO;
    }
    return self;
}

+ (GMResponse *)responseWithJsonDic:(NSDictionary *)dic {
    GMResponse *response = nil;
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        NSString *result = [dic objectForKey:KEY_RESULT];
        NSString *desc = [dic objectForKey:KEY_DESC];
        if (result.length > 0 && desc.length > 0) {
            response = [[GMResponse alloc] init];
            response.code = result;
            response.desc = desc;
            response.jsonDic = dic;
            response.isFromDB = NO;
        }
    }
    return response;
}

@end

@implementation TestData

+ (void)checkDataWithInterfaceId:(NSString *)interfaceId loadType:(LoadType)loadTpye callback:(ResponseBlock)resultBlock {
    if ([interfaceId isEqualToString:LOCAL_TYPE_INTERFACE]) {
        //一、local类型接口
        //1、先从缓存取数据
        GMResponse *gmResponse = [ShYCacheManage getResponseWithInterfaceId:interfaceId cacheDataType:CacheDataType_Local];
        
        if (loadTpye == Load_Type_PullRefresh) {
            //2、如果loadType是刷新，直接去服务器取数据
            [FakeServer checkDataWithInterfaceId:interfaceId lastCheckTime:nil callback:resultBlock];
            
        } else {
            //3、如果loadType是首次进入
            if (!gmResponse || gmResponse.isOutOfTime) {
                //4、缓存中无数据 || 从缓存取出的数据已超时过期
                //调取接口去服务器获取数据
                [FakeServer checkDataWithInterfaceId:interfaceId lastCheckTime:nil callback:resultBlock];
                
            } else {
                //5、从缓存取出的数据可用，直接回调
                resultBlock(gmResponse);
            }
        }
        
    } else if ([interfaceId isEqualToString:SERVER_TYPE_INTERFACE]) {
        //二、server类型的接口
        //1、先从缓存取数据，并取出lastCheckTime
        GMResponse *gmResponse = [ShYCacheManage getResponseWithInterfaceId:interfaceId cacheDataType:CacheDataType_Server];
        NSString *lastCheckTime = [ShYCacheManage getLastCheckTimeByInterfaceID:interfaceId otherKeys:nil loadType:loadTpye];
        
        if (loadTpye == Load_Type_PullRefresh) {
            //2、如果loadType是刷新，直接去服务器取数据
            [FakeServer checkDataWithInterfaceId:interfaceId lastCheckTime:lastCheckTime callback:resultBlock];
            
        } else {
            //3、如果loadType是首次进入
            //4、先判断是否有缓存
            if (!gmResponse) {
                //5、无缓存则lastCheckTime直接传0去服务器取数据
                [FakeServer checkDataWithInterfaceId:interfaceId lastCheckTime:CACHE_INITIAL_TIME callback:resultBlock];
                
            } else {
                //6、有缓存则先让页面展示缓存
                resultBlock(gmResponse);
                
                //7、传lastCheckTime去服务器校验缓存数据是否仍然有效
                [FakeServer checkDataWithInterfaceId:interfaceId lastCheckTime:lastCheckTime callback:resultBlock];
            }
        }
        
    } else {
        GMLog(@"从服务器获取数据出错");
    }
}

@end

//假装这是服务器
@implementation FakeServer

+ (void)checkDataWithInterfaceId:(NSString *)interfaceId lastCheckTime:(NSString *)lastCheckTime callback:(ResponseBlock)resultBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([interfaceId isEqualToString:LOCAL_TYPE_INTERFACE]) {
            //local类型接口
            NSDate *createTime = [NSDate date];
            NSDictionary *responseDic = @{
                                        @"result": @"000",
                                        @"desc": @"local类型的数据",
                                        @"createTime": [NecessaryConfig converDate:createTime]
                                        };
            GMResponse *response = [GMResponse responseWithJsonDic:responseDic];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                resultBlock(response);
            });
            
        } else if ([interfaceId isEqualToString:SERVER_TYPE_INTERFACE]) {
            //server类型接口
            
        }
        
    });
    
    
}

@end



