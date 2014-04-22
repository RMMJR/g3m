

package org.glob3.mobile.tools;

import java.util.ArrayList;

import org.glob3.mobile.generated.Angle;
import org.glob3.mobile.generated.Geodetic2D;
import org.glob3.mobile.generated.MercatorUtils;
import org.glob3.mobile.generated.Sector;


public class TileSector
         extends
            Sector {

   public TileSector _parent;
   public int        _level;
   public int        _row;
   public int        _column;


   public TileSector(final Geodetic2D lower,
                     final Geodetic2D upper,
                     final TileSector parent,
                     final int level,
                     final int row,
                     final int column) {

      super(lower, upper);
      _parent = parent;
      _level = level;
      _row = row;
      _column = column;
   }


   public TileSector(final Sector sector,
                     final TileSector parent,
                     final int level,
                     final int row,
                     final int column) {

      super(sector);
      _parent = parent;
      _level = level;
      _row = row;
      _column = column;
   }


   public Sector getSector() {
      return this;
   }


   public Sector getExtendedSector(final double tolerance) {

      final Geodetic2D geodeticDelta = new Geodetic2D(this._deltaLatitude.times(tolerance), this._deltaLongitude.times(tolerance));
      final Geodetic2D extendedLower = this._lower.sub(geodeticDelta);
      final Geodetic2D extendedUpper = this._upper.add(geodeticDelta);

      return new Sector(extendedLower, extendedUpper);

      //      final TileSector result = new TileSector(extendedLower, extendedUpper, this._parent, this._level, this._row, this._column);
      //      System.out.println("SECTOR: " + this.toString());
      //      System.out.println("EXTENDED SECTOR: " + result.toString());
      //      return result;
   }


   public final ArrayList<TileSector> getSubTileSectors(final boolean mercator) {

      final Angle splitLongitude = Angle.midAngle(_lower._longitude, _upper._longitude);

      final Angle splitLatitude = mercator ? MercatorUtils.calculateSplitLatitude(_lower._latitude, _upper._latitude)
                                          : Angle.midAngle(_lower._latitude, _upper._latitude);

      return createSubTileSectors(splitLatitude, splitLongitude);
   }


   private final ArrayList<TileSector> createSubTileSectors(final Angle splitLatitude,
                                                            final Angle splitLongitude) {

      final int nextLevel = _level + 1;

      final int row2 = 2 * _row;
      final int column2 = 2 * _column;

      final ArrayList<TileSector> subSectors = new ArrayList<TileSector>();

      final TileSector s00 = createSubTileSector(_lower._latitude, _lower._longitude, splitLatitude, splitLongitude, nextLevel,
               row2, column2);
      subSectors.add(s00);

      final TileSector s01 = createSubTileSector(_lower._latitude, splitLongitude, splitLatitude, _upper._longitude, nextLevel,
               row2, column2 + 1);
      subSectors.add(s01);

      final TileSector s10 = createSubTileSector(splitLatitude, _lower._longitude, _upper._latitude, splitLongitude, nextLevel,
               row2 + 1, column2);
      subSectors.add(s10);

      final TileSector s11 = createSubTileSector(splitLatitude, splitLongitude, _upper._latitude, _upper._longitude, nextLevel,
               row2 + 1, column2 + 1);
      subSectors.add(s11);

      return subSectors;
   }


   private TileSector createSubTileSector(final Angle lowerLat,
                                          final Angle lowerLon,
                                          final Angle upperLat,
                                          final Angle upperLon,
                                          final int subLevel,
                                          final int row,
                                          final int column) {

      return new TileSector(new Geodetic2D(lowerLat, lowerLon), new Geodetic2D(upperLat, upperLon), this, subLevel, row, column);
   }


   //   public List<TileSector> getSubTileSectors() {
   //
   //      final List<TileSector> subSectors = new ArrayList<TileSector>(4);
   //      final int subLevel = this._level + 1;
   //
   //      int rowInc = this._row;
   //      int columnInc = this._column;
   //      final TileSector s00 = new TileSector(this._lower, this._center, this, subLevel, this._row + rowInc, this._column
   //                                                                                                           + columnInc);
   //
   //      rowInc = this._row;
   //      columnInc = this._column + 1;
   //      final TileSector s01 = new TileSector(new Geodetic2D(this._lower._latitude, this._center._longitude), new Geodetic2D(
   //               this._center._latitude, this._upper._longitude), this, subLevel, this._row + rowInc, this._column + columnInc);
   //
   //      rowInc = this._row + 1;
   //      columnInc = this._column;
   //      final TileSector s10 = new TileSector(new Geodetic2D(this._center._latitude, this._lower._longitude), new Geodetic2D(
   //               this._upper._latitude, this._center._longitude), this, subLevel, this._row + rowInc, this._column + columnInc);
   //
   //      rowInc = this._row + 1;
   //      columnInc = this._column + 1;
   //      final TileSector s11 = new TileSector(this._center, this._upper, this, subLevel, this._row + rowInc, this._column
   //                                                                                                           + columnInc);
   //
   //      subSectors.add(s00);
   //      subSectors.add(s01);
   //      subSectors.add(s10);
   //      subSectors.add(s11);
   //
   //      return subSectors;
   //   }

   //   public List<SectorVec> getSubsectors() {
   //
   //      final List<SectorVec> subSectors = new ArrayList<SectorVec>(4);
   //      final int subLevel = this._level + 1;
   //
   //      int rowInc = this._row - 1;
   //      int columnInc = this._column - 1;
   //      final SectorVec s11 = new SectorVec(this._lower, this._center, this, subLevel, this._row + rowInc, this._column + columnInc);
   //
   //      rowInc = this._row - 1;
   //      columnInc = this._column;
   //      final SectorVec s12 = new SectorVec(new Geodetic2D(this._lower._latitude, this._center._longitude), new Geodetic2D(
   //               this._center._latitude, this._upper._longitude), this, subLevel, this._row + rowInc, this._column + columnInc);
   //      rowInc = this._row;
   //      columnInc = this._column - 1;
   //      final SectorVec s21 = new SectorVec(new Geodetic2D(this._center._latitude, this._lower._longitude), new Geodetic2D(
   //               this._upper._latitude, this._center._longitude), this, subLevel, this._row + rowInc, this._column + columnInc);
   //      rowInc = this._row;
   //      columnInc = this._column;
   //      final SectorVec s22 = new SectorVec(this._center, this._upper, this, subLevel, this._row + rowInc, this._column + columnInc);
   //
   //      subSectors.add(s11);
   //      subSectors.add(s12);
   //      subSectors.add(s21);
   //      subSectors.add(s22);
   //
   //      return subSectors;
   //   }

   //   @Override
   //   public String toString() {
   //      return "SectorVec [_parent=" + _parent + ", _level=" + _level + ", _row=" + _row + ", _column=" + _column + ", _lower="
   //             + toStringGeodetic2D(_lower) + ", _upper=" + toStringGeodetic2D(_upper) + ", _center=" + toStringGeodetic2D(_center)
   //             + ", _deltaLatitude=" + toStringAngle(_deltaLatitude) + ", _deltaLongitude=" + toStringAngle(_deltaLongitude) + "]";
   //   }

   @Override
   public String toString() {
      return "SectorVec [_level=" + _level + ", _row=" + _row + ", _column=" + _column + ", _lower=" + toStringGeodetic2D(_lower)
             + ", _upper=" + toStringGeodetic2D(_upper) + ", _center=" + toStringGeodetic2D(_center) + ", _deltaLatitude="
             + toStringAngle(_deltaLatitude) + ", _deltaLongitude=" + toStringAngle(_deltaLongitude) + "]";
   }


   public String toStringGeodetic2D(final Geodetic2D g) {

      return "(" + g._latitude._degrees + ", " + g._longitude._degrees + ")";
   }


   public String toStringAngle(final Angle a) {

      return "(" + a._degrees + ")";
   }

}
