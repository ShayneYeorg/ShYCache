//
//  ShYCacheManage.m
//  Gmcchh
//
//  Created by 杨淳引 on 16/5/16.
//  Copyright © 2016年 KingPoint. All rights reserved.
//

#import "ShYCacheManage.h"

//拼接Key的用途
typedef enum _KeyPurpose {
    KeyPurpose_Normal = 1,      //用做存取Response或lastCheckTime的Key
    KeyPurpose_FuzzyQuery       //用做模糊查询时使用的Key
} KeyPurpose;

//初始时间
NSString *const CACHE_INITIAL_TIME      = @"0";

//缓存表字段
NSString *const CACHE_RESPONSE_CODE     = @"rspCode";     //响应编码
NSString *const CACHE_RESPONSE_DESC     = @"rspDesc";     //响应描述
NSString *const CACHE_RESPONSE_VALUE    = @"rspValue";    //响应JSON
NSString *const CACHE_SAVE_TIME         = @"saveTime";    //保存时间
NSString *const CACHE_INTERFACE_ID      = @"interfaceId"; //接口标识
NSString *const CACHE_SUPPLE_TERMS      = @"suppleTerms"; //其他条件(比如手机号、地市、分页的下标、条数等参数的拼接，可为空)

NSString *const DBFILE_NAME             = @"shycache.db";
static NSString *const CACHE_TABLE_NAME = @"cacheTable";
static int expireMin                    = 1; //CacheDataType_Local类型的数据过期的分钟数

@implementation ShYCacheManage

#pragma mark - 表相关方法

static FMDatabase *db = nil;

+ (void)createAllTables {
    [ShYCacheManage createDBFile];
    [ShYCacheManage createStoreTable];
}

+ (void)rebuildAllTables {
    if (!db) {
        [ShYCacheManage createDBFile];
    }
    if (![db open]) {
        return;
    }
    [db executeUpdate:[NSString stringWithFormat:@"DROP TABLE %@", CACHE_TABLE_NAME]];
    [ShYCacheManage createStoreTable];
}

+ (void)cleanAllData {
    if (!db) {
        [ShYCacheManage createDBFile];
    }
    if (![db open]) {
        return;
    }
    [db setShouldCacheStatements:YES];
    
    BOOL state = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", CACHE_TABLE_NAME]];
    if (state) {
        ShYLog(@"清除所有缓存---成功");
    } else {
        ShYLog(@"清除所有缓存---失败");
    }
}

#pragma mark - lastCheckTime

+ (void)updateLastCheckTime:(NSString *)lastCheckTime interfaceID:(NSString *)interfaceID {
    [ShYCacheManage updateLastCheckTime:lastCheckTime interfaceID:interfaceID otherKeys:nil];
}

+ (void)updateLastCheckTime:(NSString *)lastCheckTime interfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray {
    if (!lastCheckTime.length || !interfaceID.length) {
        ShYLog(@"%@接口不需更新lastCheckTime", interfaceID);
        return;
    }
    
    NSString *key;
    if (otherKeysArray.count) {
        NSMutableArray *keysArrayM = [[NSMutableArray alloc]init];
        [keysArrayM addObject:interfaceID];
        [keysArrayM addObjectsFromArray:otherKeysArray];
        key = [ShYCacheManage fabricateKey:keysArrayM purpose:KeyPurpose_Normal];
        
    } else {
        key = interfaceID;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:lastCheckTime forKey:key];
    [userDefaults synchronize];
    ShYLog(@"更新%@接口的lastCheckTime成功", interfaceID);
}

+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID {
    return [ShYCacheManage getLastCheckTimeByInterfaceID:interfaceID otherKeys:nil];
}

+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray {
    return [ShYCacheManage getLastCheckTimeByInterfaceID:interfaceID otherKeys:otherKeysArray loadType:0];
}

+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray loadType:(LoadType)loadType {
    if (loadType != Load_Type_FirstLoad || !interfaceID.length) {
        return CACHE_INITIAL_TIME;
    }
    
    NSString *key;
    if (otherKeysArray.count) {
        NSMutableArray *keysArrayM = [[NSMutableArray alloc]init];
        [keysArrayM addObject:interfaceID];
        [keysArrayM addObjectsFromArray:otherKeysArray];
        key = [ShYCacheManage fabricateKey:keysArrayM purpose:KeyPurpose_Normal];
        
    } else {
        key = interfaceID;
    }
    
    NSString *lastCheckTime = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!lastCheckTime) {
        lastCheckTime = CACHE_INITIAL_TIME;
    }
    return lastCheckTime;
}

#pragma mark - 新增、更新缓存

