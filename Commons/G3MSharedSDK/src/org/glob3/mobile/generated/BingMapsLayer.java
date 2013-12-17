package org.glob3.mobile.generated; 
public class BingMapsLayer extends Layer
{
  private final String _imagerySet;
  private final String _key;

  private final int _initialLevel;

  private boolean _isInitialized;

  private String _brandLogoUri;
  private String _copyright;
  private String _imageUrl;
  private java.util.ArrayList<String> _imageUrlSubdomains = new java.util.ArrayList<String>();

  private void processMetadata(String brandLogoUri, String copyright, String imageUrl, java.util.ArrayList<String> imageUrlSubdomains, int imageWidth, int imageHeight, int zoomMin, int zoomMax)
  {
    _brandLogoUri = brandLogoUri;
    _copyright = copyright;
    _imageUrl = imageUrl;
    _imageUrlSubdomains = imageUrlSubdomains;
  
    _isInitialized = true;
  
    final IMathUtils mu = IMathUtils.instance();
  
    setParameters(new LayerTilesRenderParameters(Sector.fullSphere(), 1, 1, mu.max(zoomMin, _initialLevel), zoomMax, new Vector2I(imageWidth, imageHeight), LayerTilesRenderParameters.defaultTileMeshResolution(), true));
  }

  private String getQuadkey(int zoom, int column, int row)
  {
    IStringBuilder isb = IStringBuilder.newStringBuilder();
  
    for (int i = 1; i <= zoom; i++)
    {
      final int t = (((row >> (zoom - i)) & 1) << 1) | ((column >> (zoom - i)) & 1);
      isb.addInt(t);
    }
  
    final String result = isb.getString();
  
    if (isb != null)
       isb.dispose();
  
    return result;
  }

  protected final String getLayerType()
  {
    return "BingMaps";
  }

  protected final String getBrandLogoUri()
  {
    return _brandLogoUri;
  }

  protected final String getCopyright()
  {
    return _copyright;
  }

  protected final boolean rawIsEquals(Layer that)
  {
    BingMapsLayer t = (BingMapsLayer) that;
  
    if (!_imagerySet.equals(t._imagerySet))
    {
      return false;
    }
  
    if (!_key.equals(t._key))
    {
      return false;
    }
  
    if (_initialLevel != t._initialLevel)
    {
      return false;
    }
  
    return true;
  }


  /**
   imagerySet: "Aerial", "AerialWithLabels", "Road", "OrdnanceSurvey" or "CollinsBart". See class BingMapType for constants.
   key: Bing Maps key. See http: //msdn.microsoft.com/en-us/library/gg650598.aspx
   */
  public BingMapsLayer(String imagerySet, String key, TimeInterval timeToCache, boolean readExpired, int initialLevel)
  {
     this(imagerySet, key, timeToCache, readExpired, initialLevel, null);
  }
  public BingMapsLayer(String imagerySet, String key, TimeInterval timeToCache, boolean readExpired)
  {
     this(imagerySet, key, timeToCache, readExpired, 2, null);
  }
  public BingMapsLayer(String imagerySet, String key, TimeInterval timeToCache)
  {
     this(imagerySet, key, timeToCache, true, 2, null);
  }
  public BingMapsLayer(String imagerySet, String key, TimeInterval timeToCache, boolean readExpired, int initialLevel, LayerCondition condition)
  {
     super(condition, "BingMaps", timeToCache, readExpired, null);
     _imagerySet = imagerySet;
     _key = key;
     _initialLevel = initialLevel;
     _isInitialized = false;
  
  }

  public final URL getFeatureInfoURL(Geodetic2D position, Sector sector)
  {
    return new URL();
  }

  public final java.util.ArrayList<Petition> createTileMapPetitions(G3MRenderContext rc, LayerTilesRenderParameters layerTilesRenderParameters, Tile tile)
  {
    java.util.ArrayList<Petition> petitions = new java.util.ArrayList<Petition>();
  
    final IStringUtils su = IStringUtils.instance();
  
    final int level = tile._level;
    final int column = tile._column;
    final int numRows = (int) IMathUtils.instance().pow(2.0, level);
    final int row = numRows - tile._row - 1;
  
    final int subdomainsSize = _imageUrlSubdomains.size();
    String subdomain = "";
    if (subdomainsSize > 0)
    {
      // select subdomain based on fixed data (instead of round-robin) to be cache friendly
      final int subdomainsIndex = IMathUtils.instance().abs(level + column + row) % subdomainsSize;
      subdomain = _imageUrlSubdomains.get(subdomainsIndex);
    }
  
    final String quadkey = getQuadkey(level, column, row);
  
    String path = _imageUrl;
    path = su.replaceSubstring(path, "{subdomain}", subdomain);
    path = su.replaceSubstring(path, "{quadkey}", quadkey);
    path = su.replaceSubstring(path, "{culture}", "en-US");
  
    petitions.add(new Petition(tile._sector, new URL(path, false), getTimeToCache(), getReadExpired(), true));
  
    return petitions;
  }

//C++ TO JAVA CONVERTER TODO TASK: The implementation of the following method could not be found:
//  boolean isReady();

