//
//  XBChatViewController.m
//  lanya
//
//  Created by xiangbin on 2017/10/16.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBConnectionViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Message.pbobjc.h"
#import "Sib.pbobjc.h"
#import "XBCharaModel.h"
#import "XBDeviceModel.h"
#import "XBDataConversionFactory.h"
#import "gmp-iPhoneOS.h"
#import "pbc.h"
#import "pbc_test.h"
#import "XBGCM_AES.h"
#import "XBHMAC.h"
#import "XBSHA.h"
#import <AVFoundation/AVFoundation.h>
#import "SVProgressHUD.h"
#import "JBScanCode.h"
#import "JBAddThirdPart.h"
#import "JBDeviceCell.h"
#import "XBChatRoomViewController.h"


// 定义调试阶段打印的宏，调试结束后，直接注释掉
#define XBLog(...) NSLog(__VA_ARGS__)
#define SCANVIEWH 50

#pragma mark - 相关的静态变量
/** 服务字符串 */
static NSString *const serviceUUIDString = @"A55DB3D0-4C7B-3E8D-E23C-0E9A9C6FE1EF";
/** 特征字符串 */
static NSString *const characteristicUUIDString = @"72A7700C-859D-4317-9E35-D7F5A93005B1";
/** 自己作为外设广播的随机数 */
static NSString *randNumberString = nil;

#pragma mark - ======== 密钥协商过程中的参数（START） ==========
pairing_t pairing;
element_t P,a,Pa,b,Pb,c,Pc;
element_t out1,out2,out3;
/** BLE_SEND_MAX_LEN是蓝牙单次可处理最大字节长度 */
const int BLE_SEND_MAX_LEN = 160;

/** 用户的种类，协议认证过程中使用 */
typedef enum {
    kUserKindNone = 0,
    kUserKindA ,
    kUserKindB ,
    kUserKindC,
}UserKind;


@interface XBConnectionViewController ()<CBPeripheralManagerDelegate,CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate,JBScanCodeDelegate,JBAddThirdPartDelegate,XBChatRoomViewControllerDelegate>

#pragma mark - 外设相关的变量
/** 外设的服务，供外设使用的，中心不要乱用，会错 */
@property (nonatomic,strong) NSMutableArray* serviceArray;
/** 外设管理者 */
@property (nonatomic,strong) CBPeripheralManager* peripheralMgr;
/** iOS会发两次广播，第一次要忽略掉 */
@property (nonatomic,assign) BOOL isSecondBroadcast;
/** 订阅的特征，供外设使用的字段 */
@property (atomic,strong) id subscriptionChara;

#pragma mark - 中心管理者相关的变量
/** 中心管理者 */
@property (nonatomic,strong) CBCentralManager* centerMgr;
/** 仅仅是扫描到的是iOS设备用的，使用该变量确定是第一次发的广播包，还是第二次发的广播包 */
@property (nonatomic,strong) NSMutableArray* otherArray;
/** 用来防止重复连接的数组，已经连接的设备发送的随机数会被存储，这样下次遇到相同的就知道该设备已经连接上了 */
@property (nonatomic,strong) NSMutableArray *numsArray;
/** 中心设备保存的连接到的外部设备写特征字段的数组  */
@property (nonatomic,strong) NSMutableArray *writeCharas;

#pragma mark - 中心和外设都可以使用的变量
/** 扫描到的外设数组集合 */
@property (nonatomic,strong) NSMutableArray* peripheralArray;
/** 扫描到的中心数组集合 */
@property (nonatomic,strong) NSMutableArray* centersArray;
/** 数据模型数组 */
@property (nonatomic,strong) NSMutableArray* devicesModelArray;

#pragma mark - 通信过程中要用到的变量
/** 分块发送的数据 */
@property (nonatomic,strong) NSMutableData* mdata;
/** 用户的种类 */
@property (nonatomic,assign) UserKind userKind;
// 两人
@property (nonatomic,strong) C3* dataABC_m1;  // 两人，三人公用的
@property (nonatomic,strong) C3* dataAB_m2;
// 三人
@property (nonatomic,strong) C3P* dataABC_m2;
@property (nonatomic,strong) C4P* dataABC_m3;
@property (nonatomic,strong) C3P* dataABC_m4;
@property (nonatomic,assign) bool isThirdPartWantsToJoin;

#pragma mark - 二维码相关的变量
/** 标记当前是否显示了二维码窗口 */
@property (nonatomic,assign) bool isCodeWindowShow;
/** 二维码窗口的指针 */
@property (nonatomic,strong) UIView* codeView;
/** 标记当前是否显示了扫描二维码窗口 */
@property (nonatomic,assign) bool isScanCodeWindowShow;
/** 扫描二维码窗口的指针 */
@property (nonatomic,strong) UIView* scanCodeView;
@property (nonatomic,assign) bool isThirdPartWindowShow;
/** 扫描二维码窗口的指针 */
@property (nonatomic,strong) UIView* thirdPartView;
/** keyData */
@property (nonatomic,strong) NSData* keysData;
@property (nonatomic, weak) AVCaptureSession *session;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *layer;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
/**  最终的会话密码  */
@property (nonatomic,copy) NSString* sessionKey;
/**  聊天室的控制器  */
@property (nonatomic,strong) XBChatRoomViewController *chatRoomVC;
@end

@implementation XBConnectionViewController
#pragma mark - 各种懒加载
- (NSMutableArray *)writeCharas
{
    if(!_writeCharas) {
        _writeCharas = [NSMutableArray array];
    }
    return _writeCharas;
}

-(NSMutableArray *)numsArray
{
    if(!_numsArray) {
        _numsArray = [NSMutableArray array];
    }
    return _numsArray;
}

- (NSMutableData *)mdata
{
    if(!_mdata) {
        _mdata = [NSMutableData data];
    }
    return _mdata;
}

- (NSMutableArray *)devicesModelArray
{
    if(!_devicesModelArray) {
        _devicesModelArray = [NSMutableArray array];
    }
    return _devicesModelArray;
}


- (NSMutableArray *)otherArray
{
    if(!_otherArray) {
        _otherArray = [NSMutableArray array];
    }
    return _otherArray;
}

- (NSMutableArray *)peripheralArray
{
    if(!_peripheralArray) {
        _peripheralArray = [NSMutableArray array];
    }
    return _peripheralArray;
}

-(NSMutableArray *)centersArray
{
    if(!_centersArray) {
        _centersArray = [NSMutableArray array];
    }
    return _centersArray;
}

-(NSMutableArray *)serviceArray
{
    if(!_serviceArray) {
        _serviceArray = [NSMutableArray array];
    }
    return _serviceArray;
}

/** 懒加载 - 中心管理器 */
-(CBCentralManager *)centerMgr
{
    if(!_centerMgr) {
        _centerMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:YES]}];
    }
    return _centerMgr;
    
}

/** 懒加载 - 外设管理器 */
- (CBPeripheralManager *)peripheralMgr
{
    if(!_peripheralMgr) {
        _peripheralMgr = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:YES]}];
    }
    return  _peripheralMgr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 取消UITableView的分割线
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 开启外设
    [self peripheralMgr];
    // 开启中心
    [self centerMgr];
}
#pragma mark - 以上方法都不用改动
#pragma mark =======================================================

/** 给指定的蓝牙设备发送信息 */
- (void)sendProtolMessage:(NSData *)msgData toOneDeviceModel:(XBDeviceModel *)model
{
    dispatch_queue_t  queue= dispatch_queue_create("com.xingbin.lanya.queue", NULL);
    if([model dKind]==kDeviceKindCenter) {   //中心设备
        dispatch_async(queue, ^{
            CBCentral *c  = (CBCentral *)[model device];
            [self splitMessageData:msgData toCenter:c orPeripheral:nil];
        });
    }else {  // 外设
        dispatch_async(queue, ^{
            CBPeripheral *peripheral = (CBPeripheral *)[model device];
            [self splitMessageData:msgData toCenter:nil orPeripheral:peripheral];
        });
    }
}

/** 发送信息给连接的所有设备 */
- (void)sendProtolMessage:(NSData *)msgData
{
    dispatch_queue_t  queue= dispatch_queue_create("com.xiangbin.lan.queue2", NULL);
    for(int i=0;i<self.devicesModelArray.count;i++) {
        int t = [self.devicesModelArray[i] dKind];
        if(t==kDeviceKindCenter) {
            // 外面并行执行，内部串行执行
            dispatch_async(queue, ^{
                CBCentral *c  = (CBCentral *)[self.devicesModelArray[i] device];
                [self splitMessageData:msgData toCenter:c orPeripheral:nil];
            });
        } else {
            // 外面并行执行，内部串行执行
            dispatch_async(queue, ^{
                CBPeripheral *peripheral = (CBPeripheral *)[self.devicesModelArray[i] device];
                [self splitMessageData:msgData toCenter:nil orPeripheral:peripheral];
            });
        }
        usleep(1000*1000);
    }
}

