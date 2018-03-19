/*!  头文件的基本信息。
 @file XBDeviceModel.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2017/10/17 Creation (此文档的版本信息)
   Copyright © 2017年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>
// 设备的类型 - 枚举
typedef enum {
    kDeviceKindCenter = 0,
    kDeviceKindPeripheral = 1
}DeviceKind;

// 这个模型是用来保存设备的类型的，中心或者外设
@interface XBDeviceModel : NSObject
/** 设备的名字 */
@property (nonatomic,copy) NSString* deviceNme;
/** 设备 ,可能是中心，可能是外设，使用时根据kind字段判断 */
@property (nonatomic,strong) id device;
/** 设备的类型 */
@property (nonatomic,assign) DeviceKind dKind;

@end
