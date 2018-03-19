/*!  头文件的基本信息。
 @file XBDataConversionFactory.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface XBDataConversionFactory : NSObject
/**
 *  将NSData类型的数据转换为NSString类型的数据
 *   NSData -> NSString
 *
 *  @param data NSData类型的数据
 *
 *  @return NSString类型的数据
 */
+ (NSString*)getStringFromData:(NSData *)data;

/**
 *  将NSString类型的数据转换为NSData类型的数据
 *  NSString -> NSData
 *
 *  @param string NSString类型的数据
 *
 *  @return NSData类型的数据
 */
+ (NSData *)getDataFromString:(NSString *)string;

/**
 *  从十六进制的NSData中得到字符串
 *
 *  @param data <#data description#>
 *
 *  @return <#return value description#>
 */
+ (NSString *)getStringFromHexadecimalData:(NSData *)data;

/**
 *  从字符串中恢复出十六进制的NSData
 *
 *  @param string string description
 *
 *  @return return value description
 */
+ (NSData *)getHexadecimalDataFromString:(NSString *)hexString;
@end
