//
//  NecessaryConfig.m
//  ShYCache
//
//  Created by 杨淳引 on 16/10/11.
//  Copyright © 2016年 shayneyeorg. All rights reserved.
//

#import "NecessaryConfig.h"

@implementation NecessaryConfig

+ (NSString *)converDate:(NSDate *)mDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *str=[formatter stringFromDate:mDate];
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
        NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
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
    //假装从服务器取数据
    
    //假数据
    NSDictionary *res;
    NSDate *createTime = [NSDate date];
    res = @{
            @"result": @"000",
            @"desc": @"服务器返回的描述",
            @"createTime": [NecessaryConfig converDate:createTime]
            };
    
    //回调
    GMResponse *response = [GMResponse responseWithJsonDic:res];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        resultBlock(response);
    });
}

@end



