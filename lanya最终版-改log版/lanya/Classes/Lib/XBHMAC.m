/*!  头文件方法实现的基本信息。
 @file XBHMAC.m
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import "XBHMAC.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation XBHMAC
+ (NSData *)encryptionHMAC:(NSData *)data withKey:(NSData *)k
{
    Byte *b1 = (Byte *)[data bytes];
    NSUInteger len1 = [data length];
    NSMutableString* output1 = [NSMutableString stringWithCapacity:len1 * 2];
    for(int i = 0; i < len1; i++)
        [output1 appendFormat:@"%02x", b1[i]];
    
    
    Byte *b2 = (Byte *)[k bytes];
    NSUInteger len2 = [k length];
    NSMutableString* output2 = [NSMutableString stringWithCapacity:len2 * 2];
    for(int i = 0; i < len2; i++)
        [output2 appendFormat:@"%02x", b2[i]];
    
    
    //    NSString *key =[[NSString alloc] initWithData:k encoding:NSUTF8StringEncoding];
    //    NSString *plaintext =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    const char *cKey  = [output2 cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [output1 cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    return [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
    
}
@end
