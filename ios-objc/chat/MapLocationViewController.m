//
//  MapLocationViewController.m
//  ixcode
//
//  Created by swift on 16/3/25.
//  Copyright © 2016年 macmac. All rights reserved.
//

#import "MapLocationViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import "CustomAnnotationView.h"

#define APIKey      @"064512a835b7bd6a381d6f3304f3ff0d"

#define kDefaultLocationZoomLevel       16.1
#define kDefaultControlMargin           22
#define kDefaultCalloutViewMargin       -8

@interface MapLocationViewController ()<MAMapViewDelegate, AMapSearchDelegate, UIGestureRecognizerDelegate>{
    
    MAMapView *_mapView;
    AMapSearchAPI *_search;
    
    CLLocation *_currentLocation;
    UIButton *_locationButton;
    
    UILabel *locationLabel;
    UITableView *_tableView;
    NSArray *_pois;
    NSMutableArray *_annotations;
    
    UITapGestureRecognizer *_tapGesture;
    MAPointAnnotation *_destinationPoint;
    
    NSArray *_pathPolylines;
    NSString *district;
    
    NSString *province;
}
@end

@implementation MapLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapView];
    [self initSearch];
    [self initControls];
    [self initShowView];
    [self initAttributes];
    [self initButton];
    
}

-(void)initButton{
    if (self.isSelectPoistion) {
        UIBarButtonItem *_actionButton=[[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(selectLocationPosition)];
        self.navigationItem.rightBarButtonItem = _actionButton;
    }
    
}

-(void)initData:(double)latitude longitude:(double)longitude isSelectLocation:(BOOL)isSelectLocation{
    self.latitude = latitude;
    self.longitude = longitude;
    self.isSelectPoistion = isSelectLocation;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
	  [_mapView removeAnnotations:_annotations];
	  [_annotations removeAllObjects];
    if(!self.isSelectPoistion){
        MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
        pointAnnotation.coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude);
        [_mapView addAnnotation:pointAnnotation];
        //计算中心点
        CLLocationCoordinate2D centCoor;
        centCoor.latitude = (CLLocationDegrees)(self.latitude);
        centCoor.longitude = (CLLocationDegrees)(self.longitude);
        MACoordinateSpan span;//= MKCoordinateSpanMake(0.01, 0.01);
        //计算地理位置的跨度
        span.latitudeDelta  = 0.031394;
        span.longitudeDelta = 0.027276;
        MACoordinateRegion region = MACoordinateRegionMake(centCoor, span);
        [_mapView setRegion:region animated:true];
    }
    else {
        [self locateAction];
    }
    
}

- (void)initMapView
{
    [MAMapServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)/1.2)];
    
    _mapView.delegate = self;
    
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, kDefaultControlMargin);
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, kDefaultControlMargin);
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    [self.view addSubview:_mapView];
    _mapView.showsScale = true;
    _mapView.showsCompass = true;
    if (self.isSelectPoistion) {
        _mapView.showsUserLocation = true;
    }
    else {
        _mapView.showsUserLocation = false;
    }
    
}

- (void)initSearch
{
    _search = [[AMapSearchAPI alloc] initWithSearchKey:APIKey Delegate:self];
}

- (void)initControls
{
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(kDefaultControlMargin, CGRectGetHeight(_mapView.bounds) - 60, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _locationButton.backgroundColor = [UIColor whiteColor];
    
    [_locationButton addTarget:self action:@selector(locateAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    
    [_mapView addSubview:_locationButton];
    
    //
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds) - 60, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = [UIColor whiteColor];
    [searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    
    [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_mapView addSubview:searchButton];
    
    //
    UIButton *pathButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pathButton.frame = CGRectMake(140, CGRectGetHeight(_mapView.bounds) - 60, 40, 40);
    pathButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    pathButton.backgroundColor = [UIColor whiteColor];
    [pathButton setImage:[UIImage imageNamed:@"path"] forState:UIControlStateNormal];
    
    [pathButton addTarget:self action:@selector(convertPoints) forControlEvents:UIControlEventTouchUpInside];
    
//    [_mapView addSubview:pathButton];
    
}

- (void)initAttributes
{
    _annotations = [NSMutableArray array];
    _pois = nil;
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapPress:)];
    _tapGesture.delegate = self;
    [_mapView addGestureRecognizer:_tapGesture];
}

- (void)initShowView
{
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) /6;
    
    locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-halfHeight, CGRectGetWidth(self.view.bounds), halfHeight)];
    locationLabel.backgroundColor = [UIColor whiteColor];
    locationLabel.userInteractionEnabled = true;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectLocationPosition)];
    
    [locationLabel addGestureRecognizer:gesture];
    
    [self.view addSubview:locationLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers

- (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect
{
    NSLog(@"----------- offsetToContainRect");
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - (CGRectGetMinX(innerRect)));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - (CGRectGetMaxX(innerRect)));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - (CGRectGetMinY(innerRect)));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - (CGRectGetMaxY(innerRect)));
    return CGSizeMake(nudgeLeft ?: nudgeRight, nudgeTop ?: nudgeBottom);
}



