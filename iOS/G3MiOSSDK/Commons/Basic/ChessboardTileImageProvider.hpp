//
//  ChessboardTileImageProvider.hpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 4/23/14.
//
//

#ifndef __G3MiOSSDK__ChessboardTileImageProvider__
#define __G3MiOSSDK__ChessboardTileImageProvider__

#include "TileImageProvider.hpp"

class IImage;

class ChessboardTileImageProvider : public TileImageProvider {
private:
  const int _splits;

  IImage* _image;

protected:
  ~ChessboardTileImageProvider();

public:
  ChessboardTileImageProvider(int splits = 8) :
  _splits(splits),
  _image(NULL)
  {
  }

  const TileImageContribution* contribution(const Tile* tile);

  void create(const Tile* tile,
              const TileImageContribution* contribution,
              const Vector2I& resolution,
              long long tileDownloadPriority,
              bool logDownloadActivity,
              TileImageListener* listener,
              bool deleteListener,
              FrameTasksExecutor* frameTasksExecutor);

  void cancel(const std::string& tileId);

  void imageCreated(const IImage* image,
                    const Tile* tile,
                    TileImageListener* listener,
                    bool deleteListener);

};

#endif
