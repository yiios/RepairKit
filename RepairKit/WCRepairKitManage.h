//
//  WCRepairKitManage.h
//  RepairKitDemo
//
//  Created by Limo on 2018/6/12.
//  Copyright © 2018年 Limo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCRepairKitManage : NSObject


/**
 数据库元数据备份-不加密备份
 
 @param corruptedDBPath 需备份的数据库路径
 @return 是否成功备份
 */
- (BOOL)backupDBPath:(NSString *)corruptedDBPath;


/**
 数据库元数据备份-加密备份
 
 @param corruptedDBPath 需备份的数据库路径
 @param backupCipherStr 元数据备份的密码，若不加密备份，则为 nil
 @return 是否成功备份
 */
- (BOOL)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr;

/**
 数据库元数据备份
 
 @param corruptedDBPath 需备份的数据库路径
 @param corruptedDBCipherStr 数据库的密码，若数据库不加密，则为 nil
 @param backupCipherStr 数据备份的密码，若不加密备份，则为 nil
 @param error 传入error指针即可获取错误对象
 @return 元数据备份路径，如果为nil则说明备份失败！
 */
- (NSString *)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr error:(NSError **)error;

/**
 数据库数据修复-备份不加密-替换损坏数据库-数据库PageSize默认4096
 
 @param corruptedDBPath 已损坏的数据库路径
 @return 是否成功修复
 */
- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath;

/**
 数据库数据修复-替换损坏数据库-数据库PageSize默认4096
 
 @param corruptedDBPath 已损坏的数据库路径
 @param backupCipherStr 元数据备份的密码，若备份不加密，则传 nil
 @return 是否成功修复
 */
- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr;

/**
 数据库数据修复
 
 @param corruptedDBPath 已损坏的数据库路径
 @param pageSize 损坏的数据库的页面大小。iOS上默认为4096。除非您可以调用PRAGMA page_size = NewPageSize来设置页面大小，否则页面大小不会改变。此外，您可以调用PRAGMA page_size来检查当前值，同时数据库没有损坏。
 @param corruptedDBCipherStr 数据库的密码，若数据库不加密，则为 nil
 @param backupCipherStr 元数据备份的密码，若备份不加密，则为 nil
 @param isOverwriteFile 是否替换损坏数据库文件
 @param error 传入error指针即可获取错误对象
 @return 修复后的数据库路径，如果为nil则说明修复失败！
 */
- (NSString *)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize corruptedDBCipher:(NSString *)corruptedDBCipherStr backupCipher:(NSString *)backupCipherStr isOverwriteFile:(BOOL)isOverwriteFile error:(NSError **)error;


/**
 使用SQLite check指令检查数据库完整性
 
 @param dbPath 需检查的数据库路径
 @param isQuick 是否执行快速检查 如果为YES 则执行 "PRAGMA quick_check;" 执行整个库的完全性检查，略去了对索引内容与表内容匹配的校验。 如果为NO 则执行 "PRAGMA integrity_check; " 执行整个库的完全性检查，会查看错序的记录、丢失的页，毁坏的索引等。
 @param error 传入error指针即可获取错误对象
 @return 数据库是否完整
 */
- (BOOL)sqliteCheckIntegrityDB:(NSString *)dbPath isQuick:(BOOL)isQuick error:(NSError **)error;


/**
 使用RepairKit api检查数据库完整性
 
 @param dbPath 需检查的数据库路径
 @param corruptedDBCipherStr 数据库的密码，若数据库不加密，则传 nil
 @param error 传入error指针即可获取错误对象
 @return 数据库是否完整
 */
- (BOOL)repairKitCheckIntegrityDB:(NSString *)dbPath corruptedDBCipher:(NSString *)corruptedDBCipherStr error:(NSError **)error;

/**
 检查备份是否存在
 
 @param corruptedDBPath 需检查的原始数据库路径
 @param error 传入error指针即可获取错误对象
 @return 数据库备份是否存在
 */
- (BOOL)backupExistsAtDBPath:(NSString *)corruptedDBPath error:(NSError **)error;

+ (instancetype)shareManage;

@end
