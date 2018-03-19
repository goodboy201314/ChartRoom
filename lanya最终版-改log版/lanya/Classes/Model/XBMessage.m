/*!  头文件方法实现的基本信息。
 @file XBMessage.m
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/18 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import "XBMessage.h"


@implementation XBMessage

+(instancetype)messageWithName:(NSString *)name Content:(NSString *)content andType:(XBMessageType)type
{
    // 创建
    XBMessage *message =[[self alloc] init];
    // 赋值
    message.name = name;
    message.content = content;
    message.type = type;
    // 返回
    return message;
}
@end
