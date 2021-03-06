//
//  URLTemplateLayer.hpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 9/29/13.
//
//

#ifndef __G3MiOSSDK__URLTemplateLayer__
#define __G3MiOSSDK__URLTemplateLayer__

#include "RasterLayer.hpp"

#include "Sector.hpp"
class IStringUtils;


class URLTemplateLayer : public RasterLayer {
private:
  const std::string _urlTemplate;
  const bool        _isTransparent;

#ifdef C_CODE
  mutable const IMathUtils*   _mu;
  mutable const IStringUtils* _su;
#endif
#ifdef JAVA_CODE
  private IMathUtils   _mu;
  private IStringUtils _su;
#endif

  const Sector _dataSector;

protected:
  std::string getLayerType() const {
    return "URLTemplate";
  }

  virtual const std::string getPath(const LayerTilesRenderParameters* layerTilesRenderParameters,
                                    const Tile* tile,
                                    const Sector& sector) const;

  bool rawIsEquals(const Layer* that) const;

  const TileImageContribution* rawContribution(const Tile* tile) const;

  const URL createURL(const Tile* tile) const;

public:
  static URLTemplateLayer* newMercator(const std::string&    urlTemplate,
                                       const Sector&         dataSector,
                                       const bool            isTransparent,
                                       const int             firstLevel,
                                       const int             maxLevel,
                                       const TimeInterval&   timeToCache,
                                       const bool            readExpired    = true,
                                       const float           transparency   = 1,
                                       const LayerCondition* condition      = NULL,
                                       const std::string&    disclaimerInfo = "");

  static URLTemplateLayer* newWGS84(const std::string&    urlTemplate,
                                    const Sector&         dataSector,
                                    const bool            isTransparent,
                                    const int             firstLevel,
                                    const int             maxLevel,
                                    const TimeInterval&   timeToCache,
                                    const bool            readExpired    = true,
                                    const LayerCondition* condition      = NULL,
                                    const float           transparency   = 1,
                                    const std::string&    disclaimerInfo = "");

  URLTemplateLayer(const std::string&                urlTemplate,
                   const Sector&                     dataSector,
                   const bool                        isTransparent,
                   const TimeInterval&               timeToCache,
                   const bool                        readExpired,
                   const LayerCondition*             condition,
                   const LayerTilesRenderParameters* parameters,
                   float                             transparency   = 1,
                   const std::string&                disclaimerInfo = "");

  const std::string description() const;

  URLTemplateLayer* copy() const;

  URL getFeatureInfoURL(const Geodetic2D& position,
                        const Sector& sector) const;

  std::vector<Petition*> createTileMapPetitions(const G3MRenderContext* rc,
                                                const LayerTilesRenderParameters* layerTilesRenderParameters,
                                                const Tile* tile) const;
  
  RenderState getRenderState();

  const Sector getDataSector() const {
    return _dataSector;
  }

};

#endif
