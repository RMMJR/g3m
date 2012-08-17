//
//  EAGLView.m
//  Prueba Opengl iPad
//
//  Created by Agustín Trujillo Pino on 12/01/11.
//  Copyright 2011 Universidad de Las Palmas. All rights reserved.
//

#import "G3MWidget_iOS.h"

#import "ES2Renderer.h"

#include "G3MWidget.hpp"
#include "CompositeRenderer.hpp"
#include "Planet.hpp"
#include "Logger_iOS.hpp"
#include "Factory_iOS.hpp"

#include "CameraRenderer.hpp"
#include "CameraSingleDragHandler.hpp"
#include "CameraDoubleDragHandler.hpp"
#include "CameraRotationHandler.hpp"
#include "CameraDoubleTapHandler.hpp"
#include "CameraConstraints.hpp"

#include "Downloader.hpp"
#include "TileRenderer.hpp"
#include "DummyRenderer.hpp"
#include "MarksRenderer.hpp"
#include "SimplePlanetRenderer.hpp"
#include "Effects.hpp"
#include "SceneGraphRenderer.hpp"
#include "GLErrorRenderer.hpp"
#include "EllipsoidalTileTessellator.hpp"
#include "LatLonMeshRenderer.h"

//#include "FileSystemStorage_iOS.hpp"
#include "SQLiteStorage_iOS.hpp"
#include "NullStorage.hpp"
#include "TileImagesTileTexturizer.hpp"
#include "SingleImageTileTexturizer.hpp"
#include "BusyQuadRenderer.hpp"
#include "BusyMeshRenderer.hpp"
#include "CPUTextureBuilder.hpp"
#include "LayerSet.hpp"
#include "WMSLayer.hpp"
#include "StaticImageLayer.hpp"

#include "CachedDownloader.hpp"
#include "Downloader_iOS.hpp"

#include "INativeGL.hpp"
#include "NativeGL2_iOS.hpp"
#include "GL.hpp"

#include "MultiLayerTileTexturizer.hpp"
#include "TilesRenderParameters.hpp"

#include "Box.hpp"

#include <stdlib.h>

@interface G3MWidget_iOS ()
@property(nonatomic, getter=isAnimating) BOOL animating;
@end

class OceanTerrainTouchEventListener: public TerrainTouchEventListener, IDownloadListener{
  IFactory*    const _factory;
  IDownloader* const _downloader;
public:
  
  OceanTerrainTouchEventListener(IFactory* f, IDownloader* d):_factory(f), _downloader(d){}
  
  void onTerrainTouchEvent(const TerrainTouchEvent& event){
    //      printf("POINT %f, %f", event._g2d.latitude().degrees(), event._g2d.longitude().degrees());
    URL url = event._layer->getFeatureURL(event._g2d, _factory, event._sector, 256, 256);
    //      printf("%s\n", url.getPath().c_str());
    
    _downloader->request(url, 999999999, this, false);
  }
  
