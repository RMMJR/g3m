package org.glob3.mobile.generated; 
//
//  GEO2DLineStringGeometry.cpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 11/30/12.
//
//

//
//  GEO2DLineStringGeometry.hpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 11/30/12.
//
//




//class Geodetic2D;

public class GEO2DLineStringGeometry extends GEOLineStringGeometry
{
  private java.util.ArrayList<Geodetic2D> _coordinates;
  private Color _color;
  private final float _lineWidth;

  protected final Mesh createMesh(G3MRenderContext rc)
  {
  
    return create2DBoundaryMesh(_coordinates, _color, _lineWidth, rc);
  }


  public GEO2DLineStringGeometry(java.util.ArrayList<Geodetic2D> coordinates, Color color, float lineWidth)
  {
     _coordinates = coordinates;
     _color = color;
     _lineWidth = lineWidth;

  }


  public void dispose()
  {
    final int coordinatesCount = _coordinates.size();
    for (int i = 0; i < coordinatesCount; i++)
    {
      Geodetic2D coordinate = _coordinates.get(i);
      if (coordinate != null)
         coordinate.dispose();
    }
    _coordinates = null;
  }

}