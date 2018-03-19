/*!  头文件的基本信息。
 @file XBSHA.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface XBSHA : NSObject
/**
 *  基本的hash
 *
 *  @return 结果：十六进制的字符串显示
 */
+ (NSString *) encryptionSHA1WithString:(NSString *)string;


/**
 *  224位的hash
 *
 *  @return 结果：十六进制的字符串显示
 */
+ (NSString *) encryptionSHA224WithString:(NSString *)string;


/**
 *  256位hash
 *
 *  @return 结果：十六进制的字符串显示
 */
+ (NSString *) encryptionSHA256WithString:(NSString *)string;


/**
 *  384位hash
 *
 *  @return 结果：十六进制的字符串显示
 */
+ (NSString *) encryptionSHA384WithString:(NSString *)string;


/**
 *  512位hash
 *
 *  @return 结果：十六进制的字符串显示
 */
+ (NSString *) encryptionSHA512WithString:(NSString *)string;


/**
 *  通过hash得到32位的bytes
 *
 *  @param string 传入的字符串
 *
 *  @return 32byte数组
 */
+ (NSData *)bytesOfSHA256WithString:(NSString *)string;
@end
