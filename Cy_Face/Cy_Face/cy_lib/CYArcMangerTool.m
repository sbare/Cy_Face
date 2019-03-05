//
//  ArcMangerTool.m
//  ArcSoftFaceEngineDemo
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019 ArcSoft. All rights reserved.
//

#import "CYArcMangerTool.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import "ASFVideoProcessor.h"
#import "ASFCameraController.h"
#import "ColorFormatUtil.h"
#import "GLKitView.h"
#import "ASFRManager.h"

#define IMAGE_WIDTH     720
#define IMAGE_HEIGHT    1280

@interface CYArcMangerTool()<ASFCameraControllerDelegate,ASFVideoProcessorDelegate>
@end


@implementation CYArcMangerTool

static ASFVideoProcessor *_videoProcessor ;
static ASFCameraController *_cameraController;
static NSMutableArray *_arrayAllFaceRectView;
static GLKitView *_glView;//内部openGL视图
static CYEndRecognitionCompletionBlock _endRecognitionCompletionBlock;
static PersonalData *_personalData;
static ArcSoftFaceEngine *_engine;
//static NSMutableArray <ASFRPerson *>*_persons;
static ASFRManager *_frManager;
static LPASF_FaceFeature _faceFacture;

+(void)initialize
{
    //人脸数据进度
    _videoProcessor =  [[ASFVideoProcessor alloc] init];
    _videoProcessor.delegate = self;
    
    //脸部识别框以及数据_数组
    _arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    
    //采集人脸数据
    _cameraController = [[ASFCameraController alloc]init];
    _cameraController.delegate = self;
    [_cameraController setupCaptureSession:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation] isFront:YES];
    
    //采集到的模型数据
    _personalData = [[PersonalData alloc]init];
    
    _glView = [[GLKitView alloc]init];
    _frManager = [[ASFRManager alloc] init];
}

/**启动可切换前后置摄像头*/
//+(void)changeSwitchWithX:(float)x y:(float)y
//{
//    _switch.hidden = NO;
//    CGRect frame = _switch.frame;
//    frame.origin.x = x;
//    frame.origin.y = y;
//    _switch.frame = frame;
//}

+(NSMutableArray *)personArr;
{
    return  [_frManager.allPersons mutableCopy];
}

+(void)startRecognition:(UIView *)view endRecognitionCompletionBlock:(CYEndRecognitionCompletionBlock)endRecognitionCompletionBlock
{
    //开启监听
    [self startRecognition];
    
    //在此刻把外面传进来的代码块赋值内部block
    _endRecognitionCompletionBlock = endRecognitionCompletionBlock;
    
//    _glView.frame = view.bounds;
    [view insertSubview:_glView atIndex:0];
}

+(void)registerPersonWithName:(NSString *)name
{
    if (name != NULL && name.length > 0) {
        if([_videoProcessor registerDetectedPerson:name]){//注册成功
            NSLog(@"注册成功");
        }
    }
}

+(NSString *)engineActiveWithAppid:(NSString *)appid sdkkey:(NSString *)sdkkey{
    
    _engine = [[ArcSoftFaceEngine alloc] init];
    
    MRESULT mr = [_engine activeWithAppId:appid SDKKey:sdkkey];
    
    //引擎初始化
    MRESULT ar = [_engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                                        orientPriority:ASF_OP_0_HIGHER_EXT
                                                 scale:16
                                            maxFaceNum:10
                                          combinedMask:ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE];

    NSLog(@"初始化结果为：%ld", ar);
    
    if (mr == ASF_MOK) {//SDK激活成功
        return @"SDK激活成功";
    } else if(mr == MERR_ASF_ALREADY_ACTIVATED){//SDK已激活
        return @"SDK已激活";
    } else {//SDK激活失败
        return @"SDK激活失败";
    }
}

+(void)endRecognition
{
    [_cameraController stopCaptureSession];
    [_videoProcessor uninitProcessor];
}

/**开始人脸识别*/
+(void)stopRecognition
{
    _glView.hidden = YES;
    [_cameraController stopCaptureSession];
}

/**暂停人脸识别*/
+(void)startRecognition
{
    _glView.hidden = NO;
    //每次监听都要重新配置
    [_videoProcessor initProcessor];
    [_cameraController startCaptureSession];
}