/** 信息分包发送 */
-(void)splitMessageData:(NSData *)msgData toCenter:(CBCentral *)c orPeripheral:(CBPeripheral *)p
{
    dispatch_queue_t  queue= dispatch_queue_create("com.xiangbin.lanya.queue3", NULL);
    for (int i = 0; i < [msgData length]; i += BLE_SEND_MAX_LEN) {
        // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
        NSData *subData;
        if ((i + BLE_SEND_MAX_LEN) < [msgData length]) {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
            subData = [msgData subdataWithRange:NSRangeFromString(rangeStr)];
        }
        else {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([msgData length] - i)];
            subData = [msgData subdataWithRange:NSRangeFromString(rangeStr)];
        }
        dispatch_async(queue, ^{
            DataTransfer *trans = [DataTransfer new];
            trans.data_p =subData;
            Frame *f = [Frame new];
            f.dataTransfer = trans;
            NSData *d = [f data];
            p==nil?[self sendMessage:d toCenters:[NSArray arrayWithObject:c]]:[self sendMessage:d toPeripheral:p];
        });
        usleep(100*1000);
        
    } // end of for
    
    dispatch_async(queue, ^{
        DataTransfer *trans = [DataTransfer new];
        // 每一条信息以 “xiangbin”结尾
        trans.data_p =[XBDataConversionFactory getDataFromString:@"xiangbin"];
        
        Frame *f = [Frame new];
        f.dataTransfer = trans;
        
        NSData *d = [f data];
        p==nil?[self sendMessage:d toCenters:[NSArray arrayWithObject:c]]:[self sendMessage:d toPeripheral:p];
    });
    usleep(100*1000);
}


// 生成32字节长度的Key
- (NSData *)generate32BytesKey
{
    return  [XBSHA bytesOfSHA256WithString:[self genRandomLengthString]];
}

// 生成12字节长度的IV
- (NSData*)generate12BytesIv
{
    NSData * data = [XBSHA bytesOfSHA256WithString:[self genRandomLengthString]];
    Byte b[12];
    Byte *byte = (Byte *)[data bytes];
    for (int i=0; i<12; i++) {
        b[i] = byte[i];
    }
    return [NSData dataWithBytes:b length:12];
}

- (NSData*)generate12BytesIvWithInput:(NSString *)input
{
    NSData * data = [XBSHA bytesOfSHA256WithString:input];
    Byte b[12];
    Byte *byte = (Byte *)[data bytes];
    for (int i=0; i<12; i++) {
        b[i] = byte[i];
    }
    return [NSData dataWithBytes:b length:12];
}

// 生成随机的字符串
- (NSString *)genRandomLengthString
{
    int len = 10 + rand()%100;
    NSMutableString *mStr = [NSMutableString string];
    for(int i=0;i<len;i++) {
        [mStr appendFormat:@"%d",rand()];
    }
    return mStr;
}


#pragma mark - ===== 二维码相关操作 =====
// 生成二维码
- (UIImage *)generateCodeWithData:(NSData *)data withSize:(float)size
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复默认
    [filter setDefaults];
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    // 5. 将CIImage转换成UIImage，并放大显示
    //    return [UIImage imageWithCIImage:outputImage scale:1.0 orientation:UIImageOrientationUp];
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:size];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - 外设管理者相关的方法
/**
 *  CBPeripheralManager初始化后会触发的方法
 *   < 外设操作 ====  1  ===== >
 *  @param peripheral 外设管理者自己
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    // 蓝牙设备没有问题的话就开始操作
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        XBLog(@">>>>> 蓝牙设备打开成功");
        // 初始化要广播的信息
        [self addServicesToPeripheral];
    }
}

/**
 *  给外设添加服务信息
 */
- (void)addServicesToPeripheral
{
    
    // 设置特征  -可读，可写，可订阅
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:characteristicUUIDString] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    // 创建服务
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:serviceUUIDString] primary:YES];
    service.characteristics = @[characteristic];
    [self.serviceArray addObject:service] ;
    
    // 添加服务 添加服务进CBPeripheralManager时会触发的方法 - (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error  ---- 添加几次服务，就会触发几次
    // 这里添加了一个服务，所以触发一次
    [self.peripheralMgr addService:service];
}

/**
 *  添加服务进CBPeripheralManager时会触发的方法
 *  < 外设操作 ====  2  ===== >
 *
 *  @param peripheral 外设
 *  @param service    服务
 *  @param error      错误
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    // 广播内容
    if(self.isSecondBroadcast == NO) {
        randNumberString = [NSString stringWithFormat:@"%d",arc4random()];
        self.isSecondBroadcast = YES;
    }
    XBLog(@"randomnumebr****************** %@",randNumberString);
    
    NSDictionary *advertDict = @{  CBAdvertisementDataServiceUUIDsKey:[self.serviceArray valueForKeyPath:@"UUID"]
                                   ,CBAdvertisementDataLocalNameKey:randNumberString
                                   };
    
    // 发出广播,会触发peripheralManagerDidStartAdvertising:error:
    [peripheral startAdvertising:advertDict];
}

/**
 *  开始广播触发的代理
 *  < 外设操作 ====  3  ===== >
 *
 *  @param peripheral 外设管理者
 *  @param error      广播错误
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    XBLog(@">>>>>> 开始广播");
    if(error) {
        XBLog(@"广播出错，错误信息：%@",   error.localizedDescription);
    }
    
}

#pragma mark - 外设对中心请求作出的反应

/**
 *  外设收到读的请求,然后读特征的值赋值给request
 *         <外设收到中心   读   的请求 >
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    // 判断是否可读
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        request.value = data;
        XBLog(@"中心读外设备,UUID= %@", request.characteristic.UUID.UUIDString);
        // 对请求  成功  做出响应
        [self.peripheralMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else {
        [self.peripheralMgr respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
}

/**
 *  外设收到写的请求,然后读request的值,写给特征
 *         <外设收到中心   写   的请求 >
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    CBATTRequest *request = requests.firstObject;
    
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        NSData *data = request.value;
        // 此处赋值要转类型,否则报错
        CBMutableCharacteristic *mChar = (CBMutableCharacteristic *)request.characteristic;
        mChar.value = data;
        // 对请求成功做出响应
        [self readMessage:data fromCenter:[requests firstObject].central];
        
        [self.peripheralMgr respondToRequest:request withResult:CBATTErrorSuccess];
    }else {
        [self.peripheralMgr respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


/**
 *  中心订阅外设的某个特征
 *   <外设收到中心  订阅  的请求 >
 *
 *  @param peripheral     外设
 *  @param central        中心
 *  @param characteristic 订阅的字段
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    XBLog(@"%s, line = %d, 订阅了%@的数据", __FUNCTION__, __LINE__, characteristic.UUID);
    // 记录订阅的字段
    self.subscriptionChara= characteristic;
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    XBLog(@"%s, line = %d", __FUNCTION__, __LINE__);
}

/**
 *  外设发信息给中心（其实就是外设修改订阅的特征的值，然后自动通知中心读取）
 *
 *  @param message 数据
 *  @param centers 中心的数组
 */
- (void)sendMessage:(NSData *)message toCenters:(NSArray *)centers
{
    // 理论上要判断的，这里省了
    XBLog(@"---------外设更新是否成功：%d",[self.peripheralMgr updateValue:message forCharacteristic:(CBMutableCharacteristic *)_subscriptionChara onSubscribedCentrals:centers]);
    
    XBLog(@">>>>>>> 外设:  外设发 ----- ");
}

/**
 *  外设读取中心写的信息
 *
 *  @param message 中心写的信息
 *  @param center  中心
 */
-(void)readMessage:(NSData *)message fromCenter:(CBCentral *)center
{
    Frame *frame = [Frame parseFromData:message error:nil];
    XBLog(@">>>>>>>> 外设收到中心发来信息");
    XBLog(@"== %d,%@",frame.oneOfOneOfCase,message);
    
    if(frame.oneOfOneOfCase==2) {  // 外设收到中心发来的姓名信息，发送自己的姓名给中心
        // 创建外设模型数据
        XBDeviceModel *d = [[XBDeviceModel alloc] init];
        d.deviceNme = frame.identity.alias;
        d.device = center;
        d.dKind =  kDeviceKindCenter;
        // 添加
        if(![self isHaveDeviceNamed:d.deviceNme] && ![self.devicesModelArray containsObject:d] ) {
            [self.devicesModelArray addObject:d];
            XBLog(@"%@",self.devicesModelArray);
            [self.tableView reloadData];
            XBLog(@">>>>> 添加 reloadData");
        }
        
        // 立马发送姓名信息给外设
        XBLog(@"外设发送信息: 开始 ");
        // 身份信息
        Identity *identity = [Identity new];
        identity.uid = 0;
        identity.alias = self.userName;
        
        Frame *frame2 = [[Frame alloc] init];
        frame2.identity = identity;
        
        NSData *data = [frame2 data];
        [self sendMessage:data toCenters:self.centersArray];
        
        XBLog(@"外设发送信息: 结束 ");
        
        
    }else if(frame.oneOfOneOfCase==3) {
        static int count = 0;
        NSData *d = frame.dataTransfer.data_p;
        if([[XBDataConversionFactory getStringFromData:d] isEqualToString:@"xiangbin"]) {
            count = 0;
            // 判断信息
            [self readProtolMessage:self.mdata];
        }else {
            [self.mdata appendData:d];
            XBLog(@"&u& 外设--收到信息 i = %d,%@",count++,d);
        }
    }
    
}

#pragma mark - ========= B处理部分 ==========
// 收到信息的窗口显示扫描二维码界面
-(void)scanCodeInterface
{
    int w = self.view.frame.size.width;
    int h = 44;
    int x = 0;
    int y = self.view.frame.size.height - h;
    CGRect rect = CGRectMake(x, y, w, h);
    UIView *v = [[UIView alloc] initWithFrame:rect];
    v.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:v];
    
}

