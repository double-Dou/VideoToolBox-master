//
//  AVCaptureManager.m
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/27.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import "AVCaptureManager.h"
#import "VideoEndcoder.h"

@interface AVCaptureManager()<AVCaptureVideoDataOutputSampleBufferDelegate>
//前后摄像头
@property(nonatomic, strong) AVCaptureDeviceInput * frontCamera;
@property(nonatomic, strong) AVCaptureDeviceInput * backCamera;
//当前正在使用的设备
@property(nonatomic, strong) AVCaptureDeviceInput * currentVideoInputDevice;
@property(nonatomic, strong) AVCaptureDeviceInput * audioInputDevice;
//输出数据接收
@property(nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property(nonatomic, strong) AVCaptureAudioDataOutput * audioDataOutput;
//会话(输入输出之间的中介)
@property(nonatomic, strong) AVCaptureSession * captureSession;
//预览图层
@property(nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;
//视频的输入与输出设备的连接
@property(nonatomic, weak) AVCaptureConnection *videoConnection;
//将要显示到的控制器
@property(nonatomic, strong) UIViewController *viewController;
//聚焦视图
@property (nonatomic, strong) UIImageView *focusImageView;
//编码器
@property (nonatomic, strong) VideoEndcoder *endcoder;
@end
@implementation AVCaptureManager

//懒加载
-(UIImageView *)focusImageView
{
    if (!_focusImageView) {
        _focusImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"focus"]];
        [self.viewController.view addSubview:_focusImageView];
    }
    return _focusImageView;
}

-(UIView *)backView
{
    if (!_backView) {
        _backView = [[UIView alloc]initWithFrame:self.viewController.view.frame];
    }
    return _backView;
}

//初始化方法
-(instancetype)initAVCaptureManagerWithViewController:(UIViewController *)viewController
{
    if (self = [super init]) {
        self.viewController = viewController;
        self.isCapturing = NO;
        [self createInputDevice];
        [self createOutput];
        [self createSession];
        [self initPreviewLayer];
        
        self.endcoder = [[VideoEndcoder alloc]initVideoEndcoder];
        
    }
    return self;
}

//初始化音视频输入设备
-(void)createInputDevice
{
    //获取摄像头设备
    NSArray * cameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //用摄像头设备初始化视频输入设备
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevices.firstObject error:nil];
    //获取麦克风
    AVCaptureDevice * audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //用麦克风初始化音频输入设备
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    self.currentVideoInputDevice = self.frontCamera;
}

//初始化输出设备
-(void)createOutput
{
    // 获取视频数据输出设备
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    // 设置代理，捕获视频样品数据
    // 注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:videoQueue];
    // 获取音频数据输出设备
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    // 设置代理，捕获视频样品数据
    // 注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [self.audioDataOutput setSampleBufferDelegate:self queue:audioQueue];
    
}

//初始化对象
-(void)createSession
{
    self.captureSession = [[AVCaptureSession alloc]init];
    // 设置录像分辨率
    [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    //将输入设备加入会话中
    if ([self.captureSession canAddInput:self.currentVideoInputDevice]) {
        [self.captureSession addInput:self.currentVideoInputDevice];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    //将输出设备加入会话
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    }
    
    if ([self.captureSession canAddOutput:self.audioDataOutput]) {
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    // 9.获取视频输入与输出连接，用于分辨音视频数据
    //_videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //开启会话
    [self.captureSession startRunning];
}

//初始化预览图层
-(void)initPreviewLayer
{
    // 10.添加视频预览图层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.viewController.view.frame;
    [self.backView.layer insertSublayer:self.previewLayer atIndex:0];
    [self.viewController.view insertSubview:self.backView atIndex:0];
}
//会话销毁
-(void)destoryCaptureSession
{
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.currentVideoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
        [self.previewLayer removeFromSuperlayer];
        [self.backView removeFromSuperview];
        self.isCapturing = NO;
    }
    self.captureSession = nil;
}

//切换摄像头
-(void)changeCamera
{
    [self.captureSession removeInput:self.currentVideoInputDevice];
    self.currentVideoInputDevice = self.currentVideoInputDevice == self.frontCamera?self.backCamera : self.frontCamera;
    [self.captureSession addInput:self.currentVideoInputDevice];
    
}

//点击设置屏幕聚焦
-(void)setfocusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point
{
    // 把当前位置转换为摄像头点上的位置
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    //设置聚焦光标位置和显示
    self.focusImageView.center=point;
    self.focusImageView.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusImageView.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusImageView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusImageView.alpha=0;
        
    }];
    
    AVCaptureDevice *captureDevice = _currentVideoInputDevice.device;
    // 锁定配置
    [captureDevice lockForConfiguration:nil];
    
    // 设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:cameraPoint];
    }
    
    // 设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:cameraPoint];
    }
    
    // 解锁配置
    [captureDevice unlockForConfiguration];
}

//采集到数据的代理回调
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.isCapturing) {
        if (captureOutput == self.videoDataOutput) {
            NSLog(@"处理视频数据:%@",sampleBuffer);
            [self.endcoder encodeFrame:sampleBuffer];//进行编码
            
        }else
        {
            //NSLog(@"处理音频数据:%@",sampleBuffer);
        }
    }else
    {
        NSLog(@"未进行数据处理");
    }
}

@end