- (void)searchAction
{
    NSLog(@"----------- searchAction");
    if (_currentLocation == nil || _search == nil)
    {
        NSLog(@"search failed");
        return;
    }
    
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    request.searchType = AMapSearchType_PlaceAround;
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    
//    request.keywords = district;
    
    [_search AMapPlaceSearch:request];
}

- (void)locateAction
{
    NSLog(@"----------- locateAction");
    if (_mapView.userTrackingMode != MAUserTrackingModeFollow)
    {
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
        [_mapView setZoomLevel:kDefaultLocationZoomLevel animated:YES];
    }
}

- (void)reGeoAction
{
    NSLog(@"----------- reGeoAction");
    if (_currentLocation)
    {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        
        [_search AMapReGoecodeSearch:request];
    }
}

- (void)handleTapPress:(UITapGestureRecognizer *)gesture
{
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
    NSLog(@"----------- handleTapPress");
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:[gesture locationInView:_mapView]
                                              toCoordinateFromView:_mapView];
        
        // 添加标注
        if (_destinationPoint != nil)
        {
            // 清理
            [_mapView removeAnnotation:_destinationPoint];
            _destinationPoint = nil;
            
            [_mapView removeOverlays:_pathPolylines];
            _pathPolylines = nil;
        }
        
        _destinationPoint = [[MAPointAnnotation alloc] init];
        _destinationPoint.coordinate = coordinate;
        _destinationPoint.title = @"Destination";
        _currentLocation = _destinationPoint;
        AMapPOI *poi = _pois[0];
         NSLog(@"select position---%f, %f", _destinationPoint.coordinate.latitude, _destinationPoint.coordinate.longitude);
        
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
        annotation.title    = poi.name;
        annotation.subtitle = poi.address;
        [self searchAction];
        [self reGeoAction];
        [_mapView addAnnotation:_destinationPoint];
    }
    
}


-(void)selectLocationPosition{
    if(locationLabel.text == nil){
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"提示" message:@"请先点击地图选择位置" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.alertViewStyle=UIAlertViewStyleDefault;
        
        [alert show];
        return;
    }
    
    if (_destinationPoint == nil)
    {
        return;
    }
    UIImage *image = [_mapView takeSnapshotInRect:CGRectMake(0, 0, _mapView.frame.size.width-10, _mapView.frame.size.height-10)];
    
    UIImage * images = [self reSizeImage:image toSize:CGSizeMake(150, 150)];
    [_locationButton setImage:image forState:UIControlStateNormal];
    //    NSString *address = [NSString stringWithFormat:@"%@%@", province, locationLabel.text];
    self.locationBlock(images, _destinationPoint.coordinate.latitude, _destinationPoint.coordinate.longitude, locationLabel.text);
    
    NSLog(@"选择了地址:%@, 图片大小 width:%f, height:%f", locationLabel.text, images.size.width, image.size.height);
    
    MAPointAnnotation *destinationPoints = _destinationPoint;
    // 添加标注
    if (_destinationPoint != nil)
    {
        // 清理
        [_mapView removeAnnotation:_destinationPoint];
        _destinationPoint = nil;
        
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
    }
    _destinationPoint = destinationPoints;
    [self.navigationController popViewControllerAnimated:true];
}

- (void)convertPoints
{
    NSLog(@"----------- convertPoints");
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(_destinationPoint.coordinate.latitude, _destinationPoint.coordinate.longitude);

    // 添加标注
    if (_destinationPoint != nil)
    {
        // 清理
        [_mapView removeAnnotation:_destinationPoint];
        _destinationPoint = nil;
        
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
    }
    
    _destinationPoint = [[MAPointAnnotation alloc] init];
    _destinationPoint.coordinate = coordinate;
    _destinationPoint.title = @"Destination";
    _currentLocation = _destinationPoint;
    AMapPOI *poi = _pois[0];
    NSLog(@"select position---%f, %f", _destinationPoint.coordinate.latitude, _destinationPoint.coordinate.longitude);
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title    = poi.name;
    annotation.subtitle = poi.address;
    [self searchAction];
    [_mapView addAnnotation:_destinationPoint];
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
//    NSLog(@"response :%@", response);
    NSLog(@"----------- onReGeocodeSearchDone");
    
    NSString *title = response.regeocode.addressComponent.city;
    if (title.length == 0)
    {
        // 直辖市的city为空，取province
        title = response.regeocode.addressComponent.province;
    }
    
    if (_isSelectPoistion) {
        province = [NSString stringWithFormat:@"%@%@", response.regeocode.addressComponent.province, response.regeocode.addressComponent.city];
        NSLog(@"-----------%@",province);
    }
    // 更新我的位置title
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
    
}

- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    NSLog(@"----------- onPlaceSearchDone");
    //    NSLog(@"request: %@", request);
    //    NSLog(@"response: %@", response);
    
    if (response.pois.count > 0)
    {
        _pois = response.pois;
        AMapPOI *poi = _pois[0];
        locationLabel.text =  poi.address;
        [_tableView reloadData];
        
        // 清空标注
        [_mapView removeAnnotations:_annotations];
        [_annotations removeAllObjects];
    }
}

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay
{
    NSLog(@"----------- viewForOverlay");
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 4;
        polylineView.strokeColor = [UIColor magentaColor];
        
        return polylineView;
    }
    
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    NSLog(@"@%----------viewForAnnotation------@%", annotation, _destinationPoint);
//    _destinationPoint = annotation;
    if (annotation == _destinationPoint)
    {
        static NSString *reuseIndetifier = @"startAnnotationReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        return annotationView;
    }
//    if(self.isSelectPoistion){
//        if (annotation == _destinationPoint)
//        {
//            static NSString *reuseIndetifier = @"startAnnotationReuseIndetifier";
//            MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
//            if (annotationView == nil)
//            {
//                annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
//            }
//            
//            annotationView.canShowCallout = YES;
//            annotationView.animatesDrop = YES;
//            
//            return annotationView;
//        }
//
//    }
//    else {
//        if ([annotation isKindOfClass:[MAPointAnnotation class]])
//        {
//            static NSString *reuseIndetifier = @"annotationReuseIndetifier";
//            CustomAnnotationView *annotationView = (CustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
//            if (annotationView == nil)
//            {
//                annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
//            }
//            annotationView.image = [UIImage imageNamed:@"restaurant"];
//            
//            // 设置为NO，用以调用自定义的calloutView
//            annotationView.canShowCallout = NO;
//            
//            // 设置中心点偏移，使得标注底部中间点成为经纬度对应点
//            annotationView.centerOffset = CGPointMake(0, -18);
//            return annotationView;
//        }
    
//    }
    
    
    
    return nil;
}

- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    NSLog(@"----------- didChangeUserTrackingMode");
    // 修改定位按钮状态
    if (mode == MAUserTrackingModeNone)
    {
        [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    }
    else
    {
        [_locationButton setImage:[UIImage imageNamed:@"location_yes"] forState:UIControlStateNormal];
    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
     NSLog(@"----------- didUpdateUserLocation");
//        NSLog(@"userLocation: %@", userLocation.location);
    if (updatingLocation)
    {
        _currentLocation = [userLocation.location copy];
    }
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    NSLog(@"----------- didSelectAnnotationView");
    // 选中定位annotation的时候进行逆地理编码查询
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        [self reGeoAction];
    }
    
    // 调整自定义callout的位置，使其可以完全显示
    if ([view isKindOfClass:[CustomAnnotationView class]]) {
        CustomAnnotationView *cusView = (CustomAnnotationView *)view;
        CGRect frame = [cusView convertRect:cusView.calloutView.frame toView:_mapView];
        
        frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(kDefaultCalloutViewMargin, kDefaultCalloutViewMargin, kDefaultCalloutViewMargin, kDefaultCalloutViewMargin));
        
        if (!CGRectContainsRect(_mapView.frame, frame))
        {
            CGSize offset = [self offsetToContainRect:frame inRect:_mapView.frame];
            
            CGPoint theCenter = _mapView.center;
            theCenter = CGPointMake(theCenter.x - offset.width, theCenter.y - offset.height);
            
            CLLocationCoordinate2D coordinate = [_mapView convertPoint:theCenter toCoordinateFromView:_mapView];
            
            [_mapView setCenterCoordinate:coordinate animated:YES];
        }
        
    }
}

-(UIImage*)captureWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 2);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *newImages = UIGraphicsGetImageFromCurrentImageContext();
    [newImages drawInRect:CGRectMake(0, 0, 60, 60)];
    UIGraphicsEndImageContext();
    
    return newImages;
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}


@end