+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId {
    [ShYCacheManage forceUpdateResponse:response interfaceId:interfaceId otherResponseKeys:nil];
}

+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray {
    [ShYCacheManage forceUpdateResponse:response interfaceId:interfaceId otherResponseKeys:responseKeysArray otherLastCheckTimeKeys:nil];
}

+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray otherLastCheckTimeKeys:(NSArray *)lastCheckTimeKeysArray {
    [ShYCacheManage forceUpdateResponse:response interfaceId:interfaceId otherResponseKeys:responseKeysArray otherLastCheckTimeKeys:lastCheckTimeKeysArray shouldSaveLastCheckTime:YES];
}

+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray otherLastCheckTimeKeys:(NSArray *)lastCheckTimeKeysArray shouldSaveLastCheckTime:(BOOL)shouldSaveLastCheckTime {
    if (!response || response.isFromDB || !interfaceId.length) {
        return;
    }
    if (!db) {
        [ShYCacheManage createDBFile];
    }
    if (![db open]) {
        return;
    }
    [db setShouldCacheStatements:YES];
    
    NSString *saveTime = [NecessaryConfig converDate:[NSDate date]];
    NSString *value = nil;
    if (!response.jsonDic) {
        value = @"";
    } else {
        value = [NecessaryConfig jsonStringWithDictionary:response.jsonDic];
    }
    NSString *responseKey = @"";
    if (responseKeysArray.count) {
        NSMutableArray *responseKeysArrayM = [NSMutableArray arrayWithArray:responseKeysArray];
        responseKey = [ShYCacheManage fabricateKey:responseKeysArrayM purpose:KeyPurpose_Normal];
    }
    
    FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?", CACHE_TABLE_NAME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS], interfaceId, responseKey];
    if ([result next]) {
        BOOL state = [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ?, %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ?", CACHE_TABLE_NAME, CACHE_RESPONSE_CODE, CACHE_RESPONSE_DESC, CACHE_RESPONSE_VALUE, CACHE_SAVE_TIME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS], response.code, response.desc, value, saveTime, interfaceId, responseKey];
        if (state) {
            ShYLog(@"更新%@接口部分缓存---成功", interfaceId);
            if (response.jsonDic[KEY_LAST_CHECK_TIME] && shouldSaveLastCheckTime) {
                [ShYCacheManage updateLastCheckTime:response.jsonDic[KEY_LAST_CHECK_TIME] interfaceID:interfaceId otherKeys:lastCheckTimeKeysArray];
            }
            
        } else {
            ShYLog(@"更新%@接口部分缓存---失败", interfaceId);
        }
        
    } else {
        BOOL state = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@) VALUES(?, ?, ?, ?, ?, ?)", CACHE_TABLE_NAME, CACHE_RESPONSE_CODE, CACHE_RESPONSE_DESC, CACHE_RESPONSE_VALUE, CACHE_SAVE_TIME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS], response.code, response.desc, value, saveTime, interfaceId, responseKey];
        if (state) {
            ShYLog(@"新增%@接口缓存---成功", interfaceId);
            if (response.jsonDic[KEY_LAST_CHECK_TIME] && shouldSaveLastCheckTime) {
                [ShYCacheManage updateLastCheckTime:response.jsonDic[KEY_LAST_CHECK_TIME] interfaceID:interfaceId otherKeys:lastCheckTimeKeysArray];
            }
            
        } else {
            ShYLog(@"新增%@接口缓存---失败", interfaceId);
        }
    }
    
    [result close];
    [db close];
}

#pragma mark - 获取缓存

+ (GMResponse *)getResponseWithInterfaceId:(NSString *)interfaceId cacheDataType:(CacheDataType)cacheDataType {
    return [ShYCacheManage getResponseWithInterfaceId:interfaceId otherKeys:nil cacheDataType:cacheDataType];
}

+ (GMResponse *)getResponseWithInterfaceId:(NSString *)interfaceId otherKeys:(NSArray *)otherKeysArray cacheDataType:(CacheDataType)cacheDataType {
    GMResponse *response = nil;
    if (![db open]) {
        return response;
    }
    
    NSString *key = @"";
    if (otherKeysArray.count) {
        NSMutableArray *otherKeysArrayM = [NSMutableArray arrayWithArray:otherKeysArray];
        key = [ShYCacheManage fabricateKey:otherKeysArrayM purpose:KeyPurpose_Normal];
    }
    
    FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?", CACHE_TABLE_NAME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS], interfaceId, key];
    if ([result next]) {
        response = [[GMResponse alloc] init];
        response.code = [result stringForColumn:CACHE_RESPONSE_CODE];
        response.desc = [result stringForColumn:CACHE_RESPONSE_DESC];
        response.jsonDic = [NecessaryConfig dictionaryWithJsonString:[result stringForColumn:CACHE_RESPONSE_VALUE]];
        response.isFromDB = YES;
        response.isOutOfTime = NO;
        
        //基础服务数据需要判断缓存是否已过期失效(半小时)
        if (cacheDataType == CacheDataType_Local && [ShYCacheManage isLocalTypeDataOutOfTime:[result stringForColumn:CACHE_SAVE_TIME]]) {
            //过期
            response.isOutOfTime = YES;
            ShYLog(@"%@接口的数据已过期", interfaceId);
        }
        
        [result close];
        return response;
    }
    
    [result close];
    return response;
}