#pragma mark - ===== 代理<JBScanCodeDelegate> =====
- (void)showScanCodeView
{
    // 显示扫描的界面扫描
    [self scanCode];
    // 显示是否加入第三方的用户
    // 将扫描控件从窗口中移除
    [self.scanCodeView removeFromSuperview];
}

#pragma mark - ===== 代理 <JBAddThirdPartDelegate> =====
/**
 *  三方认证
 */
- (void)didAddThirdPart
{
    XBLog(@"三方认证");
    // 三方认证,这时候A,B已经确定下来了
    self.userKind = kUserKindB;
    // 先得到两把Key
    M2 *m = [M2 parseFromData:self.keysData error:nil];
    NSData *key1 = [[[m k] k1K2] first];
    NSData *key2 = [[[m k] k1K2] second];
    
    // 获取通过蓝牙传递的参数
    C3 *c3 = self.dataABC_m1;
    NSData *data_C_1_1 = c3.c1;
    NSData *data_C_1_2 = c3.c2;
    NSData *data_C_1_3 = c3.c3;
    Byte *byte_C_1_1 = (Byte *)[data_C_1_1 bytes];
    Byte *byte_C_1_3 = (Byte *)[data_C_1_3 bytes];
    NSUInteger len = [data_C_1_1 length] + [data_C_1_3 length];
    Byte *newC_1_2 = (Byte *)malloc(len);
    for(int i=0;i<[data_C_1_1 length];i++) {
        newC_1_2[i] = byte_C_1_1[i];
    }
    for(int i=0;i<[data_C_1_3 length];i++) {
        newC_1_2[i+[data_C_1_1 length]] = byte_C_1_3[i];
    }
    NSData *data_C_1_1_A = [NSData dataWithBytes:newC_1_2 length:len];
    NSData *d = [XBHMAC encryptionHMAC:data_C_1_1_A withKey:key2];
    // 1.用户B验证用户A是否合法
    if(![d isEqualToData:data_C_1_2]) {
        XBLog(@"NO");
        [SVProgressHUD showErrorWithStatus:@"用户A验证不通过"];
    }else {  // 用户A合法
        NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
        const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
        pbc_demo_pairing_init(pairing,ss);
        if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
        // 初始化
        element_init_G1(P, pairing);
        element_init_Zr(b, pairing);
        element_init_G1(Pb, pairing);
        
        element_from_hash(P, "a.properties", 12);
        element_printf("P = %B\n", P);
        element_random(b);
        element_mul_zn(Pb, P, b);
        
        // 2.解密C_1_1得到Pa
        element_init_G1(Pa, pairing);
        Byte *byte_vi = (Byte *)malloc(12); //加密使用的向量
        NSInteger len2 = [data_C_1_1 length] -12;
        Byte *byte_encryp_Pa = (Byte *)malloc(len2);
        for(int i=0;i<12;i++) {
            byte_vi[i] = byte_C_1_1[i];
        }
        for(int i=0;i<len2;i++) {
            byte_encryp_Pa[i] = byte_C_1_1[i+12];
        }
        NSData *data_vi = [NSData dataWithBytes:byte_vi length:12];
        NSData *data_encryp_Pa = [NSData dataWithBytes:byte_encryp_Pa length:len2];
        
        NSData *data_Pa = [XBGCM_AES decryptionDataFromData:data_encryp_Pa withKye:key1 andVi:data_vi];
        Byte *byte_Pa =(Byte *) [data_Pa bytes];
        // 从字节数组中恢复Pa
        element_from_bytes(Pa, byte_Pa);
        element_printf("解密：Pa =%B \n",Pa);
        
        // 生成K_b_1和K_b_2
        NSData *data_K_b_1 = [self generate32BytesKey];
        NSData *data_K_b_2 = [self generate32BytesKey];
        
        // 1.计算生成C_2_1
        // 将Pa和Pb转化成数组连接起来
        int len_Pb = element_length_in_bytes(Pb);
        unsigned char digest_Pb[len_Pb];
        element_to_bytes(digest_Pb, Pb);
        NSData *data_Pb = [NSData dataWithBytes:digest_Pb length:len_Pb];
        
        Pair *pair_Pa_Pb = [Pair new];
        pair_Pa_Pb.first = data_Pa;
        pair_Pa_Pb.second = data_Pb;
        
        NSData *data_Pa_Pb = [pair_Pa_Pb data];
        NSData *data_iv = [self generate12BytesIv];
        NSData *data_encryp_Pa_Pb = [XBGCM_AES encryptionData:data_Pa_Pb withKye:data_K_b_1 andVi:data_iv];
        // 连接vi和data
        NSInteger len_e_Pa_Pb = [data_encryp_Pa_Pb length];
        Byte* byte_encryp_Pa_Pb = (Byte *)[data_encryp_Pa_Pb bytes];
        Byte *byte_e_vi = (Byte *)[data_iv bytes];
        
        Byte *byte_C_2_1 = (Byte *)malloc(len_e_Pa_Pb + 12);
        for(int i=0;i<12;i++) {
            byte_C_2_1[i] = byte_e_vi[i];
        }
        for(int i=0;i<len_e_Pa_Pb;i++) {
            byte_C_2_1[i+12] = byte_encryp_Pa_Pb[i];
        }
        
        NSData *data_C_2_1 =[NSData dataWithBytes:byte_C_2_1 length:len_e_Pa_Pb + 12];
        
        // 2.计算生成C_2_2
        // 连接三个部分
        NSInteger len_C_2_1 = [data_C_2_1 length];
        
        NSData *data_A = data_C_1_3;
        NSInteger len_A = [data_A length];
        Byte* byte_A = (Byte *)[data_A bytes];
        
        NSData *data_B = [XBDataConversionFactory getDataFromString:self.userName];
        NSInteger len_B = [data_B length];
        Byte * byte_B = (Byte*)[data_B bytes];
        
        Byte *byte_C_2_2 = (Byte *)malloc(len_C_2_1 + len_A + len_B);
        for(int i=0;i<len_C_2_1;i++) {
            byte_C_2_2[i] = byte_C_2_1[i];
        }
        for(int i=0;i<len_A;i++) {
            byte_C_2_2[i +len_C_2_1] = byte_A[i];
        }
        for(int i=0;i<len_B;i++) {
            byte_C_2_2[i +len_C_2_1+len_A] = byte_B[i];
        }
        
        XBLog(@"测试信息B: A = %@",data_A);
        XBLog(@"测试信息B: B = %@",data_B);
        XBLog(@"测试信息B: data_C_2_1 = %@",data_C_2_1);
        
        NSData *data_C_2_2 = [XBHMAC encryptionHMAC:[NSData dataWithBytes:byte_C_2_2 length:len_C_2_1 + len_A + len_B] withKey:data_K_b_2];
        
        // 3.计算生成C_2_3
        Pair *pair_AB = [Pair new];
        pair_AB.first = data_A;
        pair_AB.second = data_B;
        // ====================== 发送
        C3P *b2c = [C3P new];
        b2c.c1 = data_C_2_1;
        b2c.c2 = data_C_2_2;
        b2c.c3 = pair_AB;
        
        M2 *m = [M2 new];
        m.m2P3 = b2c;
        NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(sendProtolMessage:) object:[m data]];
        [thread start];
        // ===================== 生成二维码
        Pair *pair_Key = [Pair new];
        pair_Key.first = data_K_b_1;
        pair_Key.second = data_K_b_2;
        
        K *k = [K new];
        k.k1K2 = pair_Key;
        
        M2 *mKey =[M2 new];
        mKey.k = k;
        NSData *data_pair = [mKey data];
        // 将pair转换成string
        NSString *str_pair = [XBDataConversionFactory getStringFromHexadecimalData:data_pair];
        XBLog(@"B->C:keyData: %@",data_pair);
        XBLog(@"B->C:keyString: %@",str_pair);
        
        // 设置生成的图片尺寸和位置
        float w = 200;
        float h = w;
        float x = (self.view.frame.size.width - w) * 0.5;
        float y = (self.view.frame.size.height - 20 - h)  * 0.5;
        
        //NSData *data = data_pair;
        UIImage *img = [self generateCodeWithData:[XBDataConversionFactory getDataFromString:str_pair] withSize:w];
        UIView *codeV = [[UIView alloc] initWithFrame:self.view.frame];
        codeV.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:codeV];
        
        
        CGRect rect = CGRectMake(x, y, w, h);
        UIImageView *imgV = [[UIImageView alloc] initWithFrame:rect];
        imgV.image = img;
        [codeV addSubview:imgV];
        // 设置相关变量
        self.isCodeWindowShow = true;
        self.codeView = codeV;
    }
}

/**
 *  两方认证
 */
