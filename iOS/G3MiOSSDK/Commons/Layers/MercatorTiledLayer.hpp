//
//  MercatorTiledLayer.hpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 3/8/13.
//
//

#ifndef __G3MiOSSDK__MercatorTiledLayer__
#define __G3MiOSSDK__MercatorTiledLayer__

#include "RasterLayer.hpp"
#include "Sector.hpp"


class MercatorTiledLayer : public RasterLayer {
protected:
  const std::string _protocol;
  const std::string _domain;
#ifdef C_CODE
  const std::vector<std::string> _subdomains;
#endif
#ifdef JAVA_CODE
  protected final java.util.ArrayList<String> _subdomains;
#endif
  const std::string _imageFormat;

  const Sector _dataSector;

  const int    _initialLevel;
  const int    _maxLevel;
  const bool   _isTransparent;

  virtual std::string getLayerType() const{
    return "MercatorTiled";
  }

  virtual bool rawIsEquals(const Layer* that) const;

  const TileImageContribution* rawContribution(const Tile* tile) const;

  const URL createURL(const Tile* tile) const;

public:
  MercatorTiledLayer(const std::string&              protocol,
                     const std::string&              domain,
                     const std::vector<std::string>& subdomains,
                     const std::string&              imageFormat,
                     const TimeInterval&             timeToCache,
                     const bool                      readExpired,
                     const Sector&                   dataSector,
                     const int                       initialLevel,
                     const int                       maxLevel,
                     const bool                      isTransparent  = false,
                     const float                     transparency   = 1,
                     const LayerCondition*           condition      = NULL,
                     const std::string&              disclaimerInfo = "");

  URL getFeatureInfoURL(const Geodetic2D& position,
                        const Sector& sector) const;

  std::vector<Petition*> createTileMapPetitions(const G3MRenderContext* rc,
                                                const LayerTilesRenderParameters* layerTilesRenderParameters,
                                                const Tile* tile) const;

  virtual const std::string description() const;

  virtual MercatorTiledLayer* copy() const;

  virtual RenderState getRenderState();

  const Sector getDataSector() const {
    return _dataSector;
  }

};

#endif