  public final void initialize(G3MContext context)
  {
    final URL url = new URL("http://dev.virtualearth.net/REST/v1/Imagery/Metadata/" + _imagerySet + "?key=" + _key, false);
  
    context.getDownloader().requestBuffer(url, DownloadPriority.HIGHEST, TimeInterval.fromDays(1), true, new BingMapsLayer_MetadataBufferDownloadListener(this), true);
  }

  public final void onDowloadMetadata(IByteBuffer buffer)
  {
    IJSONParser parser = IJSONParser.instance();
  
    final JSONBaseObject jsonBaseObject = parser.parse(buffer);
    if (jsonBaseObject == null)
    {
      ILogger.instance().logError("BingMapsLayer: Can't parse json metadata.");
      return;
    }
  
    final JSONObject jsonObject = jsonBaseObject.asObject();
    if (jsonObject == null)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, root object is not an json-object.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final String brandLogoUri = jsonObject.getAsString("brandLogoUri", "");
    final String copyright = jsonObject.getAsString("copyright", "");
  
    final JSONArray resourceSets = jsonObject.getAsArray("resourceSets");
    if (resourceSets == null)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, resourceSets field not found.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    if (resourceSets.size() != 1)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, resourceSets has %d elements (the current implementation can only handle 1 element).", resourceSets.size());
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final JSONObject resource = resourceSets.getAsObject(0);
    if (resource == null)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, can't find resource jsonobject.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final JSONArray resources = resource.getAsArray("resources");
    if (resources.size() != 1)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, resources has %d elements (the current implementation can only handle 1 element).", resources.size());
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final JSONObject meanfulResource = resources.getAsObject(0);
    if (meanfulResource == null)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, can't find a meanfulResource JSONObject.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final String imageUrl = meanfulResource.getAsString("imageUrl", "");
    if (imageUrl.length() == 0)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, can't find a imageUrl String.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    final int imageWidth = (int) meanfulResource.getAsNumber("imageWidth", 256);
    final int imageHeight = (int) meanfulResource.getAsNumber("imageHeight", 256);
  
    final int zoomMin = (int) meanfulResource.getAsNumber("zoomMin", 1);
    final int zoomMax = (int) meanfulResource.getAsNumber("zoomMax", 1);
  
    final JSONArray imageUrlSubdomainsJS = meanfulResource.getAsArray("imageUrlSubdomains");
    if (imageUrlSubdomainsJS == null)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, can't find a imageUrlSubdomains JSONArray.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    java.util.ArrayList<String> imageUrlSubdomains = new java.util.ArrayList<String>();
    for (int i = 0; i < imageUrlSubdomainsJS.size(); i++)
    {
      final String imageUrlSubdomain = imageUrlSubdomainsJS.getAsString(i, "");
      if (imageUrlSubdomain.length() != 0)
      {
        imageUrlSubdomains.add(imageUrlSubdomain);
      }
    }
  
    if (imageUrlSubdomains.size() == 0)
    {
      ILogger.instance().logError("BingMapsLayer: Error while parsing json metadata, can't find any imageUrlSubdomain String.");
      parser.deleteJSONData(jsonBaseObject);
      return;
    }
  
    processMetadata(brandLogoUri, copyright, imageUrl, imageUrlSubdomains, imageWidth, imageHeight, zoomMin, zoomMax);
  
  //  http://ecn.{subdomain}.tiles.virtualearth.net/tiles/h{quadkey}.jpeg?g=1180&mkt={culture}
  
  
    parser.deleteJSONData(jsonBaseObject);
    if (buffer != null)
       buffer.dispose();
  }
  public final void onDownloadErrorMetadata()
  {
    ILogger.instance().logError("BingMapsLayer: Error while downloading metadata.");
  }

  public final String description()
  {
    return "[BingMapsLayer]";
  }

  public final BingMapsLayer copy()
  {
    return new BingMapsLayer(_imagerySet, _key, TimeInterval.fromMilliseconds(_timeToCacheMS), _readExpired, _initialLevel, (_condition == null) ? null : _condition.copy());
  }

  public final RenderState getRenderState()
  {
    _errors.clear();
    if (_imagerySet.compareTo("") == 0)
    {
      _errors.add("Missing layer parameter: imagerySet");
    }
    if (_key.compareTo("") == 0)
    {
      _errors.add("Missing layer parameter: key");
    }
  
    if (_errors.size() > 0)
    {
      return RenderState.error(_errors);
    }
    if (!_isInitialized)
    {
      return RenderState.busy();
    }
    return RenderState.ready();
  }
}