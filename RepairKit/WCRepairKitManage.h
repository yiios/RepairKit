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
 数据库数据修复-非加密

 @param corruptedDBPath 已损坏的数据库路径
 @param pageSize 损坏的数据库的页面大小。iOS上默认为4096。除非您可以调用PRAGMA page_size = NewPageSize来设置页面大小，否则页面大小不会改变。此外，您可以调用PRAGMA page_size来检查当前值，同时数据库没有损坏。
 @return 是否成功修复
 */
- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize;

/**
 数据库元数据备份-非加密

 @param corruptedDBPath 需备份的数据库路径
 @return 是否成功备份
 */
- (BOOL)backupDBPath:(NSString *)corruptedDBPath;

/**
 数据库数据修复-备份加密

 @param corruptedDBPath 已损坏的数据库路径
 @param pageSize 损坏的数据库的页面大小。iOS上默认为4096。除非您可以调用PRAGMA page_size = NewPageSize来设置页面大小，否则页面大小不会改变。此外，您可以调用PRAGMA page_size来检查当前值，同时数据库没有损坏。
 @param backupCipherStr 元数据备份的密码，若备份未加密，则为 nil
 @return 是否成功修复
 */
- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize backupCipher:(NSString *)backupCipherStr;

/**
 数据库元数据备份-备份加密

 @param corruptedDBPath 需备份的数据库路径
 @param backupCipherStr 元数据备份的密码，若备份未加密，则为 nil
 @return 是否成功备份
 */
- (BOOL)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr;

+ (instancetype)shareManage;

@end
