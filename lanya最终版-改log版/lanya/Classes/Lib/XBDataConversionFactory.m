/*!  头文件方法实现的基本信息。
 @file XBDataConversionFactory.m
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import "XBDataConversionFactory.h"

@implementation XBDataConversionFactory
+ (NSString*)getStringFromData:(NSData *)data
{
    return  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


+ (NSData *)getDataFromString:(NSString *)string
{
    return [string dataUsingEncoding: NSUTF8StringEncoding];
}

/**
 *  从十六进制的NSData中得到字符串
 *
 *  @param data data description
 *
 *  @return return value description
 */
+ (NSString *)getStringFromHexadecimalData:(NSData *)data
{
    //    NSUInteger len = [data length];
    //    Byte *digest = (Byte *)[data bytes];
    //    NSMutableString *m = [NSMutableString string];
    //    for (int i=0; i<len; i++) {
    //         [m appendFormat:@"%02x,",digest[i]];
    //    }
    //    return m;
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

/**
 *  从字符串中恢复出十六进制的NSData
 *
 *  @param string string description
 *
 *  @return return value description
 */
+ (NSData *)getHexadecimalDataFromString:(NSString *)str
{
    //    NSUInteger len = [hexString length];
    //    Byte bytes[len/2];
    //    int j=0;
    //    for(int i=0;i<len;i++) {
    //        int int_ch1;
    //        unichar hex_char1 = [hexString characterAtIndex:i];
    //        if(hex_char1 >= '0' && hex_char1 <='9')
    //            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
    //        else if(hex_char1 >= 'A' && hex_char1 <='F')
    //            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
    //        else
    //            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
    //
    //        i++;
    //        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
    //        int int_ch2;
    //        if(hex_char2 >= '0' && hex_char2 <='9')
    //            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
    //        else if(hex_char1 >= 'A' && hex_char1 <='F')
    //            int_ch2 = hex_char2-55; //// A 的Ascll - 65
    //        else
    //            int_ch2 = hex_char2-87; //// a 的Ascll - 97
    //
    //        int int_ch = int_ch1+int_ch2;
    //        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
    //        j++;
    //    }
    //
    //    NSData *newData = [[NSData alloc] initWithBytes:bytes length:len/2];
    //    return newData;
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}
@end
