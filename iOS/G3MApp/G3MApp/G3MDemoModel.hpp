//
//  G3MDemoModel.hpp
//  G3MApp
//
//  Created by Diego Gomez Deck on 11/16/13.
//  Copyright (c) 2013 Igo Software SL. All rights reserved.
//

#ifndef __G3MApp__G3MDemoModel__
#define __G3MApp__G3MDemoModel__

#include <vector>
#include <string>

class G3MDemoListener;
class G3MDemoScene;
class LayerSet;
class GEORenderer;
class G3MWidget;
class G3MContext;
class GEOTileRasterizer;
class MarksRenderer;
class MeshRenderer;
class ShapesRenderer;
class PlanetRenderer;

class G3MDemoModel {
private:
  G3MDemoListener* _listener;

  G3MWidget* _g3mWidget;

  LayerSet*       _layerSet;
  GEORenderer*    _geoRenderer;

  G3MDemoScene*              _selectedScene;
  std::vector<G3MDemoScene*> _scenes;

  const G3MContext* _context;

public:

  G3MDemoModel(G3MDemoListener* listener,
               LayerSet* layerSet,
               GEORenderer* geoRenderer);

  void initializeG3MWidget(G3MWidget* g3mWidget);

  void initializeG3MContext(const G3MContext* context);

  G3MWidget* getG3MWidget() const {
    return _g3mWidget;
  }

  LayerSet* getLayerSet() const {
    return _layerSet;
  }

  GEORenderer* getGEORenderer() const {
    return _geoRenderer;
  }

  GEOTileRasterizer* getGEOTileRasterizer() const;

  MarksRenderer* getMarksRenderer() const;

  MeshRenderer* getMeshRenderer() const;

  ShapesRenderer* getShapesRenderer() const;

  PlanetRenderer* getPlanetRenderer() const;

  int getScenesCount() const {
    return _scenes.size();
  }

  const G3MDemoScene* getScene(int index) {
    return _scenes[index];
  }

  G3MDemoScene* getSceneByName(const std::string& sceneName) const;

  void selectScene(const std::string& sceneName);

  void selectScene(G3MDemoScene* scene);

  bool isSelectedScene(const G3MDemoScene* scene) const {
    return _selectedScene == scene;
  }

  G3MDemoScene* getSelectedScene() const {
    return _selectedScene;
  }

  void reset();

  void onChangeSceneOption(G3MDemoScene* scene,
                           const std::string& option,
                           int optionIndex);

  void showDialog(const std::string& title,
                  const std::string& message) const;

};

#endif