  void onDownload(const Response* response) {
    std::string s = (char*) response->getByteBuffer()->getData();
    //printf("%s\n", s.c_str());
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FEATURE"
                                                    message:[NSString stringWithCString:s.c_str()
                                                                               encoding:NSUTF8StringEncoding]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
  
  void onError(const Response* response) {
    printf("Error in request\n");
  }
  
  void onCanceledDownload(const Response* response) {
  }
  
  void onCancel(const URL* url) {
    printf("Cancel in request\n");
  }
};


@implementation G3MWidget_iOS

@synthesize animating              = _animating;
@synthesize animationFrameInterval = _animationFrameInterval;
@synthesize displayLink            = _displayLink;
@synthesize animationTimer         = _animationTimer;
@synthesize renderer               = _renderer;
@synthesize widget                 = _widget;
/*@synthesize  multipleTouchEnabled*/


// You must implement this method
+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void) initWidgetCSIRO
{
  // create GLOB3M WIDGET
  int width = (int) [self frame].size.width;
  int height = (int) [self frame].size.height;

  IFactory *factory = new Factory_iOS();
  ILogger *logger = new Logger_iOS(ErrorLevel);
  
  
  
  NativeGL2_iOS * nGL = new NativeGL2_iOS(); 
  GL* gl  = new GL(nGL);

  // composite renderer is the father of the rest of renderers
  CompositeRenderer* comp = new CompositeRenderer();
  
  // camera renderer and handlers
  CameraRenderer *cameraRenderer;
  cameraRenderer = new CameraRenderer();
  cameraRenderer->addHandler(new CameraSingleDragHandler);
  cameraRenderer->addHandler(new CameraDoubleDragHandler);
  cameraRenderer->addHandler(new CameraRotationHandler);
  cameraRenderer->addHandler(new CameraDoubleTapHandler);
  comp->addRenderer(cameraRenderer);
  
  
  //STORAGE
//  NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//  IStorage* storage = new FileSystemStorage_iOS(URL([documentsDirectory cStringUsingEncoding:NSUTF8StringEncoding]));
  IStorage* storage = new SQLiteStorage_iOS("g3m.cache");
  Downloader* downloaderOLD = new Downloader(storage, 5, factory->createNetwork());
  IDownloader* downloader = new CachedDownloader(new Downloader_iOS(8),
                                                 storage);
  
  //LAYERS
  LayerSet* layerSet = new LayerSet();
//  WMSLayer* baseLayer = new WMSLayer("bmng200405",
//                                     "http://www.nasa.network.com/wms?",
//                                     WMS_1_1_0,
//                                     "image/jpeg",
//                                     Sector::fullSphere(),
//                                     "EPSG:4326",
//                                     "",
//                                     false,
//                                     Angle::nan(),
//                                     Angle::nan());
//  layerSet->addLayer(baseLayer);

  if (false){
//    Sector s = Sector::fromDegrees(-60, 50, 10, 185);
//    WMSLayer *wmsl = new WMSLayer("test:contourGSLA",
//                                  "http://imos2.ersa.edu.au/geo2/test/wms",
//                                  WMS_1_1_0,
//                                  "image/png",
//                                  s,
//                                  "EPSG:4326",
//                                  "sla_test",
//                                  true,
//                                  Angle::nan(),
//                                  Angle::nan());
//    
//    WMSLayer *wms_sst = new WMSLayer("sea_surface_temperature",
//                                     "http://opendap-vpac.arcs.org.au/thredds/wms/IMOS/SRS/GHRSST-SSTsubskin/2012/20120626-ABOM-L3P_GHRSST-SSTsubskin-AVHRR_MOSAIC_01km-AO_DAAC-v01-fv01_0.nc?",
//                                     WMS_1_3_0,
//                                     "image/png",
//                                     s,
//                                     "EPSG:4326&COLORSCALERANGE=273.8%2C302.8&NUMCOLORBANDS=50&LOGSCALE=false",
//                                     "boxfill%2Fsst_36",
//                                     true,
//                                     Angle::nan(),
//                                     Angle::nan());
//    
//    layerSet->addLayer(wmsl);
//    layerSet->addLayer(wms_sst);
  }
  
  WMSLayer *oceans = new WMSLayer("igo:bmng200401,igo:ocean_2010_0_15",
                                  "igo:ocean_2010_0_15",
                                  "http://igosoftware.dyndns.org:8081/geoserver/igo/wms",
                                  WMS_1_3_0,
                                  "image/jpeg",
                                  Sector::fullSphere(),
                                  "EPSG:4326",
                                  "",
                                  false,
                                  Angle::nan(),
                                  Angle::nan());
  
  oceans->addTerrainTouchEventListener(new OceanTerrainTouchEventListener(factory, downloader));
  
  layerSet->addLayer(oceans);
  
  //STATIC IMAGE FOR TESTING AUSTRALIA
//  IImage *image = factory->createImageFromFileName("20120720_cintp1.png");
//  StaticImageLayer * imageLayer = new StaticImageLayer("SIL",
//                                                       image,
//                                                       Sector::fromDegrees(-60, 50, 10, 185), 
//                                                       fss);
//  layerSet->addLayer(imageLayer);
  
  // very basic tile renderer
  if (true) {
    bool renderDebug = false;
    TilesRenderParameters* parameters = TilesRenderParameters::createDefault(renderDebug);
    
    TileTexturizer* texturizer = NULL;
    if (true) {
      const bool useNewTexturizer = true;
      if (useNewTexturizer) {
        texturizer = new MultiLayerTileTexturizer(layerSet);
      }
      else {
        texturizer = new TileImagesTileTexturizer(parameters, downloader, layerSet);
      }
    }
    else {
      //SINGLE IMAGE
      IImage *singleWorldImage = factory->createImageFromFileName("world.jpg");
      texturizer = new SingleImageTileTexturizer(parameters, singleWorldImage);
    }
    
    const bool showStatistics = false;
    TileRenderer* tr = new TileRenderer(new EllipsoidalTileTessellator(parameters->_tileResolution, true),
                                        texturizer,
                                        parameters,
                                        showStatistics);
    comp->addRenderer(tr);
  }
  
  if (false) {
    // dummy renderer with a simple box
    DummyRenderer* dum = new DummyRenderer();
    comp->addRenderer(dum);
  }
  
  if (false) {
    // simple planet renderer, with a basic world image
    SimplePlanetRenderer* spr = new SimplePlanetRenderer("world.jpg");
    comp->addRenderer(spr);
  }

  TextureBuilder* texBuilder = new CPUTextureBuilder();
  TexturesHandler* texturesHandler = new TexturesHandler(gl, factory, texBuilder, false);
  
  const Planet* planet = Planet::createEarth();
  
//  Renderer* busyRenderer = new BusyQuadRenderer("ProgressWheel.png");
  Renderer* busyRenderer = new BusyMeshRenderer();
  
  EffectsScheduler* scheduler = new EffectsScheduler();
  
  std::vector <ICameraConstrainer *> cameraConstraint;
  cameraConstraint.push_back(new SimpleCameraConstrainer);

  _widget = G3MWidget::create(factory,
                              logger,
                              gl,
                              texturesHandler,
                              downloaderOLD,
                              downloader,
                              planet, 
                              cameraConstraint,
                              comp,
                              busyRenderer,
                              scheduler,
                              width, height,
                              Color::fromRGBA((float)0, (float)0.1, (float)0.2, (float)1),
                              true);
  
  Geodetic3D australia = Geodetic3D::fromDegrees(-26.91, 133.94, 1.1e7);
  ((G3MWidget*)_widget)->getNextCamera()->setPosition(australia);

}