- (void)didNotAddThirdPart
{
    XBLog(@"两方认证");
    // 两方认证,这时候A,B已经确定下来了
    self.userKind = kUserKindB;
    // 先得到两把Key
    M2 *m = [M2 parseFromData:self.keysData error:nil];
    NSData *key1 = [[[m k] k1K2] first];
    NSData *key2 = [[[m k] k1K2] second];
    
    // 获取通过蓝牙传递的参数
    C3 *c3 = self.dataABC_m1;
    NSData *data_C_1_1 = c3.c1;
    NSData *data_C_1_2 = c3.c2;
    NSData *data_C_1_3 = c3.c3;
    Byte *byte_C_1_1 = (Byte *)[data_C_1_1 bytes];
    Byte *byte_C_1_3 = (Byte *)[data_C_1_3 bytes];
    NSUInteger len = [data_C_1_1 length] + [data_C_1_3 length];
    Byte *newC_1_2 = (Byte *)malloc(len);
    for(int i=0;i<[data_C_1_1 length];i++) {
        newC_1_2[i] = byte_C_1_1[i];
    }
    for(int i=0;i<[data_C_1_3 length];i++) {
        newC_1_2[i+[data_C_1_1 length]] = byte_C_1_3[i];
    }
    NSData *data_C_1_1_A = [NSData dataWithBytes:newC_1_2 length:len];
    NSData *d = [XBHMAC encryptionHMAC:data_C_1_1_A withKey:key2];
    // 1.用户B验证用户A是否合法
    if(![d isEqualToData:data_C_1_2]) {
        XBLog(@"NO");
        [SVProgressHUD showErrorWithStatus:@"用户A验证不通过"];
    }else {  // 用户A合法
        NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
        const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
        pbc_demo_pairing_init(pairing,ss);
        if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
        // 初始化
        element_init_G1(P, pairing);
        element_init_Zr(b, pairing);
        element_init_G1(Pb, pairing);
        element_init_G1(Pa, pairing);
        
        element_from_hash(P, "a.properties", 12);
        element_printf("P = %B\n", P);
        element_random(b);
        element_mul_zn(Pb, P, b);
        
        // 2.解密C_1_1得到Pa
        //Byte *byte_C_1_1 = (Byte *)[data_C_1_1 bytes];
        Byte *byte_vi = (Byte *)malloc(12); //加密使用的向量
        NSInteger len2 = [data_C_1_1 length] -12;
        Byte *byte_encryp_Pa = (Byte *)malloc(len2);
        for(int i=0;i<12;i++) {
            byte_vi[i] = byte_C_1_1[i];
        }
        for(int i=0;i<len2;i++) {
            byte_encryp_Pa[i] = byte_C_1_1[i+12];
        }
        NSData *data_vi = [NSData dataWithBytes:byte_vi length:12];
        NSData *data_encryp_Pa = [NSData dataWithBytes:byte_encryp_Pa length:len2];
        
        NSData *data_Pa = [XBGCM_AES decryptionDataFromData:data_encryp_Pa withKye:key1 andVi:data_vi];
        Byte *byte_Pa =(Byte *) [data_Pa bytes];
        // 从字节数组中恢复Pa
        element_from_bytes(Pa, byte_Pa);
        element_printf("解密：Pa =%B \n",Pa);
        // 计算Pa*b
        element_mul_zn(Pa, Pa, b);
        //        element_printf("测试变量Pab = %B\n",Pa);
        // 将Pa转化为数组
        int len3 = element_length_in_bytes(Pa);
        unsigned char digest[len3];
        element_to_bytes(digest, Pa);
        NSData *data_Pab = [NSData dataWithBytes:digest length:len3];
        //        NSLog(@"测试变量：data_Pab =%@",data_Pab );
        // 3.计算H1(b*Pa)
        NSString *string_K_a_b = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_Pab]];
        // 长度不够，在一次hash
        string_K_a_b = [XBSHA encryptionSHA256WithString:string_K_a_b];
        //[HMAC encryptionHMAC:<#(NSData *)#> withKey:<#(NSData *)#>]
        // 4.计算C_2_1
        NSData *data_B = [XBDataConversionFactory getDataFromString:self.userName];
        Byte *byte_B =(Byte *) [data_B bytes];
        NSData *data_A = data_C_1_3;
        Byte *byte_A = (Byte*)[data_A bytes];
        // 连接A和B
        Byte *byte_A_B = (Byte *)malloc([data_A length] + [data_B length]);
        for(int i = 0;i<[data_A length];i++) {
            byte_A_B[i] = byte_A[i];
        }
        for(int i = 0;i<[data_B length];i++) {
            byte_A_B[i+[data_A length]] = byte_B[i];
        }
        NSData *data_A_B = [NSData dataWithBytes:byte_A_B length:[data_A length] + [data_B length]];
        NSData *data_C_2_1 = [XBHMAC encryptionHMAC:data_A_B withKey:[XBDataConversionFactory getDataFromString:string_K_a_b]];
        // 5.计算Pb
        int len4 = element_length_in_bytes(Pb);
        unsigned char digest2[len4];
        element_to_bytes(digest2, Pb);
        NSData *data_Pb = [NSData dataWithBytes:digest2 length:len4];
        NSData *data_C_2_2 = data_Pb;
        // 6.计算B
        NSData *data_C_2_3 = data_B;
        
        // ========================== 传输的数据 ====================
        // 创建信息部分
        C3 *b2a = [C3 new];
        b2a.c1 = data_C_2_1;
        b2a.c2 = data_C_2_2;
        b2a.c3 = data_C_2_3;
        // 创建外包装
        M2 *m = [M2 new];
        m.m2P2 = b2a;
        // ============================= 发送
        NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(sendProtolMessage:) object:[m data]];
        [thread start];
        
        // 7.计算K
        NSString *K = [XBSHA encryptionSHA384WithString:[XBDataConversionFactory getStringFromHexadecimalData:data_Pab]];
        XBLog(@"K = %@",K);
        // 移除添加第三个控件的窗口
        if(self.isThirdPartWindowShow) [self.thirdPartView removeFromSuperview];
        
        // 聊天开始
        [self chatRoomWithSessionKey:K];
//        [SVProgressHUD showWithStatus:K];
    }
    
}

