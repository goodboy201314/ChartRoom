/*!  头文件的基本信息。
 @file XBMessage.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/18 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <UIKit/UIKit.h>

/** 信息是自己的还是别人的 */
typedef enum {
    XBMessageTypeMe = 0,
    XBMessageTypeOther
} XBMessageType;


@interface XBMessage : NSObject
/**  姓名*/
@property (nonatomic,copy) NSString* name;
/**  发的信息内容  */
@property (nonatomic,copy) NSString* content;
/**  信息的类型  */
@property (nonatomic,assign) XBMessageType type;
/**  cell的高度  */
@property (nonatomic,assign) CGFloat cellHeight;

+(instancetype)messageWithName:(NSString *)name Content:(NSString *)content andType:(XBMessageType)type;
@end
