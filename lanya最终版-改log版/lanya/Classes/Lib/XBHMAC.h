/*!  头文件的基本信息。
 @file XBHMAC.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface XBHMAC : NSObject
/**
 *  加密方式,MAC算法: HmacSHA256
 *
 *  @param plaintext 要加密的文本
 *  @param key       秘钥
 *
 *  @return 加密后的字符串
 */
//+ (NSString *)encryptionHMAC:(NSString *)plaintext withKey:(NSString *)key;

+ (NSData *)encryptionHMAC:(NSData *)data withKey:(NSData *)k;
@end