// 协议部分的信息读取
- (void)readProtolMessage:(NSData *)msgData
{
    XBLog(@"========= end ========");
    
    M2 *m = [M2 parseFromData:msgData error:nil];
    int msgNum = m.oneOfOneOfCase;
    switch (msgNum) {
        case 1: // 读取到的是第一条发送的信息
        {
            // 保存第一条信息
            self.dataABC_m1 = m.m1;
            JBScanCode *scanCodeView = [JBScanCode scanCode];
            scanCodeView.delegate = self;
            // scanCodeView显示的位置
            int x = 0;
            int w = self.view.frame.size.width;
            int h = SCANVIEWH;
            int y = self.view.frame.size.height - h;
            scanCodeView.frame = CGRectMake(x, y, w, h);
            scanCodeView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:scanCodeView];
            self.isScanCodeWindowShow = true;
            self.scanCodeView = scanCodeView;
            break;
        }
        case 2:
        {
            if(self.userKind != kUserKindA) break; // 第三台手机不干活
            
            // 保存第二条信息
            self.dataAB_m2 = m.m2P2;
            // 移除二维码界面
            if(self.isCodeWindowShow) [self.codeView removeFromSuperview];
            
            // 得到发送过来的值
            C3 *c3 = self.dataAB_m2;
            NSData *data_C_2_1 = c3.c1;
            NSData *data_C_2_2 = c3.c2;
            NSData *data_C_2_3 = c3.c3;
            Byte *byte_Pb = (Byte *)[data_C_2_2 bytes];
            element_init_G1(Pb, pairing);
            element_from_bytes(Pb, byte_Pb);
            // 计算Pba
            element_mul_zn(Pb, Pb, a);
            int len1 = element_length_in_bytes(Pb);
            unsigned char digest[len1];
            element_to_bytes(digest, Pb);
            NSData *data_Pba = [NSData dataWithBytes:digest length:len1];
            
            // 1.验证用户B是否合法
            NSString *string_K_a_b = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_Pba]];
            string_K_a_b = [XBSHA encryptionSHA256WithString:string_K_a_b];
            
            // 连接A和B
            NSData *data_A = [XBDataConversionFactory getDataFromString:self.userName];
            Byte *byte_A =(Byte *) [data_A bytes];
            NSData *data_B = data_C_2_3;
            Byte *byte_B = (Byte*)[data_B bytes];
            // 连接A和B
            Byte *byte_A_B = (Byte *)malloc([data_A length] + [data_B length]);
            for(int i = 0;i<[data_A length];i++) {
                byte_A_B[i] = byte_A[i];
            }
            for(int i = 0;i<[data_B length];i++) {
                byte_A_B[i+[data_A length]] = byte_B[i];
            }
            NSData *data_A_B = [NSData dataWithBytes:byte_A_B length:[data_A length] + [data_B length]];
            
            NSData *data_newC_2_1= [XBHMAC encryptionHMAC:data_A_B withKey:[XBDataConversionFactory getDataFromString:string_K_a_b]];
            if(![data_newC_2_1 isEqualToData:data_C_2_1]) {
                XBLog(@"用户B身份信息有误");
            }else {
                NSString * K = [XBSHA encryptionSHA384WithString:[XBDataConversionFactory getStringFromHexadecimalData:data_Pba]];
                XBLog(@"K = %@",K);
                
                // 聊天开始
                [self chatRoomWithSessionKey:K];
//                [SVProgressHUD showWithStatus:K];
            }
            break;
        }
            
        case 3:
        {
            if(self.userKind == kUserKindA || self.userKind==kUserKindB) break; // 第一二台手机不干活
            self.isThirdPartWantsToJoin = true;
            // 保存第一条信息
            self.dataABC_m2 = m.m2P3;
            if(self.isCodeWindowShow) break;
            
            JBScanCode *scanCodeView = [JBScanCode scanCode];
            scanCodeView.delegate = self;
            // scanCodeView显示的位置
            int x = 0;
            int w = self.view.frame.size.width;
            int h = SCANVIEWH;
            int y = self.view.frame.size.height - h;
            scanCodeView.frame = CGRectMake(x, y, w, h);
            scanCodeView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:scanCodeView];
            self.isScanCodeWindowShow = true;
            self.scanCodeView = scanCodeView;
            
            break;
        }
            
        case 4:  // 是C发给A的
        {
            if(self.userKind != kUserKindA) break;  // 如果自己不是A那么不处理
            // 先保存一下子
            self.dataABC_m3 = m.m3P3;
            // 拿出每一个
            NSData *data_C_3_1 = self.dataABC_m3.c1;
            NSData *data_C_3_2 = self.dataABC_m3.c2;
            NSData *data_C_3_3 = self.dataABC_m3.c3;
            Pair *pairBC = self.dataABC_m3.c4;
            
            // 拿出Pc，Pb
            element_init_G1(Pb, pairing);
            element_init_G1(Pc, pairing);
            // 从字节数组中恢复Pb
            Byte *byte_Pb =(Byte *) [data_C_3_3 bytes];
            element_from_bytes(Pb, byte_Pb);
            // 从字节数组中恢复Pc
            Byte *byte_Pc =(Byte *) [data_C_3_2 bytes];
            element_from_bytes(Pc, byte_Pc);
            
            // 计算a*C3,2
            element_t tt;
            element_init_G1(tt, pairing);
            element_mul_zn(tt, Pc, a);
            NSInteger len_tt = element_length_in_bytes(tt);
            unsigned char digest[len_tt];
            element_to_bytes(digest, tt);
            NSData *data_tt = [NSData dataWithBytes:digest length:len_tt];
            NSString* string_K_a_c = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_tt]];
            string_K_a_c = [XBSHA encryptionSHA256WithString:string_K_a_c];
            
            // 1.验证是否合法
            // 连接ABC和C3,3
            NSData *data_A = [XBDataConversionFactory getDataFromString:self.userName];
            Byte *byte_A = (Byte *)[data_A bytes];
            
            NSData *data_B = pairBC.first;
            Byte *byte_B =(Byte *)[data_B bytes];
            
            NSData *data_C = pairBC.second;
            Byte *byte_C = (Byte*)[data_C bytes];
            
            Byte *byte_ABCPb = (Byte*)malloc([data_A length] + [data_B length] + [data_C length] + [data_C_3_3 length]);
            for(int i=0;i<[data_A length];i++) {
                byte_ABCPb[i] = byte_A[i];
            }
            for(int i=0;i<[data_B length];i++) {
                byte_ABCPb[i + [data_A length]] = byte_B[i];
            }
            for(int i=0;i<[data_C length];i++) {
                byte_ABCPb[i + [data_A length] + [data_B length]] = byte_C[i];
            }
            for(int i=0;i<[data_C_3_3 length];i++) {
                byte_ABCPb[i +[data_A length] +[data_B length] +[data_C length]] = byte_Pb[i];
            }
            NSData *data_ABCPb = [NSData dataWithBytes:byte_ABCPb length:[data_A length] + [data_B length] + [data_C length] + [data_C_3_3 length]];
            NSData *dataNew_C_3_1 = [XBHMAC encryptionHMAC:data_ABCPb withKey:[XBDataConversionFactory getDataFromString:string_K_a_c]];
            if(![dataNew_C_3_1 isEqualToData:data_C_3_1]) {  // 验证不通过
                [SVProgressHUD showErrorWithStatus:@"A部分：身份信息错误"];
            }else {  // 验证通过
                element_init_GT(out1, pairing);
                element_pairing(out1, Pc, Pb);
                element_pow_zn(out1, out1, a);
                // 转换为nsdata
                int len_out1 = element_length_in_bytes(out1);
                unsigned char digest_out1[len_out1];
                element_to_bytes(digest_out1, out1);
                NSData *data_out1 = [NSData dataWithBytes:digest_out1 length:len_out1];
                
                NSString *K = [XBSHA encryptionSHA256WithString:[XBDataConversionFactory getStringFromHexadecimalData:data_out1]];
                XBLog(@"A:  K = %@",K);
//                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"A: K = %@",K]];
                if(self.isCodeWindowShow) [self.codeView removeFromSuperview];
                [self chatRoomWithSessionKey:K];
            }
            
            break;
        }
            
        case 5: // C发送个B的
        {
            if(self.userKind != kUserKindB) break;  // 如果自己不是A那么不处理
            self.dataABC_m4 = m.m4P3;
            NSData *data_C_4_1 = self.dataABC_m4.c1;
            NSData *data_C_4_2 = self.dataABC_m4.c2;
            Pair *pairAC = self.dataABC_m4.c3;
            
            element_init_G1(Pc, pairing);
            Byte *byte_Pc =(Byte *) [data_C_4_2 bytes];
            element_from_bytes(Pc, byte_Pc);
            // 计算K_b_c
            element_t tt;
            element_init_G1(tt, pairing);
            element_mul_zn(tt, Pc, b);
            NSInteger len_tt = element_length_in_bytes(tt);
            unsigned char digest[len_tt];
            element_to_bytes(digest, tt);
            NSData *data_tt = [NSData dataWithBytes:digest length:len_tt];
            NSString* string_K_b_c = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_tt]];
            string_K_b_c = [XBSHA encryptionSHA256WithString:string_K_b_c];
            // 验证是否合法
            // 连接ABC
            NSData *data_A = pairAC.first;
            NSData *data_C = pairAC.second;
            NSData *data_B = [XBDataConversionFactory getDataFromString:self.userName];
            Byte *byte_A = (Byte *)[data_A bytes];
            Byte *byte_B =(Byte *)[data_B bytes];
            Byte *byte_C = (Byte*)[data_C bytes];
            // 连接
            Byte *byte_ABC = (Byte*)malloc([data_A length] + [data_B length] + [data_C length]);
            for(int i=0;i<[data_A length];i++) {
                byte_ABC[i] = byte_A[i];
            }
            for(int i=0;i<[data_B length];i++) {
                byte_ABC[i + [data_A length]] = byte_B[i];
            }
            for(int i=0;i<[data_C length];i++) {
                byte_ABC[i + [data_A length] + [data_B length]] = byte_C[i];
            }
            NSData *data_ABC = [NSData dataWithBytes:byte_ABC length:[data_A length] + [data_B length] + [data_C length]];
            NSData *dataNew_C_4_1 = [XBHMAC encryptionHMAC:data_ABC withKey:[XBDataConversionFactory getDataFromString:string_K_b_c]];
            if(![dataNew_C_4_1 isEqualToData:data_C_4_1]){  // 验证不通过
                [SVProgressHUD showErrorWithStatus:@"B部分：身份信息错误"];
            }else {  // 验证通过
                element_init_GT(out2, pairing);
                element_pairing(out2, Pa, Pc);
                element_pow_zn(out2, out2, b);
                // 转换为nsdata
                int len_out2 = element_length_in_bytes(out2);
                unsigned char digest_out2[len_out2];
                element_to_bytes(digest_out2, out2);
                NSData *data_out2 = [NSData dataWithBytes:digest_out2 length:len_out2];
                
                NSString *K = [XBSHA encryptionSHA256WithString:[XBDataConversionFactory getStringFromHexadecimalData:data_out2]];
                XBLog(@"B:  K = %@",K);
//                [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"B:K = %@",K]];
                if(self.isCodeWindowShow) [self.codeView removeFromSuperview];
                if(self.isThirdPartWindowShow) [self.thirdPartView removeFromSuperview];
                [self chatRoomWithSessionKey:K];
            }
            break;
        }
        case 6: //相互发的消息，不是协议之内的
        {
            // 0.解密数据所需的密钥和向量
            NSData *key = [XBSHA bytesOfSHA256WithString:self.sessionKey];
            NSData *iv = [self generate12BytesIvWithInput:self.sessionKey];
            
            // 1.拿到数据
            Pair *pairContents = m.k.k1K2;
            
            // 2.解密姓名和内容
            NSData *name_data = [XBGCM_AES decryptionDataFromData:pairContents.first withKye:key andVi:iv];
            NSData *message_data = [XBGCM_AES decryptionDataFromData:pairContents.second withKye:key andVi:iv];
            
            // 3.传递给聊天界面显示
            [self.chatRoomVC receiveMessage:[XBDataConversionFactory getStringFromData:message_data] fromUser:[XBDataConversionFactory getStringFromData:name_data]];
        }
        default:
            break;
    }
    // 显示扫描界面
    // [self scanCode];
    
    // 清空mdata
    [self.mdata resetBytesInRange:NSMakeRange(0, self.mdata.length)];
    [self.mdata setLength:0];
    
}

- (void)scanCode
{
    // 1.创建捕捉会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.session = session;
    
    // 2.添加输入设备(数据从摄像头输入)
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [session addInput:input];
    
    // 3.添加输出数据(示例对象-->类对象-->元类对象-->根元类对象)
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:output];
    
    // 3.1.设置输出元数据的类型(类型是二维码数据)
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // 4.添加扫描图层
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.frame = self.view.bounds;
    [self.view.layer addSublayer:layer];
    self.layer = layer;
    
    // 5.开始扫描
    [session startRunning];
}

// 当扫描到数据时就会执行该方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *object = [metadataObjects lastObject];
        XBLog(@"hex_string:%@", object.stringValue);
        self.keysData = [XBDataConversionFactory getHexadecimalDataFromString:object.stringValue];
        XBLog(@"data:%@",[XBDataConversionFactory getHexadecimalDataFromString:object.stringValue]);
        XBLog(@">>>>>>>>>扫描扫描");
        
        // 停止扫描
        [self.session stopRunning];
        
        // 将预览图层移除
        [self.layer removeFromSuperlayer];
        
        if(self.isThirdPartWantsToJoin) {
            // 第三个人干的活
            [self thirdPartOperation];
        }else {
            // 添加询问是否加入第三方的窗口
            [self isAddThirdPart];
        }
        
        
    } else {
        XBLog(@"没有扫描到数据");
    }
}

