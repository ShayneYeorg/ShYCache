//
//  DBManage2.h
//  Gmcchh
//
//  Created by 杨淳引 on 16/5/16.
//  Copyright © 2016年 KingPoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"
#import "FMDatabasePool.h"
#import <sqlite3.h>

//一些使用这套缓存的前提条件，实际使用时要对应具体项目里的具体内容
#import "NecessaryConfig.h"

//初始时间
UIKIT_EXTERN NSString *const CACHE_INITIAL_TIME;

//缓存表字段
UIKIT_EXTERN NSString *const CACHE_RESPONSE_CODE;  //响应编码
UIKIT_EXTERN NSString *const CACHE_RESPONSE_DESC;  //响应描述
UIKIT_EXTERN NSString *const CACHE_RESPONSE_VALUE; //响应JSON
UIKIT_EXTERN NSString *const CACHE_SAVE_TIME;      //保存时间
UIKIT_EXTERN NSString *const CACHE_INTERFACE_ID;   //接口标识
UIKIT_EXTERN NSString *const CACHE_SUPPLE_TERMS;   //其他条件(比如手机号、地市、分页的下标、条数等参数的拼接，可为空)

UIKIT_EXTERN NSString *const DBFILE_NAME;

typedef enum _CacheDataType{
    CacheDataType_Basic_Service = 0, //基础服务数据缓存(半小时失效)
    CacheDataType_Server_Local       //服务器本地数据缓存(失效时间由后台决定)
} CacheDataType;

@interface DBManage2 : NSObject

/* --------------------------- 表相关方法 --------------------------- */
+ (void)createAllTable;
+ (void)rebuildAllTable;
+ (void)cleanAllData;


/* ------------------------- lastCheckTime ------------------------ */
/**
 *  更新接口的最新更新时间(一般不需主动调用)
 *  (forceUpdateResponse相关方法里已调用updateLastCheckTime相关方法)
 *
 *  @param lastCheckTime      最新更新时间
 *  @param interfaceID        接口标识
 */
+ (void)updateLastCheckTime:(NSString *)lastCheckTime interfaceID:(NSString *)interfaceID;

/**
 *  更新接口的某个最新更新时间
 *  (有些接口可能需要保存多个lastCheckTime，将各个lastCheckTime的区分条件传入otherKeysArray)
 *
 *  @param lastCheckTime      最新更新时间
 *  @param interfaceID        接口标识
 *  @param otherKeysArray     辅助参数数组，元素是NSString对象
 */
+ (void)updateLastCheckTime:(NSString *)lastCheckTime interfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray;

/**
 *  获取接口的最新更新时间
 *
 *  @param interfaceID        接口标识
 */
+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID;

/**
 *  获取接口的某个最新更新时间
 *  (有些接口会有多个lastCheckTime，获取符合otherKeysArray条件的那个)
 *
 *  @param interfaceID        接口标识
 *  @param otherKeysArray   辅助参数数组，元素是NSString对象
 */
+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray;

/**
 *  获取接口的某个最新更新时间(考虑loadType)
 *  (当loadType不等于firstLoad的时候，返回0)
 *
 *  @param interfaceID        接口标识
 *  @param otherKeysArray   辅助参数数组，元素是NSString对象，不需辅助条件则传nil
 *  @param loadType           加载类型
 */
+ (NSString *)getLastCheckTimeByInterfaceID:(NSString *)interfaceID otherKeys:(NSArray *)otherKeysArray loadType:(LoadType)loadType;


/* ----------------------- 新增、更新缓存 ----------------------- */
/**
 *  新增或更新某个接口的所有缓存数据，并更新lastCheckTime
 *  (如果response中不包含lastCheckTime字段，则不更新lastCheckTime)
 *
 *  @param response                 响应体
 *  @param interfaceId              接口标识
 */
+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId;

/**
 *  新增或更新某个接口符合条件的缓存数据，并更新lastCheckTime
 *  (如果response中不包含lastCheckTime字段，则不更新lastCheckTime)
 *
 *  @param response                 响应体
 *  @param interfaceId              接口标识
 *  @param responseKeysArray        定位缓存的辅助条件
 */
+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray;

/**
 *  新增或更新某个接口符合条件的缓存数据，并更新某个lastCheckTime
 *  (如果response中不包含lastCheckTime字段，则不更新lastCheckTime)
 *
 *  @param response                  响应体
 *  @param interfaceId               接口标识
 *  @param responseKeysArray         定位缓存的辅助条件(可为nil)
 *  @param lastCheckTimeKeysArray    定位lastCheckTime的辅助条件
 */
+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray otherLastCheckTimeKeys:(NSArray *)lastCheckTimeKeysArray;

/**
 *  新增或更新某个接口符合条件的缓存数据，可指定是否更新lastCheckTime
 *  (如果response中不包含lastCheckTime字段，则不更新lastCheckTime)
 *
 *  @param response                  响应体
 *  @param interfaceId               接口标识
 *  @param responseKeysArray         定位缓存的辅助条件(可为nil)
 *  @param lastCheckTimeKeysArray    定位lastCheckTime的辅助条件(可为nil)
 *  @param shouldSaveLastCheckTime   是否要一并更新lastCheckTime
 */
+ (void)forceUpdateResponse:(GMResponse *)response interfaceId:(NSString *)interfaceId otherResponseKeys:(NSArray *)responseKeysArray otherLastCheckTimeKeys:(NSArray *)lastCheckTimeKeysArray shouldSaveLastCheckTime:(BOOL)shouldSaveLastCheckTime;


/* -------------------------- 获取缓存 -------------------------- */
/**
 *  根据接口标识获取缓存数据
 *
 *  @param interfaceId        接口标识
 *  @param cacheDataType      缓存数据类型
 *
 *  @return                   响应体对象
 */
+ (GMResponse *)getResponseWithInterfaceId:(NSString *)interfaceId cacheDataType:(CacheDataType)cacheDataType;

/**
 *  根据接口标识获取符合条件的缓存数据
 *
 *  @param interfaceId        接口标识
 *  @param otherKeysArray     定位缓存的辅助条件
 *  @param cacheDataType      缓存数据类型
 *
 *  @return                   响应体对象
 */
+ (GMResponse *)getResponseWithInterfaceId:(NSString *)interfaceId otherKeys:(NSArray *)otherKeysArray cacheDataType:(CacheDataType)cacheDataType;


/* -------------------------- 删除缓存 -------------------------- */
/**
 *  删除某个接口的所有缓存数据
 *
 *  @param interfaceId        接口标识
 */
+ (void)deleteResponseWithInterfaceId:(NSString *)interfaceId;

/**
 *  删除某个接口中符合条件的缓存数据
 *
 *  @param interfaceId        接口标识
 *  @param otherKeysArray     定位缓存的辅助条件
 */
+ (void)deleteResponseWithInterfaceId:(NSString *)interfaceId otherKeys:(NSArray *)otherKeysArray;

@end