+(void)recognitionWithImage:(UIImage *)selectImage originImage:(UIImage *)originImage
{
    //[self clearChildView];
    //对图片宽高进行对齐处理
    int imageWidth = selectImage.size.width;
    int imageHeight = selectImage.size.width;
    if (imageWidth % 4 != 0) {
        imageWidth = imageWidth - (imageWidth % 4);
    }
    if (imageHeight % 2 != 0) {
        imageHeight = imageHeight - (imageHeight % 2);
    }
    CGRect rect = CGRectMake(0, 0, imageWidth, imageHeight);
    selectImage = [Utility clipWithImageRect:rect clipImage:selectImage];
    
    unsigned char* pRGBA = [ColorFormatUtil bitmapFromImage:selectImage];
    MInt32 dataWidth = selectImage.size.width;
    MInt32 dataHeight = selectImage.size.height;
    MUInt32 format = ASVL_PAF_NV12;
    MInt32 pitch0 = dataWidth;
    MInt32 pitch1 = dataWidth;
    MUInt8* plane0 = (MUInt8*)malloc(dataHeight * dataWidth * 3/2);
    MUInt8* plane1 = plane0 + dataWidth * dataHeight;
    unsigned char* pBGR = (unsigned char*)malloc(dataHeight * LINE_BYTES(dataWidth, 24));
    RGBA8888ToBGR(pRGBA, dataWidth, dataHeight, dataWidth * 4, pBGR);
    BGRToNV12(pBGR, dataWidth, dataHeight, plane0, pitch0, plane1, pitch1);
    
    ASF_MultiFaceInfo* fdResult = (ASF_MultiFaceInfo*)malloc(sizeof(ASF_MultiFaceInfo));
    fdResult->faceRect = (MRECT*)malloc(sizeof(fdResult->faceRect));
    fdResult->faceOrient = (MInt32*)malloc(sizeof(fdResult->faceOrient));
    
    //FD
    MRESULT mr = [_engine detectFacesWithWidth:dataWidth
                                        height:dataHeight
                                          data:plane0
                                        format:format
                                       faceRes:fdResult];
    
    NSString* fdResultStr = @"";
    if (mr == ASF_MOK) {
        if (fdResult->faceNum == 0) {
            fdResultStr = @"未检测到人脸";
        } else {
            fdResultStr = [NSString stringWithFormat:@"detectFaces检测成功,人脸框：rect[%d,%d,%d,%d]",
                           fdResult->faceRect->left, fdResult->faceRect->top,
                           fdResult->faceRect->right, fdResult->faceRect->bottom];
        }
    } else {
        fdResultStr = [NSString stringWithFormat:@"detectFaces检测失败：%ld，请重新选择", mr];
    }
    
    if (mr == ASF_MOK) {
        mr = [_engine processWithWidth:dataWidth
                                height:dataHeight
                                  data:plane0
                                format:format
                               faceRes:fdResult
                                  mask:ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE];
        if (mr == ASF_MOK) {
            //age
            ASF_AgeInfo ageInfo = {0};
            mr = [_engine getAge:&ageInfo];
            if (mr == ASF_MOK) {
                NSString *strFD = [NSString stringWithFormat:@"年龄为：%d", (int)ageInfo.ageArray[0]];
            }
            
            //gender
            ASF_GenderInfo genderInfo = {0};
            mr = [_engine getGender:&genderInfo];
            if (mr == ASF_MOK) {
                NSString *strGender = [NSString stringWithFormat:@"性别为：%@", genderInfo.genderArray[0] == 1 ? @"女" : @"男"];
            }
            
            //3DAngle
            ASF_Face3DAngle angleInfo = {0};
            mr = [_engine getFace3DAngle:&angleInfo];
            if (mr == ASF_MOK) {
                NSString *strAngle = [NSString stringWithFormat:@"3DAngle:[yaw:%f,roll:%f,pitch:%f]", angleInfo.yaw[0], angleInfo.roll[0], angleInfo.pitch[0]];
            }
            
            //FR
            ASF_SingleFaceInfo frInputFace = {0};
            frInputFace.rcFace.left = fdResult->faceRect[0].left;
            frInputFace.rcFace.top = fdResult->faceRect[0].top;
            frInputFace.rcFace.right = fdResult->faceRect[0].right;
            frInputFace.rcFace.bottom = fdResult->faceRect[0].bottom;
            frInputFace.orient = fdResult->faceOrient[0];
            ASF_FaceFeature feature1 = {0};
            NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
            mr = [_engine extractFaceFeatureWithWidth:dataWidth
                                               height:dataHeight
                                                 data:plane0
                                               format:format
                                             faceInfo:&frInputFace
                                              feature:&feature1];
            NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
            if (mr == ASF_MOK) {
                NSLog(@"FRTime:%dms, feature1:%d", (int)(cost * 1000), feature1.featureSize);
            }
            
            LPASF_FaceFeature copyFeature1 = (LPASF_FaceFeature)malloc(sizeof(ASF_FaceFeature));
            copyFeature1->featureSize = feature1.featureSize;
            copyFeature1->feature = (MByte*)malloc(feature1.featureSize);
            memcpy(copyFeature1->feature, feature1.feature, copyFeature1->featureSize);
            _faceFacture = copyFeature1;
            
            unsigned char* pRGBA2 = [ColorFormatUtil bitmapFromImage:originImage];
            MInt32 picWidth2 = originImage.size.width;
            MInt32 picHeight2 = originImage.size.height;
            //            NSLog(@"width2:%d height2:%d", picWidth2, picHeight2);
            MInt32 format2 = ASVL_PAF_NV12;
            MInt32 pi32Pitch20 = picWidth2;
            MInt32 pi32Pitch21 = picWidth2;
            MUInt8* ppu8Plane20 = (MUInt8*)malloc(picHeight2 * picWidth2 * 3/2);
            MUInt8* ppu8Plane21 = ppu8Plane20 + pi32Pitch20 * picHeight2;
            unsigned char* pBGR2 = (unsigned char*)malloc(picHeight2 * LINE_BYTES(picWidth2, 24));
            RGBA8888ToBGR(pRGBA2, picWidth2, picHeight2, picWidth2 * 4, pBGR2);
            BGRToNV12(pBGR2, picWidth2, picHeight2, ppu8Plane20, pi32Pitch20, ppu8Plane21, pi32Pitch21);
            
            ASF_MultiFaceInfo fdResult2 = {0};
            
            mr = [_engine detectFacesWithWidth:picWidth2
                                        height:picHeight2
                                          data:ppu8Plane20
                                        format:format2
                                       faceRes:&fdResult2];
            ASF_SingleFaceInfo frInputFace2 = {0};
            frInputFace2.rcFace.left = fdResult2.faceRect[0].left;
            frInputFace2.rcFace.top = fdResult2.faceRect[0].top;
            frInputFace2.rcFace.right = fdResult2.faceRect[0].right;
            frInputFace2.rcFace.bottom = fdResult2.faceRect[0].bottom;
            frInputFace2.orient = fdResult2.faceOrient[0];
            ASF_FaceFeature feature2 = {0};
            mr = [_engine extractFaceFeatureWithWidth:picWidth2
                                               height:picHeight2
                                                 data:ppu8Plane20
                                               format:format2
                                             faceInfo:&frInputFace2
                                              feature:&feature2];
            
            
            
            //FM
            MFloat confidence = 0.0;
            mr = [_engine compareFaceWithFeature:copyFeature1
                                        feature2:&feature2
                                 confidenceLevel:&confidence];
            if (mr == ASF_MOK) {
                NSLog(@"FM比对结果为：%f", confidence);
            } else {
                NSLog(@"FM失败为：%ld", mr);
            }
        }
    }
    SafeArrayFree(pBGR);
    SafeArrayFree(pRGBA);
}
+(BOOL)registerPhotoPersonWithName:(NSString *)name
{
    ASFRPerson *registerPerson = [[ASFRPerson alloc] init];
    registerPerson.faceFeatureData = [NSData dataWithBytes:_faceFacture->feature length:_faceFacture->featureSize];
    if(registerPerson == nil || registerPerson.registered)
        return NO;
    
    registerPerson.name = name;
    registerPerson.Id = [_frManager getNewPersonID];
    registerPerson.registered = [_frManager addPerson:registerPerson];
    
    return registerPerson.registered;
}
+ (void)changeFront:(BOOL)isOn {
    [_cameraController setupCaptureSession:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation] isFront:isOn];
    [_cameraController stopCaptureSession];
    [_cameraController startCaptureSession];
}
+(void)setGLViewFrame:(CGRect)rect
{
    _glView.frame = rect;
}
+(NSInteger)frontBack
{
    return  [_cameraController frontBack];
}
#pragma mark - AFVideoProcessorDelegate
+ (void)processRecognized:(NSString *)personName
{
    if(personName != nil){//匹配到人
        _personalData.name = personName;
        //_endRecognitionCompletionBlock(_personalData);
    }
}