#pragma mark - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-(void)thirdPartOperation
{
    // 自己是第三个人
    self.userKind = kUserKindC;
    
    // 先得到两把Key
    M2 *m = [M2 parseFromData:self.keysData error:nil];
    NSData *key1 = [[[m k] k1K2] first];
    NSData *key2 = [[[m k] k1K2] second];
    
    C3P *b2c =self.dataABC_m2;
    NSData *data_C_2_1 = b2c.c1;
    NSData *data_C_2_2 = b2c.c2;
    Pair *pairAB = b2c.c3;
    
    // 1.验证B是否合法
    NSData *data_A = pairAB.first;
    NSData *data_B = pairAB.second;
    NSInteger len_C_2_1 = [data_C_2_1 length];
    Byte* byte_C_2_1 = (Byte*)[data_C_2_1 bytes];
    
    NSInteger len_A = [data_A length];
    Byte* byte_A = (Byte *)[data_A bytes];
    
    NSInteger len_B = [data_B length];
    Byte * byte_B = (Byte*)[data_B bytes];
    
    Byte *byte_C_2_2 = (Byte *)malloc(len_C_2_1 + len_A + len_B);
    for(int i=0;i<len_C_2_1;i++) {
        byte_C_2_2[i] = byte_C_2_1[i];
    }
    for(int i=0;i<len_A;i++) {
        byte_C_2_2[i +len_C_2_1] = byte_A[i];
    }
    for(int i=0;i<len_B;i++) {
        byte_C_2_2[i +len_C_2_1+len_A] = byte_B[i];
    }
    
    NSData *dataNew_C_2_2 = [XBHMAC encryptionHMAC:[NSData dataWithBytes:byte_C_2_2 length:len_C_2_1 + len_A + len_B] withKey:key2];
    
    XBLog(@"测试信息C: A = %@",data_A);
    XBLog(@"测试信息C: B = %@",data_B);
    XBLog(@"测试信息C: data_C_2_1 = %@",data_C_2_1);
    
    if(![dataNew_C_2_2 isEqualToData:data_C_2_2]) {  // 不合法
        [SVProgressHUD showErrorWithStatus:@"C认证部分：身份信息不正确"];
    }else {  // 身份正确
//        [SVProgressHUD showWithStatus:@"C认证部分：身份信息正确"]; // 要注释的
        // 1.解密C_2_1
        Byte *bytesArr = (Byte *)[data_C_2_1 bytes];
        Byte *byte_d_iv = (Byte *)malloc(12);
        NSInteger len_d_C_2_1 = [data_C_2_1 length] -12;
        Byte *byte_d_C_2_1 = (Byte *)malloc(len_d_C_2_1);
        for(int i=0;i<12;i++) {
            byte_d_iv[i] = bytesArr[i];
        }
        for(int i=0;i<len_d_C_2_1;i++) {
            byte_d_C_2_1[i] = bytesArr[i+12];
        }
        // 解密
        NSData *data_d_iv = [NSData dataWithBytes:byte_d_iv length:12];
        
        NSData *data_Pair_Pa_Pb = [XBGCM_AES decryptionDataFromData:[NSData dataWithBytes:byte_d_C_2_1 length:len_d_C_2_1] withKye:key1 andVi:data_d_iv];
        Pair *pair_pa_pb = [Pair parseFromData:data_Pair_Pa_Pb error:nil];
        NSData *data_pa = pair_pa_pb.first;
        NSData *data_pb = pair_pa_pb.second;
        
        // 初始化双线性映射相关的参数
        NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
        const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
        
        pbc_demo_pairing_init(pairing,ss);
        if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
        element_init_G1(P, pairing);
        element_init_Zr(c, pairing);
        element_init_G1(Pc, pairing);
        element_t Pa_t; // 这个是真实的Pa
        element_init_G1(Pa_t, pairing);
        element_init_G1(Pa, pairing);
        element_t Pb_t; // 这个是真实的Pb
        element_init_G1(Pb_t, pairing);
        element_init_G1(Pb, pairing);
        // 计算Pc
        element_from_hash(P, "a.properties", 12);
        element_printf("P = %B\n", P);
        element_random(c);
        element_mul_zn(Pc, P, c);
        // 恢复pa,pb
        Byte *byte_pa =(Byte *) [data_pa bytes];
        element_from_bytes(Pa, byte_pa);
        element_from_bytes(Pa_t, byte_pa);
        Byte* byte_pb = (Byte*)[data_pb bytes];
        element_from_bytes(Pb, byte_pb);
        element_from_bytes(Pb_t, byte_pb);
        
        //计算c*pa
        element_mul_zn(Pa, Pa, c);
        // 计算c*pb
        element_mul_zn(Pb, Pb, c);
        // 计算K_a_c
        int len3 = element_length_in_bytes(Pa);
        unsigned char digest[len3];
        element_to_bytes(digest, Pa);
        NSData *data_Pac = [NSData dataWithBytes:digest length:len3];
        NSString* string_K_a_c = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_Pac]];
        string_K_a_c = [XBSHA encryptionSHA256WithString:string_K_a_c];
        // 计算K_a_b
        int len4 = element_length_in_bytes(Pb);
        unsigned char digest2[len4];
        element_to_bytes(digest2, Pb);
        NSData *data_Pbc = [NSData dataWithBytes:digest2 length:len4];
        NSString* string_K_b_c = [XBSHA encryptionSHA224WithString:[XBDataConversionFactory getStringFromData:data_Pbc]];
        string_K_b_c = [XBSHA encryptionSHA256WithString:string_K_b_c];
        // ===================== 计算传输给B的信息 ======================
        // 1.计算C_4_1
        // 连接ABC
        NSData *data_C = [XBDataConversionFactory getDataFromString:self.userName];
        NSInteger len_C = [data_C length];
        Byte* byte_C = (Byte*)[data_C bytes];
        Byte *byte_ABC = (Byte*)malloc(len_A+len_B+len_C);
        for(int i=0;i<len_A;i++) {
            byte_ABC[i] = byte_A[i];
        }
        for(int i=0;i<len_B;i++) {
            byte_ABC[i+len_A] = byte_B[i];
        }
        for(int i=0;i<len_C;i++) {
            byte_ABC[i+len_A+len_B] = byte_C[i];
        }
        NSData *data_ABC = [NSData dataWithBytes:byte_ABC length:len_A+len_B+len_C];
        NSData* data_C_4_1= [XBHMAC encryptionHMAC:data_ABC withKey:[XBDataConversionFactory getDataFromString:string_K_b_c]];
        
        // 2.计算C_4_2
        int len5 = element_length_in_bytes(Pc);
        unsigned char digest3[len5];
        element_to_bytes(digest3, Pc);
        NSData *data_Pc = [NSData dataWithBytes:digest3 length:len5];
        NSData *data_C_4_2 = data_Pc;
        
        // 计算pairAc
        Pair *pairAC = [Pair new];
        pairAC.first = data_A;
        pairAC.second = data_C;
        // ========================= 发送信息给B
        C3P *c2b = [C3P new];
        c2b.c1 = data_C_4_1;
        c2b.c2 = data_C_4_2;
        c2b.c3 = pairAC;
        
        M2 *m = [M2 new];
        m.m4P3 = c2b;
        dispatch_queue_t  queue= dispatch_queue_create("com.xiangbin.lanya.queue4", NULL);
        dispatch_async(queue, ^{
            [self sendProtolMessage:[m data]];
        });
        
        // =========================== 计算传输给A的信息 =======================
        int len6 = element_length_in_bytes(Pb_t);
        unsigned char digest4[len6];
        element_to_bytes(digest4, Pb_t);
        NSData *data_Pb_t = [NSData dataWithBytes:digest4 length:len6];
        
        //1.计算C_3_1
        // 连接ABC和Pb_t
        Byte *byte_Pb_t = (Byte*)[data_Pb_t bytes];
        NSInteger len_Pb_t = [data_Pb_t length];
        Byte *byte_ABCPb = (Byte *)malloc(len_Pb_t + [data_ABC length]);
        
        for(int i=0;i<[data_ABC length];i++) {
            byte_ABCPb[i] = byte_ABC[i];
        }
        for(int i=0;i<len_Pb_t;i++) {
            byte_ABCPb[i+[data_ABC length]] = byte_Pb_t[i];
        }
        NSData *data_ABCPb = [NSData dataWithBytes:byte_ABCPb length:len_Pb_t + [data_ABC length]];
        NSData *data_C_3_1 = [XBHMAC encryptionHMAC:data_ABCPb withKey:[XBDataConversionFactory getDataFromString:string_K_a_c]];
        // 2.计算c_3_2
        NSData *data_C_3_2 = data_Pc;
        // 3.计算c_3_3
        NSData *data_C_3_3 = data_Pb_t;
        // 4.计算C_3_4
        Pair *pairBC = [Pair new];
        pairBC.first = data_B;
        pairBC.second = data_C;
        
        // ========================= 发送信息给A
        XBLog(@"发给A==========================");
        
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        C4P *c2a = [C4P new];
        c2a.c1 = data_C_3_1;
        c2a.c2 = data_C_3_2;
        c2a.c3 = data_C_3_3;
        c2a.c4 = pairBC;
        
        
        M2 *m2 = [M2 new];
        m2.m3P3 = c2a;
        //            NSThread *thread2=[[NSThread alloc]initWithTarget:self selector:@selector(sendProtolMessage:) object:[m2 data]];
        //            [thread2 start];
        //        });
        dispatch_async(queue, ^{
            [self sendProtolMessage:[m2 data]];
        });
        
        XBLog(@"发给A==========================");
        element_init_GT(out3, pairing);
        element_pairing(out3, Pa_t, Pb_t);
        element_pow_zn(out3, out3, c);
        // 转换为nsdata
        int len_out3 = element_length_in_bytes(out3);
        unsigned char digest_out3[len_out3];
        element_to_bytes(digest_out3, out3);
        NSData *data_out3 = [NSData dataWithBytes:digest_out3 length:len_out3];
        
        NSString *K = [XBSHA encryptionSHA256WithString:[XBDataConversionFactory getStringFromHexadecimalData:data_out3]];
        XBLog(@"C:  K = %@",K);
