//
//  HereLayer.hpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 3/7/13.
//
//

#ifndef __G3MiOSSDK__HereLayer__
#define __G3MiOSSDK__HereLayer__

#include "RasterLayer.hpp"

#include <string>


class HereLayer : public RasterLayer {
private:
  const std::string _appId;
  const std::string _appCode;
  const int         _initialLevel;

protected:
  std::string getLayerType() const{
    return "Here";
  }

  bool rawIsEquals(const Layer* that) const;


  const TileImageContribution* rawContribution(const Tile* tile) const;

  const URL createURL(const Tile* tile) const;

public:

  HereLayer(const std::string&    appId,
            const std::string&    appCode,
            const TimeInterval&   timeToCache,
            const bool            readExpired    = true,
            const int             initialLevel   = 2,
            const float           transparency   = 1,
            const LayerCondition* condition      = NULL,
            const std::string&    disclaimerInfo = "");

  std::vector<Petition*> createTileMapPetitions(const G3MRenderContext* rc,
                                                const LayerTilesRenderParameters* layerTilesRenderParameters,
                                                const Tile* tile) const;

  URL getFeatureInfoURL(const Geodetic2D& position,
                        const Sector& sector) const;

  const std::string description() const;

  HereLayer* copy() const;

  RenderState getRenderState();

  const Sector getDataSector() const {
    return Sector::fullSphere();
  }
  
};

#endif