+ (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect
{
    CGRect frameFaceRect = {0};
    CGRect frameGLView = _glView.frame;
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*(faceRect.right-faceRect.left)/IMAGE_WIDTH;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*(faceRect.bottom-faceRect.top)/IMAGE_HEIGHT;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left/IMAGE_WIDTH;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top/IMAGE_HEIGHT;
    
    return frameFaceRect;
}

#pragma mark - AFVideoProcessorDelegate
+(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [_videoProcessor process:cameraData];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [_glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        
        if(_arrayAllFaceRectView.count >= arrayFaceInfo.count)
        {
            for (NSUInteger face=arrayFaceInfo.count; face<_arrayAllFaceRectView.count; face++) {
                UIView *faceRectView = [_arrayAllFaceRectView objectAtIndex:face];
                faceRectView.hidden = YES;
            }
        }
        else
        {
            for (NSUInteger face=_arrayAllFaceRectView.count; face<arrayFaceInfo.count; face++) {
                UIStoryboard *faceRectStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIView *faceRectView = [faceRectStoryboard instantiateViewControllerWithIdentifier:@"FaceRectVideoController"].view;
                [_glView addSubview:faceRectView];
                [_arrayAllFaceRectView addObject:faceRectView];
            }
        }
        
        for (NSUInteger face = 0; face < arrayFaceInfo.count; face++) {
            //人脸框
            UIView *faceRectView = [_arrayAllFaceRectView objectAtIndex:face];
            ASFVideoFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
            faceRectView.hidden = NO;
            faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
            UILabel* labelInfo = (UILabel*)[faceRectView viewWithTag:1];
            [labelInfo setTextColor:[UIColor yellowColor]];
            labelInfo.font = [UIFont boldSystemFontOfSize:15];
            MInt32 gender = faceInfo.gender;
            //            NSString *genderInfo = gender == 0 ? @"男" : (gender == 1 ? @"女" : @"不确定");
            //            labelInfo.text = [NSString stringWithFormat:@"age:%d gender:%@", faceInfo.age, genderInfo];
            //            UILabel* labelFaceAngle = (UILabel*)[faceRectView viewWithTag:6];
            //            labelFaceAngle.font = [UIFont boldSystemFontOfSize:15];
            //            [labelFaceAngle setTextColor:[UIColor yellowColor]];
            if(faceInfo.face3DAngle.status == 0) {
                //                labelFaceAngle.text = [NSString stringWithFormat:@"r=%.2f y=%.2f p=%.2f", faceInfo.face3DAngle.rollAngle, faceInfo.face3DAngle.yawAngle, faceInfo.face3DAngle.pitchAngle];
                
                _personalData.rollAngle = faceInfo.face3DAngle.rollAngle;
                _personalData.yawAngle = faceInfo.face3DAngle.yawAngle;
                _personalData.pitchAngle = faceInfo.face3DAngle.pitchAngle;
                _personalData.imageBufferRef = cameraFrame;
                
                _endRecognitionCompletionBlock(_personalData);
                
            } else {
                //                labelFaceAngle.text = @"Failed face 3D Angle";
                
            }
            
            _personalData.Sexual = gender;
            _personalData.age = faceInfo.age;
        }
        if(arrayFaceInfo == nil)  _endRecognitionCompletionBlock(nil);
    });
    [Utility freeCameraData:cameraData];
}




@end