//        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"C:  K = %@",K]];
        if(self.isThirdPartWindowShow) [self.thirdPartView removeFromSuperview];
        if(self.isScanCodeWindowShow) [self.scanCodeView removeFromSuperview];
        [self chatRoomWithSessionKey:K];
        
        
    }
}

- (void)isAddThirdPart
{
    // 添加询问是否加入第三方的窗口
    JBAddThirdPart *thirdPartView = [JBAddThirdPart addThirdPart];
    thirdPartView.delegate = self;
    int w = self.view.frame.size.width;
    int h = SCANVIEWH;
    int x = 0;
    int y = self.view.frame.size.height - h;
    
    thirdPartView.frame = CGRectMake(x, y, w, h);
    thirdPartView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:thirdPartView];
    
    self.isThirdPartWindowShow = true;
    self.thirdPartView = thirdPartView;
}


#pragma mark - 中心管理者相关的方法

/**
 *  中心管理者状态改变, 在初始化CBCentralManager的时候会打开设备，只有当设备正确打开后才能使用
 *      < 中心操作 *******  1  ******* >
 *
 *  @param central <#central description#>
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            XBLog(@">>>>> 蓝牙开启成功");
            // 开始扫描周围的外设
            [self.centerMgr scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:serviceUUIDString]] options:nil];
            break;
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateUnauthorized:
        case CBCentralManagerStatePoweredOff:
            XBLog(@">>>>> 蓝牙打开出问题");
            break;
    }
    
}

/**
 *  扫描到设备会进入此方法
 *   < 中心操作 *******  2  ******* >
 *
 *  @param central           中心
 *  @param peripheral        外设
 *  @param advertisementData 广播的数据
 *  @param RSSI              信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    XBLog(@"搜索到了设备:%@",peripheral.name);
    XBLog(@"advertisementData = %@",advertisementData);
    NSArray * allKeysArray =  [advertisementData allKeys];
    
    if([allKeysArray containsObject:@"kCBAdvDataServiceData"]) {   // 安卓设备
        // 获取内容 <47a64523>
        NSDictionary *dd = advertisementData[@"kCBAdvDataServiceData"];
        NSArray *keys = [advertisementData[@"kCBAdvDataServiceData"] allKeys];
        Byte *bytes = (Byte *)[dd[[keys firstObject]]  bytes] ;
        int otherNumber = CFSwapInt32BigToHost(*(int *)bytes);
        XBLog(@"kCBAdvDataServiceData==========%d",otherNumber);
        [self peripheral:peripheral compareWithOtherNumber:otherNumber];
    } else {  // iOS设备发来的信息
        
        // iOS广播包的时候，会发送两次，第一次没有用
        if([self.otherArray containsObject:peripheral.identifier.UUIDString]) {
            int otherNumber = [advertisementData[@"kCBAdvDataLocalName"] intValue];
            XBLog(@"kCBAdvDataLocalName==========%d",otherNumber);
            [self peripheral:peripheral compareWithOtherNumber:otherNumber];
        }else {
            [self.otherArray addObject:peripheral.identifier.UUIDString];
        }
        
    }
    
}

/**
 *  根据传入的值判断谁是中心，谁是外设
 *
 *  @param peripheral  待判断的设备
 *  @param otherNumber 该设备所携带的随机值
 */
- (void)peripheral:(CBPeripheral *)peripheral compareWithOtherNumber:(int)otherNumber
{
    // 如果设备连接过了，那么会存储对应设备的随机值
    // 那么就不需要再次连接了
    if([self.numsArray containsObject:[NSNumber numberWithInteger:otherNumber]]) return;
    // 存储设备对应的随机值
    [self.numsArray addObject:[NSNumber numberWithInteger:otherNumber]];
    static int num = 0;
    num++;
    XBLog(@"== @u@ static num:%d",num);
    XBLog(@"== %@",peripheral);
    // 谁大谁是外设,谁小谁是中心
    if(otherNumber >[randNumberString intValue]) {  // 自己是中心
        // 添加外设
        if(![self.peripheralArray containsObject:peripheral]) [self.peripheralArray addObject:peripheral];
        // 自己发起连接
        [self.centerMgr connectPeripheral:peripheral options:nil];
        
    }else { // 自己是外设
        if(![self.centersArray containsObject:peripheral]) [self.centersArray addObject:peripheral];
        
    }
    
}


/**
 *  外设连接成功
 *   < 中心操作 *******  3  ******* >
 *
 *  @param central    中心
 *  @param peripheral 外设
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    XBLog(@">>>>> 连接到名称为（%@）的设备-成功",peripheral.name);
    
    // 设置外设的代理为自己
    peripheral.delegate = self;
    // 扫描外设Services
    // 成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];
    
}

/**
 *  扫描外设的服务
 *  < 中心操作 *******  4  ******* >
 *
 *  @param peripheral <#peripheral description#>
 *  @param error      <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        XBLog(@">>>>> Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        XBLog(@"service.UUID = %@", service.UUID);
        //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}


/**
 *  发现外设service的特征
 *  < 中心操作 ******* 5  ******* >
 *
 *  @param peripheral <#peripheral description#>
 *  @param service    <#service description#>
 *  @param error      <#error description#>
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        XBLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        XBLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
        
        if([characteristic.UUID.UUIDString isEqualToString:characteristicUUIDString]) {
            // 写的字段
            //            self.chaXie = characteristic;
            XBCharaModel *wChara = [[XBCharaModel alloc] init];
            wChara.identity = peripheral.identifier.UUIDString;
            wChara.chara =characteristic;
            [self.writeCharas addObject:wChara];
            
            // 订阅
            // 设置通知, 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            // 立马发送姓名信息给外设
            // 只会发送一次，这个方法只会进来一次
            XBLog(@"中心发送名字信息: 开始 ");
            
            // 身份信息
            Identity *identity = [Identity new];
            identity.uid = 0;
            identity.alias = self.userName;
            
            Frame *frame = [[Frame alloc] init];
            frame.identity = identity;
            
            NSData *data = [frame data];
            [self sendMessage:data toPeripheral:peripheral];
            
            XBLog(@"中心发送名字信息: 结束 ");
            
        }
        
    } // end of for
    
}

// 获取characteristic的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if(error) {
        XBLog(@">>>>> didUpdateValueForCharacteristic is error with :%@",error.localizedDescription);
        return;
    }
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    
    if(characteristic.properties & CBCharacteristicPropertyRead) {
        //         NSLog(@"哈哈 --- characteristic.UUID:%@  value:%@", characteristic.UUID, characteristic.value);
        [self readMessage:characteristic.value fromPeripheral:peripheral forCharacteristic:characteristic];
    }
    
}

/**
 *  中心读取外设的信心
 *
 *  @param message    信息
 *  @param peripheral  外设
 */
- (void)readMessage:(NSData*)message fromPeripheral:(CBPeripheral*)peripheral forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    Frame *frame = [Frame parseFromData:message error:nil];
    XBLog(@">>>>>>>> 中心收到外设发来信息");
    XBLog(@"== %d,%@",frame.oneOfOneOfCase,message);
    
    if(frame.oneOfOneOfCase==2) {  // 中心收到外设发送的姓名信息
        // 创建外设模型数据
        XBDeviceModel *d = [[XBDeviceModel alloc] init];
        d.deviceNme = frame.identity.alias;
        d.device = peripheral;
        d.dKind =  kDeviceKindPeripheral;
        
        // 添加
        if(![self isHaveDeviceNamed:d.deviceNme] && ![self.devicesModelArray containsObject:d] ) {
            
            [self.devicesModelArray addObject:d];
            XBLog(@"%@",self.devicesModelArray);
            [self.tableView reloadData];
            XBLog(@">>>>> 添加 reloadData");
        }
        //        else{
        //            [self.centerMgr cancelPeripheralConnection:peripheral];
        //        }
        
        // end of 添加
        
        
    }// end of frame.oneOfOneOfCase==2
    else  if(frame.oneOfOneOfCase==3) {
        static int count = 0;
        NSData *d = frame.dataTransfer.data_p;
        if([[XBDataConversionFactory getStringFromData:d] isEqualToString:@"xiangbin"]) {
            count = 0;
            // 判断信息
            [self readProtolMessage:self.mdata];
        }else {
            [self.mdata appendData:d];
            XBLog(@"&u& 中心--收到信息 i = %d,%@",count++,d);
        }
        
    }
}

