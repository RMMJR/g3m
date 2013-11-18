//
//  G3MDemoModel.cpp
//  G3MApp
//
//  Created by Diego Gomez Deck on 11/16/13.
//  Copyright (c) 2013 Igo Software SL. All rights reserved.
//

#include "G3MDemoModel.hpp"

#include <G3MiOSSDK/LayerSet.hpp>
#include <G3MiOSSDK/ILogger.hpp>
#include <G3MiOSSDK/GEORenderer.hpp>
#include <G3MiOSSDK/GEOTileRasterizer.hpp>
#include <G3MiOSSDK/MarksRenderer.hpp>
#include <G3MiOSSDK/MeshRenderer.hpp>
#include <G3MiOSSDK/ShapesRenderer.hpp>
#include <G3MiOSSDK/ErrorHandling.hpp>
#include <G3MiOSSDK/G3MWidget.hpp>

#include "G3MDemoScene.hpp"
#include "G3MDemoListener.hpp"
#include "G3MRasterLayersDemoScene.hpp"
#include "G3MVectorialDemoScene.hpp"


G3MDemoModel::G3MDemoModel(G3MDemoListener* listener,
                           LayerSet* layerSet,
                           GEORenderer* geoRenderer) :
_listener(listener),
_g3mWidget(NULL),
_layerSet(layerSet),
_geoRenderer(geoRenderer),
_selectedScene(NULL)
{
  _scenes.push_back( new G3MRasterLayersDemoScene(this) );
  //  _scenes.push_back( new G3MDemoScene("Scenario+DEM") );
  _scenes.push_back( new G3MVectorialDemoScene(this) );
  //  _scenes.push_back( new G3MDemoScene("Markers") );
  //  _scenes.push_back( new G3MDemoScene("3D Symbology") );
  //  _scenes.push_back( new G3MDemoScene("Point clouds") );
  //  _scenes.push_back( new G3MDemoScene("3D Model") );
  //  _scenes.push_back( new G3MDemoScene("Camera") );

  selectScene(_scenes[0]);
}

void G3MDemoModel::setG3MWidget(G3MWidget* g3mWidget) {
  if (_g3mWidget != NULL) {
    ERROR("G3MWidget already set");
  }
  _g3mWidget = g3mWidget;
}

void G3MDemoModel::reset() {
  _g3mWidget->setBackgroundColor( Color::fromRGBA(0.0f, 0.1f, 0.2f, 1.0f) );

  _g3mWidget->setShownSector( Sector::fullSphere() );

  _layerSet->removeAllLayers(true);

  _geoRenderer->getGeoTileRasterizer()->clear();
  _geoRenderer->getMarksRenderer()->removeAllMarks();
  _geoRenderer->getMeshRenderer()->clearMeshes();
  _geoRenderer->getShapesRenderer()->removeAllShapes(true);
}

G3MDemoScene* G3MDemoModel::getSceneByName(const std::string& sceneName) const {
  const int scenesSize = _scenes.size();
  for (int i = 0; i < scenesSize; i++) {
    G3MDemoScene* scene = _scenes[i];
    if (scene->getName() == sceneName) {
      return scene;
    }
  }
  return NULL;
}

void G3MDemoModel::selectScene(const std::string& sceneName) {
  G3MDemoScene* scene = getSceneByName(sceneName);
  if (scene == NULL) {
    ILogger::instance()->logError("Invalid sceneName \"%s\"", sceneName.c_str());
  }
  else {
    selectScene(scene);
  }
}

void G3MDemoModel::selectScene(G3MDemoScene* scene) {
  if ((scene != NULL) &&
      (scene != _selectedScene)) {

    if (_selectedScene != NULL) {
      _selectedScene->deactivate();
    }

    ILogger::instance()->logInfo("Selected scene \"%s\"", scene->getName().c_str());

    _selectedScene = scene;
    _selectedScene->activate();

    if (_listener != NULL) {
      _listener->onChangedScene(_selectedScene);
    }
  }

}

void G3MDemoModel::onChangeSceneOption(G3MDemoScene* scene,
                                       const std::string& option,
                                       int optionIndex) {
  ILogger::instance()->logInfo("Selected option \"%s\" in scene \"%s\"", option.c_str(), scene->getName().c_str());

  if (_listener != NULL) {
    _listener->onChangeSceneOption(scene, option, optionIndex);
  }

}