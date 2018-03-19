/*!  头文件的基本信息。
 @file XBGCM_AES.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface XBGCM_AES : NSObject
/**
 *  用密钥key和向量vi加密字符串string
 *
 *  @param string 待加密的字符串
 *  @param key    密钥
 *  @param vi     向量
 *
 *  @return 加密后的结果：密文和认证信息的连接
 */
+ (NSData *)encryptionString:(NSString *)string withKye:(NSData *)key andVi:(NSData *)vi;



/**
 *  用密钥key和向量vi加密数据data
 *
 *  @param data 待加密的数据
 *  @param key  密钥
 *  @param vi   向量
 *
 *  @return 密文和认证信息的连接
 */
+ (NSData *)encryptionData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi;


/**
 *  从data中解密出字符串
 *
 *  @param data 待解密的数据data
 *
 *  @return 解密后的字符串
 */
+(NSString *)decryptionStringFromData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi;

/**
 *  从data中解密出打data
 *
 *  @param data 待解密的数据data
 *
 *  @return 解密后的data
 */
+(NSData *)decryptionDataFromData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi;
@end