// 判断设备列表中是否含有指定名字的设备
-(BOOL)isHaveDeviceNamed:(NSString *)name
{
    for (XBDeviceModel *d in self.devicesModelArray) {
        if([d.deviceNme isEqualToString:name]) return YES;
    }
    return NO;
}

// 从设备列表中删除指定名字的设备
-(void)removeDeviceFromTableWithName:(NSString *)name
{
    XBDeviceModel *needed = nil;
    for (XBDeviceModel *d in self.devicesModelArray) {
        if([d.deviceNme isEqualToString:name]) { needed = d; break;}
    }
    XBLog(@"============= *********************** =============== ************");
    [self.devicesModelArray removeObject:needed];
    //    if([self.peripheralArray containsObject:needed.device]) [self centralManager:self.centerMgr didDisconnectPeripheral:(CBPeripheral *)needed.device error:nil];
}

//- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error

/**
 *  中心给外设发送信息
 *
 *  @param message    信息
 *  @param peripheral  外设
 */
- (void)sendMessage:(NSData *)message toPeripheral:(CBPeripheral *)peripheral
{
    // 遍历数组，寻找对应设备的写特征值
    CBCharacteristic *characteristic = nil;
    for (XBCharaModel *item in self.writeCharas) {
        if([item.identity isEqualToString:peripheral.identifier.UUIDString]) {
            characteristic = (CBCharacteristic *)item.chara;
        }
    }
    // 获取写的特征
    //    CBCharacteristic *characteristic = (CBCharacteristic *)_chaXie;
    if(!characteristic) return;
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        // 这句才是正宗的核心代码
        [peripheral writeValue:message forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    
}

// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    XBLog(@">>>>> 连接到名称为（%@）的设备-失败",peripheral.name);
}
// 断开连接(丢失连接)
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    XBLog(@">>>>> 断开连接到名称为（%@）的设备",peripheral.name);
}

#pragma mark =======================================================
- (void)chatRoomWithSessionKey:(NSString *)key
{
    XBLog(@"============ 让我们开始聊天吧 ===========");
    self.sessionKey = key;
    
    // 显示密钥
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"会话密钥" message:key preferredStyle:UIAlertControllerStyleAlert];
    
    // 确定按钮
    [alert addAction:[UIAlertAction actionWithTitle:@"好的，知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // push聊天界面的控制器
        [self performSegueWithIdentifier:@"jump2chatRoom" sender:nil];
    }]];
    // 显示
    [self presentViewController:alert animated:YES completion:nil];
    
}

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    XBChatRoomViewController *vc = segue.destinationViewController;
    self.chatRoomVC = vc;
    vc.delegate = self;
    vc.userName = self.userName;
}

#pragma mark - XBChatRoomViewController的代理
- (void)chatRoomViewController:(XBChatRoomViewController *)chatRoomViewController didSendMessage:(NSString *)message
{
    // 0.加密数据所需的密钥和向量
    NSData *key = [XBSHA bytesOfSHA256WithString:self.sessionKey];
    NSData *iv = [self generate12BytesIvWithInput:self.sessionKey];
    
    // 1.构造要传输的数据
    NSData *name_data = [XBDataConversionFactory getDataFromString:self.userName];
    NSData *message_data = [XBDataConversionFactory getDataFromString:message];
    
    Pair *pairContents = [Pair new];
    pairContents.first = [XBGCM_AES encryptionData:name_data withKye:key andVi:iv];
    pairContents.second =[XBGCM_AES encryptionData:message_data withKye:key andVi:iv];
    
    M2 *m = [M2 new];
    m.k.k1K2 = pairContents;
    
    
    // 2.发送数据
    NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(sendProtolMessage:) object:[m data]];
    [thread start];

}


#pragma mark - UITableView的数据源方法
// 有多少设备
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devicesModelArray.count;
}

// 第indexPath个cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 获得数据模型
    XBDeviceModel *model = self.devicesModelArray[indexPath.row];
    
    // 设置cell
    JBDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deviceCell"];
    cell.device = model;
    return cell;
}

#pragma mark - UITableView的代理
// 每一个cell的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

// 单击设备选项卡时触发的动作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma mark - 信息发送部分 ：A->B
    
    XBLog(@"***************************************************************");
    XBLog(@"%@",self.devicesModelArray);
    for(int i=0;i<self.devicesModelArray.count;i++) {
        XBLog(@"%d--%@",[self.devicesModelArray[i] dKind],[self.devicesModelArray[i] deviceNme]);
    }
    
    
    // 在设备列表之中点击了某一个设备
    // 该用户是用户A
    self.userKind = kUserKindA;
    // 发信息给其他设备
    // 初始化双线性映射相关的参数
    NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
    const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    pbc_demo_pairing_init(pairing,ss);
    if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
    element_init_G1(P, pairing);
    element_init_Zr(a, pairing);
    element_init_G1(Pa, pairing);
    // 参数相关
    element_from_hash(P, "a.properties", 12);
    element_random(a);
    
    element_mul_zn(Pa, P, a);
    element_printf("加密：Pa = %B\n", Pa);
    
    // 将Pa转化为数组
    int len = element_length_in_bytes(Pa);
    unsigned char digest[len];
    element_to_bytes(digest, Pa);
    //         // 从字节数组中恢复
    //         element_t t;
    //         element_init_G1(t, pairing);
    //         element_from_bytes(t, digest);
    //         element_printf("Pa = %B\n", t);
    
    
    NSData *key = [self generate32BytesKey];
    NSData *iv = [self generate12BytesIv];
    Byte *ivBytes = (Byte *)[iv bytes];
    
    
    // 协议中的步骤：
    // 1.加密Pa,生成C1_1
    NSData *data_Pa = [NSData dataWithBytes:digest length:len];
    NSData *data_encrypt_Pa = [XBGCM_AES encryptionData:data_Pa withKye:key andVi:iv];
    Byte * byte_encrypt_pa =(Byte *) [data_encrypt_Pa bytes];
    NSUInteger len_C1_1 = [data_encrypt_Pa length] + 12;
    Byte *byte_C1_1 =(Byte *)malloc(len_C1_1);
    for(int i=0;i<12;i++) {
        byte_C1_1[i] = ivBytes[i];
    }
    for(int i=0;i<[data_encrypt_Pa length];i++) {
        byte_C1_1[i+12] = byte_encrypt_pa[i];
    }
    NSData *data_C1_1 = [NSData dataWithBytes:byte_C1_1 length:len_C1_1];
    
    // 2.连接C_11和A,生成C_1_2
    NSData *data_K_a_1 = key;
    NSData *data_A = [XBDataConversionFactory getDataFromString:self.userName];
    Byte *byte_A =(Byte *) [data_A bytes];
    Byte *byte_C_1_1_A = (Byte *)malloc([data_A length] + len_C1_1);
    for(int i=0;i<len_C1_1;i++) {
        byte_C_1_1_A[i] = byte_C1_1[i];
    }
    for(int i=0;i<[data_A length];i++) {
        byte_C_1_1_A[i+len_C1_1] = byte_A[i];
    }
    NSData *data_C_1_1_A = [NSData dataWithBytes:byte_C_1_1_A length:[data_A length] + len_C1_1];
    NSData *data_K_a_2 = [self generate32BytesKey];
    NSData *data_C_2_2 = [XBHMAC encryptionHMAC:data_C_1_1_A withKey:data_K_a_2];
    
    // 3.生成C_3_3
    NSData *data_C_3_3 = data_A;
    
    // ========================== 传输的数据 ====================
    // 创建信息部分
    C3 *a2b = [C3 new];
    a2b.c1 = data_C1_1;
    a2b.c2 = data_C_2_2;
    a2b.c3 = data_C_3_3;
    // 创建外包装
    M2 *m = [M2 new];
    m.m1 = a2b;
    // ============================= 发送
    //         [self sendProtolMessage:[m data]];
    //         NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(sendProtolMessage:) object:[m data]];
    //         [thread start];
    XBDeviceModel *model = (XBDeviceModel *)self.devicesModelArray[indexPath.row];
    dispatch_queue_t  queue= dispatch_queue_create("com.xiangbin.lanya.queue5", NULL);
    dispatch_async(queue, ^{
        [self sendProtolMessage:[m data] toOneDeviceModel:model];
    });
    
    
    
    Pair *pair_Key = [Pair new];
    pair_Key.first = data_K_a_1;
    pair_Key.second = data_K_a_2;
    
    K *k = [K new];
    k.k1K2 = pair_Key;
    
    M2 *mKey =[M2 new];
    mKey.k = k;
    NSData *data_pair = [mKey data];
    // 将pair转换成string
    NSString *str_pair = [XBDataConversionFactory getStringFromHexadecimalData:data_pair];
    XBLog(@"keyData: %@",data_pair);
    XBLog(@"keyString: %@",str_pair);
    
    // 设置生成的图片尺寸和位置
    float w = 200;
    float h = w;
    float x = (self.view.frame.size.width - w) * 0.5;
    float y = (self.view.frame.size.height - 20 - h)  * 0.5;
    
    //NSData *data = data_pair;
    UIImage *img = [self generateCodeWithData:[XBDataConversionFactory getDataFromString:str_pair] withSize:w];
    UIView *codeV = [[UIView alloc] initWithFrame:self.view.frame];
    codeV.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:codeV];
    
    
    CGRect rect = CGRectMake(x, y, w, h);
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:rect];
    imgV.image = img;
    [codeV addSubview:imgV];
    // 设置相关变量
    self.isCodeWindowShow = true;
    self.codeView = codeV;
    
}
@end
