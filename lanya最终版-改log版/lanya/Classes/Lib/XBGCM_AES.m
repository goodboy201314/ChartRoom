/*!  头文件方法实现的基本信息。
 @file XBGCM_AES.m
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import "XBGCM_AES.h"
#import "IAGAesGcm.h"  // objc:  pod 'RNCryptor', '~> 3.0'

@implementation XBGCM_AES
+ (NSData *)encryptionData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi
{
    NSData *aad = nil;
    IAGCipheredData *cipheredData = [IAGAesGcm cipheredDataByAuthenticatedEncryptingPlainData:data
                                                              withAdditionalAuthenticatedData:aad
                                                                      authenticationTagLength:IAGAuthenticationTagLength128
                                                                         initializationVector:vi
                                                                                          key:key
                                                                                        error:nil];
    //    NSLog(@"%@",cipheredData);
    // 连接两个数组
    Byte *part1 = (Byte *)[cipheredData cipheredBuffer];
    Byte *part2 = (Byte *)[cipheredData authenticationTag];
    NSUInteger len1 =[cipheredData cipheredBufferLength];
    NSUInteger len2 =[cipheredData authenticationTagLength] ;
    Byte *bytes = (Byte *)malloc(len1+len2);
    for (int i=0; i<len1; i++) {
        bytes[i] = part1[i];
    }
    for (int i=0;i<len2;i++) {
        bytes[len1+i] = part2[i];
    }
    
    NSData *da = [[NSData alloc] initWithBytes:bytes length:len1+len2];
    return da;
}


+ (NSData *)encryptionString:(NSString *)string withKye:(NSData *)key andVi:(NSData *)vi
{
    NSData *expectedPlainData = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self encryptionData:expectedPlainData withKye:key andVi:vi];
}


+(NSData *)decryptionDataFromData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi
{
    NSUInteger len = [data length];
    NSUInteger len2 = 16;
    NSUInteger len1 = len-len2;
    
    Byte *b = (Byte *)[data bytes];
    Byte *p1 =  (Byte *)malloc(len1);
    Byte *p2 =  (Byte *)malloc(len2);
    for (int i=0; i<len1; i++) {
        p1[i] = b[i];
    }
    for (int i=0; i<len2; i++) {
        p2[i] = b[i+len1];
    }
    
    IAGCipheredData *cipheredData = [[IAGCipheredData alloc] initWithCipheredBuffer:p1 cipheredBufferLength:len1 authenticationTag:p2 authenticationTagLength:len2];
    NSData *aad = nil;
    //      NSLog(@"%@",cipheredData);
    
    NSData * plainData = [IAGAesGcm plainDataByAuthenticatedDecryptingCipheredData:cipheredData withAdditionalAuthenticatedData:aad initializationVector:vi key:key error:nil];
    //    NSLog(@"%@",plainData);
    return plainData;
    
    
}

+(NSString *)decryptionStringFromData:(NSData *)data withKye:(NSData *)key andVi:(NSData *)vi
{
    NSData *plainData = [self decryptionDataFromData:data withKye:key andVi:vi];
    NSString *str = [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    return str;
}
@end