- (void) initWidgetDemo
{
  
  // create GLOB3M WIDGET
  int width = (int) [self frame].size.width;
  int height = (int) [self frame].size.height;

  IFactory *factory = new Factory_iOS();
  ILogger *logger = new Logger_iOS(ErrorLevel);
  
  NativeGL2_iOS * nGL = new NativeGL2_iOS(); 
  GL* gl  = new GL(nGL);
  
  //Testing BOX intersection
  if (true){
    Box b(Vector3D(-10,-10,-10) , Vector3D(10,10,10) );
    
    Vector3D v = b.intersectionWithRay(Vector3D(-20,0,0), Vector3D(1.0,0,0));
    printf("%f, %f, %f\n", v.x(), v.y(), v.z());
    
    Vector3D v1 = b.intersectionWithRay(Vector3D(-20,20,0), Vector3D(1.0,0,0));
    printf("%f, %f, %f\n", v1.x(), v1.y(), v1.z());
    
    Vector3D v2 = b.intersectionWithRay(Vector3D(-20,0,0), Vector3D(1.0,0.1,0));
    printf("%f, %f, %f\n", v2.x(), v2.y(), v2.z());
  }
  
  // composite renderer is the father of the rest of renderers
  CompositeRenderer* comp = new CompositeRenderer();
  
  // camera renderer and handlers
  CameraRenderer *cameraRenderer;
  cameraRenderer = new CameraRenderer();
  cameraRenderer->addHandler(new CameraSingleDragHandler);
  cameraRenderer->addHandler(new CameraDoubleDragHandler);
  cameraRenderer->addHandler(new CameraRotationHandler);
  cameraRenderer->addHandler(new CameraDoubleTapHandler);
  comp->addRenderer(cameraRenderer);

  
  //STORAGE
//  NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//  IStorage* storage = new FileSystemStorage_iOS(URL([documentsDirectory cStringUsingEncoding:NSUTF8StringEncoding]));
  IStorage* storage = new SQLiteStorage_iOS("g3m.cache");
  Downloader* downloaderOLD = new Downloader(storage, 5, factory->createNetwork());
//  const bool cleanCache = false;
//  IDownloader* downloader = new Downloader_iOS(4 * 1024 * 1024,     // 4Mb
//                                               1024 * 1024 * 1024,  // 1G
//                                               ".G3M_Cache",
//                                               8,
//                                               cleanCache);
  
  IDownloader* downloader = new CachedDownloader(new Downloader_iOS(8),
                                                 storage);
  
  if (false) {
    
    class Listener : public IDownloadListener {
    private:
      int _onDownload;
      int _onError;
      int _onCancel;

    public:
      Listener() :
      _onDownload(0),
      _onError(0),
      _onCancel(0)
      {
        
      }
      
      void onDownload(const Response* response) {
        _onDownload++;
        BOOL isMainThread = [NSThread isMainThread];
        if (isMainThread) {
          NSLog(@"*** Main-Thread: Downloaded %d bytes ***", response->getByteBuffer()->getLength());
        }
        else {
          NSLog(@"*** NOT IN Main-Thread: Downloaded %d bytes ***", response->getByteBuffer()->getLength());
        }
      }
      
      void onError(const Response* response) {
        _onError++;
      }
      
      void onCancel(const URL* url) {
        _onCancel++;
      }
      
      void onCanceledDownload(const Response* response) {
      }
      
      void showInvalidState() const {
        printf("onDownload=%d, onCancel=%d, onError=%d\n", _onDownload, _onCancel, _onError);
      }
      
      void testState() const {
        if ((_onDownload == 1) && (_onCancel == 0) && (_onError == 0)) {
          return;
        }
        if ((_onDownload == 0) && (_onCancel == 1) && (_onError == 0)) {
          return;
        }
        if ((_onDownload == 0) && (_onCancel == 0) && (_onError == 1)) {
          return;
        }
        showInvalidState();
      }

      virtual ~Listener() {
        testState();
      }
    };
    
    const long priority = 999999999;
    long requestId = downloader->request(URL("http://glob3.sourceforge.net/img/isologo640x160.png"), priority, new Listener(), true);
    long requestId2 = downloader->request(URL("http://glob3.sourceforge.net/img/isologo640x160.png"), priority, new Listener(), true);
    downloader->cancelRequest(requestId);
    downloader->cancelRequest(requestId2);
    
    printf("break (point) on me");
  }

  
  //LAYERS
  LayerSet* layerSet = new LayerSet();
 
  WMSLayer* blueMarble = new WMSLayer("bmng200405",
                                      "http://www.nasa.network.com/wms?",
                                      WMS_1_1_0,
                                      "image/jpeg",
                                      Sector::fullSphere(),
                                      "EPSG:4326",
                                      "",
                                      false,
                                      Angle::nan(),
                                      Angle::nan());
  
//  WMSLayer *pnoa = new WMSLayer("PNOA",
//                                "http://www.idee.es/wms/PNOA/PNOA",
//                                WMS_1_1_0,
//                                "image/png",
//                                Sector::fromDegrees(21, -18, 45, 6),
//                                "EPSG:4326",
//                                "",
//                                true,
//                                Angle::nan(),
//                                Angle::nan());
//
//  WMSLayer *vias = new WMSLayer("VIAS",
//                                "http://idecan2.grafcan.es/ServicioWMS/Callejero",
//                                WMS_1_1_0,
//                                "image/gif",
//                                Sector::fromDegrees(22.5,-22.5, 33.75, -11.25),
//                                "EPSG:4326",
//                                "",
//                                true,
//                                Angle::nan(),
//                                Angle::nan());
  

//  WMSLayer *oceans = new WMSLayer("igo:bmng200401,igo:ocean_2010_0_15,igo:ocean_cnt_2010_0_15",
//                                  "igo:ocean_2010_0_15,igo:ocean_cnt_2010_0_15",
//                                  //                                  "igo:ocean_2010_0_15",
//                                  "http://igosoftware.dyndns.org:8081/geoserver/igo/wms",
//                                  WMS_1_3_0,
//                                  "image/jpeg",
//                                  Sector::fullSphere(),
//                                  "EPSG:4326",
//                                  "",
//                                  false,
//                                  Angle::nan(),
//                                  Angle::nan());

//  WMSLayer *oceans = new WMSLayer(//"igo:bmng200401,igo:ocean_2010_0_15",
//                                  "igo:bmng200401,igo:ocean_2010_0_15_tiled,igo:ocean_cnt__2010_0_15_tiled",
////                                  "igo:ocean_2010_0_15_tiled",
//                                  "igo:ocean_2010_0_15_tiled",
//                                  "http://igosoftware.dyndns.org:8081/geoserver/igo/wms",
//                                  WMS_1_3_0,
//                                  "image/jpeg",
//                                  Sector::fullSphere(),
//                                  "EPSG:4326",
//                                  "",
//                                  false,
//                                  Angle::nan(),
//                                  Angle::nan());
//
//  oceans->addTerrainTouchEventListener(new OceanTerrainTouchEventListener(factory, downloader));
  
  //ORDER IS IMPORTANT
  layerSet->addLayer(blueMarble);
//  layerSet->addLayer(pnoa);
//  layerSet->addLayer(vias);
//  layerSet->addLayer(oceans);
  
  // very basic tile renderer
  if (true) {
    const bool renderDebug = true;
    TilesRenderParameters* parameters = TilesRenderParameters::createDefault(renderDebug);
//    TilesRenderParameters* parameters = TilesRenderParameters::createSingleSector(renderDebug);
    
    TileTexturizer* texturizer = NULL;
    if (true) {
      const bool useNewTexturizer = true;
      if (useNewTexturizer) {
        texturizer = new MultiLayerTileTexturizer(layerSet);
      }
      else {
        texturizer = new TileImagesTileTexturizer(parameters, downloader, layerSet);
      }
    }
    else {
      //SINGLE IMAGE
      IImage *singleWorldImage = factory->createImageFromFileName("world.jpg");
      texturizer = new SingleImageTileTexturizer(parameters, singleWorldImage);
    }
    
    const bool showStatistics = true;
    TileRenderer* tr = new TileRenderer(new EllipsoidalTileTessellator(parameters->_tileResolution, true),
                                        texturizer,
                                        parameters,
                                        showStatistics);
    comp->addRenderer(tr);
  }
  
  if (false) {
    // dummy renderer with a simple box
    DummyRenderer* dum = new DummyRenderer();
    comp->addRenderer(dum);
  }
  
  if (false) {
    // simple planet renderer, with a basic world image
    SimplePlanetRenderer* spr = new SimplePlanetRenderer("world.jpg");
    comp->addRenderer(spr);
  }
  
  if (false) {
    // marks renderer
    MarksRenderer* marks = new MarksRenderer();
    comp->addRenderer(marks);
    
    Mark* m1 = new Mark("Fuerteventura",
                        "g3m-marker.png",
                        Geodetic3D(Angle::fromDegrees(28.05), Angle::fromDegrees(-14.36), 0));
    //m1->addTouchListener(listener);
    marks->addMark(m1);
    
    
    Mark* m2 = new Mark("Las Palmas",
                        "g3m-marker.png",
                        Geodetic3D(Angle::fromDegrees(28.05), Angle::fromDegrees(-15.36), 0));
    //m2->addTouchListener(listener);
    marks->addMark(m2);
    
    if (false) {
      for (int i = 0; i < 500; i++) {
        const Angle latitude = Angle::fromDegrees( (int) (arc4random() % 180) - 90 );
        const Angle longitude = Angle::fromDegrees( (int) (arc4random() % 360) - 180 );
        //NSLog(@"lat=%f, lon=%f", latitude.degrees(), longitude.degrees());
        
        marks->addMark(new Mark("Random",
                                "g3m-marker.png",
                                Geodetic3D(latitude, longitude, 0)));
      }
    }
  }
  
  if (false) {
    LatLonMeshRenderer *renderer = new LatLonMeshRenderer();
    comp->addRenderer(renderer);
  }
  
  EffectsScheduler* scheduler = new EffectsScheduler();
  
  if (false) {
    EffectTarget* target = NULL;
    scheduler->startEffect(new SampleEffect(TimeInterval::fromSeconds(2)),
                           target);
  }
  
  if (false) {
    SceneGraphRenderer* sgr = new SceneGraphRenderer();
    SGCubeNode* cube = new SGCubeNode();
    // cube->setScale(Vector3D(6378137.0, 6378137.0, 6378137.0));
    sgr->getRootNode()->addChild(cube);
    comp->addRenderer(sgr);
  }
  
  comp->addRenderer(new GLErrorRenderer());
  
  
  TextureBuilder* texBuilder = new CPUTextureBuilder();
  TexturesHandler* texturesHandler = new TexturesHandler(gl, factory, texBuilder, false);
  
  const Planet* planet = Planet::createEarth();
  
  //Renderer* busyRenderer = new BusyQuadRenderer("ProgressWheel.png");
  Renderer* busyRenderer = new BusyMeshRenderer();
  
  std::vector <ICameraConstrainer *> cameraConstraint;
  cameraConstraint.push_back(new SimpleCameraConstrainer);

  _widget = G3MWidget::create(factory,
                              logger,
                              gl,
                              texturesHandler,
                              downloaderOLD,
                              downloader,
                              planet, 
                              cameraConstraint,
                              comp,
                              busyRenderer,
                              scheduler,
                              width, height,
                              Color::fromRGBA((float)0, (float)0.1, (float)0.2, (float)1),
                              true);
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  
  if (self) {
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.layer;
    
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    // create GL object
    _renderer = [[ES2Renderer alloc] init];
    if (!_renderer) {
      printf("**** ERROR: G3MWidget_iOS Mobile needs Opengl ES 2.0\n");
      return nil;
    }
    else {
      printf("*** Using Opengl ES 2.0\n\n");
      glver = OpenGL_2;
    }
    
    
    NSLog(@"----------------------------------------------------------------------------");
    NSLog(@"OpenGL Extensions:");
    NSString *extensionString = [[NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *extensions = [extensionString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (NSString *extension in extensions) {
        NSLog(@"  %@", extension);
    }
    NSLog(@"----------------------------------------------------------------------------");
    
    
    lastTouchEvent = NULL;

    // rest of initialization
    _animating = FALSE;
    _displayLinkSupported = FALSE;
    _animationFrameInterval = 1;
    _displayLink = nil;
    _animationTimer = nil;
    
    self.multipleTouchEnabled = YES; //NECESSARY FOR PROPER PINCH EVENT
    
    // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
    // class is used as fallback when it isn't available.
    NSString *reqSysVer = @"3.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
      _displayLinkSupported = TRUE;
    
    //Detecting LongPress
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressRecognizer.minimumPressDuration = 1.0;
    [self addGestureRecognizer:longPressRecognizer];
  }
  return self;
}

//** Agustin cancelled lonpressgesture because touchedmoved and touchedended event don't work
- (IBAction)handleLongPress:(UIGestureRecognizer *)sender {

  printf ("Longpress. state=%d\n", sender.state);
  
  if (sender.state == UIGestureRecognizerStateEnded) {
    NSLog(@"LONG PRESS");
  }
  
  if (sender.state == 1){
    
    CGPoint tapPoint = [sender locationInView:sender.view.superview];
    
    std::vector<const Touch*> pointers = std::vector<const Touch*>();
    Touch *touch = new Touch(Vector2D(tapPoint.x, tapPoint.y), Vector2D(0.0, 0.0), 1);
    pointers.push_back(touch);
    lastTouchEvent = TouchEvent::create(LongPress, pointers);
    ((G3MWidget*)[self widget])->onTouchEvent(lastTouchEvent);
  }
  
}

- (void)drawView:(id)sender {
  if (_animating) {
    /*int timeToRedraw = */[_renderer render: [self widget]];
  }
}

- (void)layoutSubviews {
  int w = (int) [self frame].size.width;
  int h = (int) [self frame].size.height;
  NSLog(@"ResizeViewportEvent: %dx%d", w, h);
  ((G3MWidget*)_widget)->onResizeViewportEvent(w,h);
  
  [_renderer resizeFromLayer:(CAEAGLLayer *) self.layer];
  [self drawView:nil];
}

//- (NSInteger)animationFrameInterval {
//    return _animationFrameInterval;
//}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval {
  // Frame interval defines how many display frames must pass between each time the
  // display link fires. The display link will only fire 30 times a second when the
  // frame internal is two on a display that refreshes 60 times a second. The default
  // frame interval setting of one will fire 60 times a second when the display refreshes
  // at 60 times a second. A frame interval setting of less than one results in undefined
  // behavior.
  if (frameInterval >= 1) {
    _animationFrameInterval = frameInterval;
    
    if (_animating) {
      [self stopAnimation];
      [self startAnimation];
    }
  }
}

- (void)startAnimation {
  if (!_animating) {
    if (_displayLinkSupported) {
      self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                     selector:@selector(drawView:)];
      [_displayLink setFrameInterval:_animationFrameInterval];
      [_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                         forMode:NSDefaultRunLoopMode];
    }
    else {
      self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) ((1.0 / 60.0) * _animationFrameInterval) 
                                                             target:self
                                                           selector:@selector(drawView:)
                                                           userInfo:nil
                                                            repeats:TRUE];
    }
    
    self.animating = TRUE;
  }
}

