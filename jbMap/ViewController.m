//
//  ViewController.m
//  jbMap
//
//  Created by jb on 15/7/17.
//  Copyright (c) 2015年 jb. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import "CLLocation+Sino.h"
#import <CoreLocation/CoreLocation.h>
#import "myLocationButton.h"

@interface ViewController ()<MAMapViewDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,AMapSearchDelegate>
{
    MAMapView *_mapView;
    CLLocationManager *_manage;
    UITextField *_textField;
    AMapSearchAPI *_search;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //地图库配置
    //(1)库拖入工程
    //(2)初始化
    //显示地图
    //地图常用配置
    //地图标记
    //poi搜索
    
    [self navBarButtonAndTextField];
    
    [self creatMapView];
    
    [self mapConfig];
    
    [self creatManage];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressClick:)];
    longPress.delegate = self;
    
    [_mapView addGestureRecognizer:longPress];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)navBarButtonAndTextField{

    _textField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, 260, 36)];
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    
    _textField.delegate = self;
    
    self.navigationItem.titleView = _textField;
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc]initWithTitle:@"搜索" style:UIBarButtonItemStylePlain target:self action:@selector(dealSearch)];
    self.navigationItem.rightBarButtonItem = searchItem;
    
    _search = [[AMapSearchAPI alloc]initWithSearchKey:@"02aba3b2eceb0089e9df55e412d78def" Delegate:self];
    UIBarButtonItem *geoItem = [[UIBarButtonItem alloc]initWithTitle:@"GEO" style:UIBarButtonItemStylePlain target:self action:@selector(geoClick)];
    self.navigationItem.leftBarButtonItem = geoItem;
    
}

-(void)geoClick{
    
    //构造AMapGeocodeSearchRequest对象，address为必选项，city为可选项
    AMapGeocodeSearchRequest *geoRequest = [[AMapGeocodeSearchRequest alloc] init];
    geoRequest.searchType = AMapSearchType_Geocode;
    geoRequest.address = @"智汇park创意园";
    geoRequest.city = @[@"guangzhou"];
    
    //发起正向地理编码
    [_search AMapGeocodeSearch: geoRequest];
}

//实现正向地理编码的回调函数
- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response
{
    if(response.geocodes.count == 0)
    {
        return;
    }
    
    //通过AMapGeocodeSearchResponse对象处理搜索结果
    NSString *strCount = [NSString stringWithFormat:@"count: %ld", (long)response.count];
    NSString *strGeocodes = @"";
    for (AMapTip *p in response.geocodes) {
        strGeocodes = [NSString stringWithFormat:@"%@\ngeocode: %@", strGeocodes, p.description];
    }
    NSString *result = [NSString stringWithFormat:@"%@ \n %@", strCount, strGeocodes];
    NSLog(@"Geocode: %@", result);
}

-(void)dealSearch{

    [_textField resignFirstResponder];
    
    [self palceAroundSearch];
    
}

-(void)palceAroundSearch{

    CLLocation *location = [[CLLocation alloc]initWithLatitude:23.178444 longitude:113.335089];
    location = [location locationMarsFromEarth];
    //构造AMapPlaceSearchRequest对象，配置关键字搜索参数
    
    AMapPlaceSearchRequest *poiRequest = [[AMapPlaceSearchRequest alloc] init];
    poiRequest.searchType = AMapSearchType_PlaceAround;
    poiRequest.keywords = _textField.text;
    poiRequest.city = @[@"guangzhou"];
    poiRequest.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    poiRequest.requireExtension = YES;
    
    //发起POI搜索
    [_search AMapPlaceSearch: poiRequest];
}

- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    for (AMapPOI *poi in response.pois) {
        
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc]init];
        annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
        annotation.title = poi.name;
        
        annotation.subtitle = [NSString stringWithFormat:@"地址%@ 电话%@",poi.address,poi.tel];
        [_mapView addAnnotation:annotation];
    }
//    if(response.pois.count == 0)
//    {
//        return;
//    }
//    
//    //通过AMapPlaceSearchResponse对象处理搜索结果
//    NSString *strCount = [NSString stringWithFormat:@"count: %ld",(long)response.count];
//    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion];
//    NSString *strPoi = @"";
//    for (AMapPOI *p in response.pois) {
//        strPoi = [NSString stringWithFormat:@"%@\nPOI: %@", strPoi, p.description];
//    }
//    NSString *result = [NSString stringWithFormat:@"%@ \n %@ \n %@", strCount, strSuggestion, strPoi];
//    NSLog(@"Place: %@", result);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{

    [textField resignFirstResponder];
    
    textField.returnKeyType = UIReturnKeyDone;
    
    return YES;
}