#pragma mark - 删除缓存

+ (void)deleteResponseWithInterfaceId:(NSString *)interfaceId {
    [ShYCacheManage deleteResponseWithInterfaceId:interfaceId otherKeys:nil];
}

+ (void)deleteResponseWithInterfaceId:(NSString *)interfaceId otherKeys:(NSArray *)otherKeysArray {
    if (!db) {
        [ShYCacheManage createDBFile];
    }
    if (![db open]) {
        return;
    }
    [db setShouldCacheStatements:YES];
    
    NSString *key = @"%%";
    if (otherKeysArray.count) {
        NSMutableArray *otherKeysArrayM = [NSMutableArray arrayWithArray:otherKeysArray];
        key = [ShYCacheManage fabricateKey:otherKeysArrayM purpose:KeyPurpose_FuzzyQuery];
    }
    
    BOOL state = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ LIKE ?", CACHE_TABLE_NAME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS], interfaceId, key];
    
    NSString *statement = [key isEqualToString:@"%%"]? @"全部": @"部分";
    if (state) {
        ShYLog(@"删除%@接口%@缓存---成功", interfaceId, statement);
    } else {
        ShYLog(@"删除%@接口%@缓存---失败", interfaceId, statement);
    }
}

#pragma mark - Private

+ (void)createDBFile {
    db = [FMDatabase databaseWithPath:[ShYCacheManage dbPath]];
}

+ (NSString *)dbPath {
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[array objectAtIndex:0] stringByAppendingPathComponent:DBFILE_NAME];
    ShYLog(@"缓存地址是: %@",path);
    return path;
}

+ (void)createStoreTable {
    if (!db) {
        [ShYCacheManage createDBFile];
    }
    if (![db open]) {
        return;
    }
    
    [db setShouldCacheStatements:YES];
    if (![db tableExists:CACHE_TABLE_NAME]) {
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE %@ (id INTEGER PRIMARY KEY, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT)", CACHE_TABLE_NAME, CACHE_RESPONSE_CODE, CACHE_RESPONSE_DESC, CACHE_RESPONSE_VALUE, CACHE_SAVE_TIME, CACHE_INTERFACE_ID, CACHE_SUPPLE_TERMS];
        [db executeUpdate:sql];
    }
    [db close];
}

//判断基础服务缓存数据是否已过期（半小时）
+ (BOOL)isLocalTypeDataOutOfTime:(NSString *)sDate {
    NSDate *saveDate = [NecessaryConfig converDate:sDate whithFormatter:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *expiredDate = [NSDate dateWithTimeInterval:expireMin*60 sinceDate:saveDate];
    NSTimeInterval interval = [expiredDate timeIntervalSinceDate:[NSDate date]];
    
    if (interval > 0) {
        return NO; //未过期
        
    } else {
        return YES; //已过期
    }
}

//构造key
+ (NSString *)fabricateKey:(NSMutableArray *)keyParams purpose:(KeyPurpose)purpose {
    if (purpose == KeyPurpose_Normal) {
        //构造lastCheckTime或Response存取使用的key
        [keyParams sortUsingComparator:^NSComparisonResult(NSString *param1, NSString *param2) {
            return [param1 compare:param2];
        }];
        NSMutableString *returnStr = [NSMutableString stringWithString:(NSString *)keyParams[0]];
        for (int i=1; i<keyParams.count; i++) {
            [returnStr appendString:[NSString stringWithFormat:@"-%@", keyParams[i]]];
        }
        return returnStr;
        
    } else if (purpose == KeyPurpose_FuzzyQuery) {
        //构造模糊查询时使用的key
        [keyParams sortUsingComparator:^NSComparisonResult(NSString *param1, NSString *param2) {
            return [param1 compare:param2];
        }];
        NSMutableString *returnStr = [NSMutableString stringWithFormat:@"%%%@%%", keyParams[0]];
        for (int i=1; i<keyParams.count; i++) {
            [returnStr appendString:[NSString stringWithFormat:@"%@%%", keyParams[i]]];
        }
        return returnStr;
    }
    return nil;
}

@end