- (void)stopAnimation {
  if (_animating) {
    if (_displayLinkSupported) {
      [_displayLink invalidate];
      self.displayLink = nil;
    }
    else {
      [_animationTimer invalidate];
      self.animationTimer = nil;
    }
    
    self.animating = FALSE;
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
  //NSSet *allTouches = [event allTouches];
  NSSet *allTouches = [event touchesForView:self];
  
  std::vector<const Touch*> pointers = std::vector<const Touch*>();
  // pointers.reserve([allTouches count]);
  
  NSEnumerator *enumerator = [allTouches objectEnumerator];
  UITouch *touch = nil;
  while ((touch = [enumerator nextObject])) {
    CGPoint current         = [touch locationInView:self];
    CGPoint previous        = [touch previousLocationInView:self];
    unsigned char tapCount  = (unsigned char) [touch tapCount];
    
    Touch *touch = new Touch(Vector2D(current.x, current.y), 
                             Vector2D(previous.x, previous.y),
                             tapCount);
    
    pointers.push_back(touch);
  }
  
  if (lastTouchEvent!=NULL) {
    delete lastTouchEvent;
  }
  lastTouchEvent = TouchEvent::create(Down, pointers);
  ((G3MWidget*)[self widget])->onTouchEvent(lastTouchEvent);
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
  //NSSet *allTouches = [event allTouches];
  NSSet *allTouches = [event touchesForView:self];
  
  std::vector<const Touch*> pointers = std::vector<const Touch*>();
  
  NSEnumerator *enumerator = [allTouches objectEnumerator];
  UITouch *touch = nil;
  while ((touch = [enumerator nextObject])) {
    CGPoint current  = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    
    Touch *touch = new Touch(Vector2D(current.x, current.y), 
                             Vector2D(previous.x, previous.y));
    
    pointers.push_back(touch);
  }
  
  // test if finger orders are the same that in the previous gesture
  if (lastTouchEvent!=NULL) {
    if (pointers.size()==2 && lastTouchEvent->getTouchCount()==2) {
      Vector2D current0 = pointers[0]->getPrevPos();
      Vector2D last0 = lastTouchEvent->getTouch(0)->getPos();
      Vector2D last1 = lastTouchEvent->getTouch(1)->getPos();
      delete lastTouchEvent;
      double dist0 = current0.sub(last0).squaredLength();
      double dist1 = current0.sub(last1).squaredLength();
      
      // swap finger order
      if (dist1<dist0) {
        std::vector<const Touch*> swappedPointers = std::vector<const Touch*>();
        swappedPointers.push_back(pointers[1]);
        swappedPointers.push_back(pointers[0]);
        lastTouchEvent = TouchEvent::create(Move, swappedPointers);
      } else {
        lastTouchEvent = TouchEvent::create(Move, pointers);
      }
    } else {
      delete lastTouchEvent;
      lastTouchEvent = TouchEvent::create(Move, pointers);
    }
  } else {
    lastTouchEvent = TouchEvent::create(Move, pointers);
  }
  
  ((G3MWidget*)[self widget])->onTouchEvent(lastTouchEvent);
}



- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  //NSSet *allTouches = [event allTouches];
  NSSet *allTouches = [event touchesForView:self];
  
  std::vector<const Touch*> pointers = std::vector<const Touch*>();
  // pointers.reserve([allTouches count]);
  
  NSEnumerator *enumerator = [allTouches objectEnumerator];
  UITouch *touch = nil;
  while ((touch = [enumerator nextObject])) {
    CGPoint current  = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    
    [touch timestamp];
    
    Touch *touch = new Touch(Vector2D(current.x, current.y), 
                             Vector2D(previous.x, previous.y));
    
    pointers.push_back(touch);
  }
  
  if (lastTouchEvent!=NULL) {
    delete lastTouchEvent;
  }
  lastTouchEvent = TouchEvent::create(Up, pointers);
  ((G3MWidget*)[self widget])->onTouchEvent(lastTouchEvent);
}


- (void)dealloc {
  if (lastTouchEvent!=NULL) {
    delete lastTouchEvent;
  }
}

@end