-(void)creatMapView{
    
    _mapView = [[MAMapView alloc]initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    
    [self.view addSubview:_mapView];
}

-(void)mapConfig{
    
    _mapView.mapType = MAMapTypeStandard;
    
    _mapView.showTraffic = YES;
    
    CLLocation *location = [[CLLocation alloc]initWithLatitude:23.178444 longitude:113.335089];
    location = [location locationMarsFromEarth];
    
    _mapView.centerCoordinate = location.coordinate;
    
    _mapView.zoomLevel = 17;
    
}

-(void)creatManage{
    
    _manage = [[CLLocationManager alloc]init];
    
    _manage.delegate = self;
    
    if (![CLLocationManager locationServicesEnabled]) {
        return;
    }
    [_manage requestAlwaysAuthorization];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        NSLog(@"授权成功！");
        
        _mapView.showsUserLocation = YES;
        
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
        
    }
}


-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{

    
    return YES;
}

-(void)longPressClick:(UILongPressGestureRecognizer*)longPress{

    if (longPress.state == UIGestureRecognizerStateEnded) {
        
        CGPoint point = [longPress locationInView:_mapView];
        
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:point toCoordinateFromView:_mapView];
        
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc]init];
        annotation.title = @"地图标记";
        
        annotation.coordinate = coordinate;
        
        annotation.subtitle = [NSString stringWithFormat:@"loc = %f,lon = %f",coordinate.latitude,coordinate.longitude];
        [_mapView addAnnotation:annotation];
        
    }
    
}

-(MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{

    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        return nil;
    }
    
    static NSString *indentify = @"id";
    MAPinAnnotationView *pin = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:indentify];
    
    if (pin == nil) {
        pin = [[MAPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:indentify];
    }
    
    pin.pinColor = MAPinAnnotationColorPurple;
    
    pin.animatesDrop = YES;
    //显示说明
    pin.canShowCallout = YES;
    
    myLocationButton *btn = [myLocationButton buttonWithType:UIButtonTypeSystem];
    [btn sizeToFit];
    
    [btn setTitle:@"导航" forState:UIControlStateNormal];
    
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    pin.rightCalloutAccessoryView = btn;
    
    btn.data = annotation;
    
    return pin;
}

-(void)btnClick:(myLocationButton *)btn{

    NSLog(@"start %f %f",_mapView.userLocation.coordinate.latitude,_mapView.userLocation.coordinate.longitude);
    
    MAPointAnnotation *annnotation = (MAPointAnnotation*)btn.data;
    
    NSLog(@"end %f %f",annnotation.coordinate.latitude,annnotation.coordinate.longitude);
    
    //构造AMapNavigationSearchRequest对象，配置查询参数
    AMapNavigationSearchRequest *naviRequest= [[AMapNavigationSearchRequest alloc] init];
    naviRequest.searchType = AMapSearchType_NaviWalking;
    naviRequest.requireExtension = YES;
    naviRequest.origin = [AMapGeoPoint locationWithLatitude:_mapView.userLocation.coordinate.latitude longitude:_mapView.userLocation.coordinate.longitude];
    naviRequest.destination = [AMapGeoPoint locationWithLatitude:annnotation.coordinate.latitude longitude:annnotation.coordinate.longitude];
    
    //发起路径搜索
    [_search AMapNavigationSearch: naviRequest];
}

- (void)onNavigationSearchDone:(AMapNavigationSearchRequest *)request response:(AMapNavigationSearchResponse *)response
{
    
//    for (AMapPath * p in response.route.paths) {
//        for (AMapStep *s in p.steps) {
//            NSLog(@"%@ %ld %@",s.instruction,(long)s.duration,s.polyline);
//        }
//    }
    if(response.route == nil)
    {
        return;
    }
    
    //通过AMapNavigationSearchResponse对象处理搜索结果
    NSString *route = [NSString stringWithFormat:@"Navi: %@", response.route];
    NSLog(@"%@", route);
}

//- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    if ([view.annotation isKindOfClass:[MAPointAnnotation class]])
//    {
//        //配置导航参数
//        MANaviConfig * config = [[MANaviConfig alloc] init];
//        config.destination = view.annotation.coordinate;//终点坐标，Annotation的坐标
//        config.appScheme = [self getApplicationScheme];//返回的Scheme，需手动设置
//        config.appName = [self getApplicationName];//应用名称，需手动设置
//        config.style = MADrivingStrategyShortest;
//        //若未调起高德地图App,引导用户获取最新版本的
//        if(![MANavigation openAMapNavigation:config])
//        {
//            [MANavigation getLatestAMapApp];
//        }
//    }
//}
//
//-(NSString *)getApplicationName
//{
//    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
//    return [bundleInfo valueForKey:@"CFBundleDisplayName"];
//}
//
//- (NSString *)getApplicationScheme
//{
//    NSDictionary *bundleInfo    = [[NSBundle mainBundle] infoDictionary];
//    NSString *bundleIdentifier  = [[NSBundle mainBundle] bundleIdentifier];
//    NSArray *URLTypes           = [bundleInfo valueForKey:@"CFBundleURLTypes"];
//    
//    NSString *scheme;
//    for (NSDictionary *dic in URLTypes)
//    {
//        NSString *URLName = [dic valueForKey:@"CFBundleURLName"];
//        if ([URLName isEqualToString:bundleIdentifier])
//        {
//            scheme = [[dic valueForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
//            break;
//        }
//    }
//    
//    return scheme;
//}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
