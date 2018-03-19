/*!  头文件的基本信息。
 @file XBCharaModel.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

// 这个模型是用来保存外部设备的写特征的
@interface XBCharaModel : NSObject
/**  外部设备的identitier  */
@property (nonatomic,copy) NSString* identity;
/**  外部设备的可以特征名字  */
@property (nonatomic,assign) id chara;

@end
