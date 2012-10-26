// ********************************************************************************************
/** Sketchy is a port to AS3 of <a href="http://gicentre.org/handy/" target="_blank">Handy</a>,
 *  a processing library developped by Jo Wood, giCentre, City University London on an original
 *  idea by <a 	href="http://www.local-guru.net/blog/2010/4/23/simulation-of-hand-drawn-
 *	lines-in-processing" target="_blank">Nikolaus Gradwohl</a>
 *  @author Thomas Paillot, intactile DESIGN, based on Handy, a processing library by Jo wood.
 *  @version 1.0, 26th October, 2012
 */ 
// ********************************************************************************************

/* This file is part of Sketchy drawing library. Sketchy is free software: you can 
 * redistribute it and/or modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 * 
 * Sketchy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
 * See the GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License along with this
 * source code (see COPYING.LESSER included with this source code). If not, see 
 * http://www.gnu.org/licenses/.
 */

package com.intactile.sketchy {

	import flash.display.Sprite;
	import flash.display.Graphics;

	import uk.co.soulwire.math.Random;

	public class SketchySprite extends Sprite {

		private var _graphics:Graphics;				// Graphics context in which this class is to render.
		private var _cosAngle:Number;				// Lookups for quick calculations.
		private var _sinAngle:Number
		private var _tanAngle:Number;				
		private var _vertices:Vector.<Array>;		// Temporary store of shape or polyline _vertices.
		
		private var _fillWeight:Number;
		private var _fillColor:uint
		private var _fillAlpha:Number;
		
		private var _strokeWeight:Number;
		private var _strokeColor:uint;
		private var _strokeAlpha:Number;
						
		private var _secondaryColor:uint;			
		private var _useSecondary:Boolean;
		
		private var _isAlternating:Boolean;			// Determines whether hachuring alternates in direction in continuous stroke.
		private var _hachureAngle:Number;
		private var _anglePerturbation:Number;
		
		private var _fillGap:Number;			
		private var _roughness:Number;
		private var _bowing:Number;					// Scaling of the 'bowing' of lines at their midpoint.

		private var _numEllipseSteps:uint;
		private var _ellipseInc:Number;

		private const MIN_ROUGHNESS:Number = 0.1;	// Roughess less than this value will be consisidered 0.

		public function SketchySprite() {
			_graphics = this.graphics;

			_numEllipseSteps = 9;
			_ellipseInc = (Math.PI * 2) / _numEllipseSteps;
			_vertices = new Vector.<Array>();

			sketchyStyle();
			lineStyle();
			beginFill();
		}
		
		// ----------------------------------- Configuration methods -----------------------------------
		
		/** 
		 *  Set the sketchy styles to default or custom values.
		 */
		public function sketchyStyle(hachureAngle:Number = -45, hachurePerturbationAngle:Number = 0, fillGap:Number = 10, roughness:Number = 1, bowing:Number = 1):void
		{
			Random.seed = 12345;
			
			_useSecondary = false;
			_isAlternating = false;
			_anglePerturbation = hachurePerturbationAngle;
			_fillGap = fillGap;
			
			setHachureAngle(hachureAngle);
			setRoughness(roughness)
			setBowing(bowing);
		}
		
		/** 
		 *	Set the styles for the hachure stroke
		 */
		public function lineStyle(strokeWeight:Number = 0, strokeColor:uint = 0x000000, strokeAlpha:Number = 1):void
		{
			_strokeWeight = strokeWeight;
			_strokeColor = strokeColor;
			_strokeAlpha = strokeAlpha;
		}
		
		/** 
		 *	Set the styles for the hachure fill
		 */
		public function beginFill(fillWeight:Number = 0, fillColor:uint = 0x000000, fillAlpha:Number = 1):void
		{
			_fillWeight = fillWeight;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
		}
		
		/** 
		 *	Reset hachure fill weight
		 */
		public function endFill():void
		{
			_fillWeight = 0;
		}

		/** 
		 *	Set the angle for shading hachures.
		 *  @param degrees Angle of hachures in degrees where 0 is vertical, 45 is NE-SW and 90 is horizontal.
		 */
		public function setHachureAngle(degrees:Number):void
		{
			_hachureAngle = (degrees % 180) * (Math.PI / 180);
			_cosAngle = Math.cos(_hachureAngle);
			_sinAngle = Math.sin(_hachureAngle);
			_tanAngle = Math.tan(_hachureAngle);
		}

		/** 
		 *  Sets the general roughness of the sketch, values are capped at 10.
		 *  @param roughness The sketchiness of the rendering graphics
		 */
		public function setRoughness(roughness:Number):void
		{
			_roughness = Math.max(0, Math.min(roughness, 10));
		}

		/** 
		 *  Sets the amount of 'bowing' of lines, applies to all straight lines. Values are capped at 10.
		 *  @param bowing The degree of bowing in the rendering of straight lines
		 */
		public function setBowing(bowing:Number):void
		{
			_bowing = Math.max(0, Math.min(bowing, 10));
		}


		// -------------------------------------- Drawing methods --------------------------------------

		/** 
		 *  Draws an ellipse using the given location and dimensions
		 *  @param x x coordinate of the ellipse's position
		 *  @param y y coordinate of the ellipse's position.
		 *  @param w Width of the ellipse
		 *  @param h Height of the ellipse
		 */
		public function drawEllipse(x:Number, y:Number, w:Number, h:Number):void
		{	
			var cx:Number = x;
			var cy:Number = y;
			var rx:Number = Math.abs(w/2);
			var ry:Number = Math.abs(h/2);

			if ((rx < _roughness/4) || (ry < _roughness/4)) {
				return;
			}	

			// Add small proportionate perturbation to dimensions of ellipse
			rx += getOffset(-rx*0.05, rx*0.05);
			ry += getOffset(-ry*0.05, ry*0.05);
			
			var originalAngle:Number = (_hachureAngle * (180 / Math.PI));
			
			
			// Draw the hachure fill of the shape
			if(_fillWeight != 0) {
				_graphics.lineStyle(_fillWeight, _fillColor, _fillAlpha);
			
				// Perturb hachure angle if requested.
				if (_anglePerturbation > 0)
					setHachureAngle(originalAngle + (2*Random.next()-1)*_anglePerturbation);

				var gap:Number = (_fillGap < 0) ? _fillWeight * 4 : _fillGap;

				// If zig-zag filling, increase gap to give approximately similar density
				if (_isAlternating) gap *= 1.41;		
			
				var aspectRatio:Number = ry/rx;
				var hyp:Number = Math.sqrt(aspectRatio*_tanAngle*aspectRatio*_tanAngle+1);
				var sinAnglePrime:Number = aspectRatio*_tanAngle / hyp;
				var cosAnglePrime:Number = 1 / hyp;
				var gapPrime:Number = gap/((rx*ry/Math.sqrt((ry*cosAnglePrime)*(ry*cosAnglePrime) + (rx*sinAnglePrime)*(rx*sinAnglePrime)))/rx);
				var halfLen:Number = Math.sqrt((rx*rx) - (cx-rx+gapPrime)*(cx-rx+gapPrime));
				var prevP2:Array = affine(cx-rx+gapPrime,cy+halfLen,cx,cy,sinAnglePrime,cosAnglePrime,aspectRatio);

				for (var xPos:Number = cx-rx+gapPrime; xPos < cx+rx; xPos += gapPrime) {
					halfLen = Math.sqrt((rx*rx) - (cx-xPos)*(cx-xPos));
					var p1:Array = affine(xPos,cy-halfLen,cx,cy,sinAnglePrime,cosAnglePrime,aspectRatio);
					var p2:Array = affine(xPos,cy+halfLen,cx,cy,sinAnglePrime,cosAnglePrime,aspectRatio);
				
					if (_isAlternating)
						lineSketchy(prevP2[0], prevP2[1], p1[0], p1[1], 2);
				
					lineSketchy(p1[0], p1[1], p2[0], p2[1], 2);

					prevP2 = p2;
				}
			}
			

			// Perturb hachure angle if requested.
			if (_anglePerturbation > 0)
				setHachureAngle(originalAngle);
			
			// Draw the hachure stroke of the shape
			_graphics.lineStyle(_strokeWeight, _strokeColor, _strokeAlpha);
			buildEllipse(cx, cy, rx, ry, 1, _ellipseInc*getOffset(0.1, getOffset(0.4, 1.0)));
			buildEllipse(cx, cy, rx, ry, 1.5, 0);
		}
		
		
		/** 
		 *  Draws a rectangle using the given location and dimensions
		 *  @param x x coordinate of the rectangle position
		 *  @param y y coordinate of the rectangle position.
		 *  @param w Width of the rectangle
		 *  @param h Height of the rectangle
		 */
		public function drawRect(x:Number, y:Number, w:Number, h:Number):void
		{
			var left:Number   = Math.min(x,x+w);
			var top:Number    = Math.min(y,y+h);
			var right:Number  = Math.max(x,x+w);
			var bottom:Number = Math.max(y,y+h);

			var originalAngle:Number = (_hachureAngle * (180 / Math.PI));


			// Draw the hachure fill of the shape
			if(_fillWeight != 0) {
				_graphics.lineStyle(_fillWeight, _fillColor, _fillAlpha);

				if (_anglePerturbation > 0)
					setHachureAngle(originalAngle + (2*Random.next()-1)*_anglePerturbation);

				var gap:Number = (_fillGap < 0) ? _fillWeight * 4 : _fillGap;
			
				if (_isAlternating)
					gap *= 1.41;

				var i:HachureIterator = new HachureIterator(top, bottom, left, right, gap, _sinAngle, _cosAngle, _tanAngle);
				var prevCoords:Array = i.getNextLine();
				var coords:Array;

				if (prevCoords != null) {
					lineSketchy(prevCoords[0],prevCoords[1],prevCoords[2],prevCoords[3], 2)

					while ((coords = i.getNextLine()) != null) {
						if (_isAlternating)
							lineSketchy(prevCoords[2],prevCoords[3],coords[0],coords[1], 2)
					
						lineSketchy(coords[0],coords[1],coords[2],coords[3], 2)
					
						prevCoords = coords;
					}
				}
			}
			

			// Restore original hachure angle if requested
			if (_anglePerturbation > 0)
				setHachureAngle(originalAngle);

			// Draw the hachure stroke of the shape
			_graphics.lineStyle(_strokeWeight, _strokeColor, _strokeAlpha);
			lineSketchy(left, top, right, top, 2);
			lineSketchy(right, top, right, bottom, 2);
			lineSketchy(right, bottom, left, bottom, 2);
			lineSketchy(left, bottom, left, top, 2);
		}
		
		public function moveTo(x:Number, y:Number):void
		{
			_vertices.length = 0;			
			_vertices.push(new Array(x, y));
		}
		
		public function lineTo(x:Number, y:Number):void
		{
			_vertices.push(new Array(x, y));
			
			lineEnd();
		}


		// --------------------------------- Private methods --------------------------------- 

		/** 
		 *	Draws a 2D line between the given coordinate pairs
		 *  @param x1 x coordinate of the start of the line
		 *  @param y1 y coordinate of the start of the line
		 *  @param x2 x coordinate of the end of the line
		 *  @param y2 y coordinate of the end of the line
		 *  @param maxOffset Maximum random offset in pixel coordinates
		 */
		private function lineSketchy(x1:Number, y1:Number, x2:Number, y2:Number, maxOffset:Number):void
		{				
			// Ensure random perturbation is no more than 10% of line length.
			var lenSq:Number = (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2);
			var offset:Number = maxOffset;

			if (maxOffset*maxOffset*100 > lenSq)
			{
				offset = Math.sqrt(lenSq)/10;
			}

			var halfOffset:Number = offset/2;
			var divergePoint:Number = 0.2 + Random.next()*0.2;

			// This is the midpoint displacement value to give slightly bowed lines.
			var midDispX:Number = _bowing*maxOffset*(y2-y1)/200;
			var midDispY:Number = _bowing*maxOffset*(x1-x2)/200;

			midDispX = getOffset(-midDispX,midDispX);
			midDispY = getOffset(-midDispY,midDispY);

			_graphics.moveTo(x1 + getOffset(-offset,offset), y1 +getOffset(-offset,offset));
			_graphics.lineTo(x1 + getOffset(-offset,offset), y1 +getOffset(-offset,offset));
			_graphics.lineTo(midDispX+x1+(x2 -x1)*divergePoint + getOffset(-offset,offset), midDispY+y1 + (y2-y1)*divergePoint +getOffset(-offset,offset));
			_graphics.lineTo(midDispX+x1+2*(x2-x1)*divergePoint + getOffset(-offset,offset), midDispY+y1+ 2*(y2-y1)*divergePoint +getOffset(-offset,offset)); 
			_graphics.lineTo(+x2 + getOffset(-offset,offset), +y2 +getOffset(-offset,offset));
			_graphics.lineTo(x2 + getOffset(-offset,offset), y2 +getOffset(-offset,offset));

			_graphics.moveTo(x1 + getOffset(-halfOffset,halfOffset), y1 +getOffset(-halfOffset,halfOffset));
			_graphics.lineTo(x1 + getOffset(-halfOffset,halfOffset), y1 +getOffset(-halfOffset,halfOffset));
			_graphics.lineTo(midDispX+x1+(x2 -x1)*divergePoint + getOffset(-halfOffset,halfOffset), midDispY+y1 + (y2-y1)*divergePoint +getOffset(-halfOffset,halfOffset));
			_graphics.lineTo(midDispX+x1+2*(x2-x1)*divergePoint + getOffset(-halfOffset,halfOffset), midDispY+y1+ 2*(y2-y1)*divergePoint +getOffset(-halfOffset,halfOffset)); 
			_graphics.lineTo(x2 + getOffset(-halfOffset,halfOffset), y2 +getOffset(-halfOffset,halfOffset));
			_graphics.lineTo(x2 + getOffset(-halfOffset,halfOffset), y2 +getOffset(-halfOffset,halfOffset));
		}
		
		
		/** 
		 *	End of a line
		 */
		private function lineEnd():void
		{
			var xs:Array = new Array(_vertices.length);
			var ys:Array = new Array(_vertices.length);

			for (var i:uint = 0; i < _vertices.length; i++) {
				xs[i] = _vertices[i][0];
				ys[i] = _vertices[i][1];
			}
						
			shape(xs, ys);
		}


		/** 
		 *	Draw a shape from a set of points
		 *  @param xs x coordinates of shape points
		 *  @param ys y coordinates of shape points
		 */
		private function shape(xs:Array, ys:Array):void {
			var left   = xs[0];
			var right  = xs[0];
			var top    = ys[0];
			var bottom = ys[0];
			
			for (var i:uint = 1; i < xs.length; i++) {
				left   = Math.min(left, xs[i]);
				right  = Math.max(right, xs[i]);
				top    = Math.min(top, ys[i]);
				bottom = Math.max(bottom, ys[i]);
			}

			var originalAngle:Number = (_hachureAngle * (180 / Math.PI));
	
			// Draw the hachure fill of the shape
			if(_fillWeight != 0) {
				if (_anglePerturbation > 0)
					setHachureAngle(originalAngle + (2*Random.next()-1)*_anglePerturbation);

				_graphics.lineStyle(_fillWeight, _fillColor, _fillAlpha);

				var gap:Number = (_fillGap < 0) ? _fillWeight * 4 : _fillGap;
		
				// Iterate through each line that could intersect with the shape.
				var it:HachureIterator = new HachureIterator(top-1, bottom+1, left-1, right+1, gap, _sinAngle, _cosAngle, _tanAngle);
				var rectCoords:Array = null;

				while ((rectCoords = it.getNextLine()) != null) {
					var lines:Array = getIntersectingLines(rectCoords,xs,ys);

					for (var k:uint = 0; k < lines.length; k += 2) {
						if (k < lines.length - 1) {
							var p1:Array = lines[k];
							var p2:Array = lines[k+1];
							lineSketchy(p1[0], p1[1], p2[0], p2[1], 2);
						}
					}
				}	
			}

			// Restore hachure angle if requested.
			if (_anglePerturbation > 0)
				setHachureAngle(originalAngle);

			_graphics.lineStyle(_strokeWeight, _strokeColor, _strokeAlpha);
	
			for (var l:uint = 0; l < xs.length-1; l++) {
				lineSketchy(xs[l], ys[l], xs[l+1], ys[l+1], 2);
			}
		}
		
		
		/** 
		 *  Generates a random offset scaled around the given range.
		 *  @param minVal Approximate minimum value around which the offset is generated.
		 *  @param maxVal Approximate maximum value around which the offset is generated.
		 */
		private function getOffset(minVal:Number, maxVal:Number):Number
		{
			return _roughness*(Random.next()*(maxVal-minVal)+minVal);
		}


		/** 
		 *	Applies a combined affine transformation that translates (cx,cy) to origin, rotates it,
		 *  scales it according to the given aspect ratio and then translates back to (cx, cy)
		 *  @param x x coordinate of the point to transform.
		 *  @param y y coordinate of the point to transform.
		 *  @param cx x coordinate of the centre point to translate to origin.
		 *  @param cy y coordinate of the centre point to translate to origin.
		 *  @param sinAnglePrime sine of modified angle that accounts for scaling graphics.
		 *  @param cosAnglePrime cosine of modified angle that accoints for scaling graphics.
		 *  @param R aspect ratio of ellipse (y/x).
		 *  @return Transformed coordinate pair.
		 */
		private function affine(x:Number, y:Number, cx:Number, cy:Number, sinAnglePrime:Number, cosAnglePrime:Number, R:Number):Array
		{		
			var A:Number = -cx*cosAnglePrime-cy*sinAnglePrime+cx;
			var B:Number = R*(cx*sinAnglePrime - cy*cosAnglePrime)+cy;
			var C:Number = cosAnglePrime;
			var D:Number = sinAnglePrime;
			var E:Number = -R*sinAnglePrime;
			var F:Number = R*cosAnglePrime;
			
			return new Array((A+ C*x + D*y), (B + E*x + F*y));
		}
		
		
		/** 
		 *	Adds the curved vertices to build an ellipse
		 *  @param cx x coordinate of the centre of the ellipse
		 *  @param cy y coordinate of the centre of the ellipse
		 *  @param rx Radius in the x direction of the ellipse
		 *  @param ry Radius in the y direction of the ellipse
		 */
		private function buildEllipse(cx:Number, cy:Number, rx:Number, ry:Number, offset:Number, overlap:Number):void
		{
			var radialOffset:Number = getOffset(-0.5,0.5)-(Math.PI/2);

			// First control point should be penultimate point on ellipse.	
			_graphics.moveTo(getOffset(-offset,offset)+cx+0.9*rx*Math.cos(radialOffset-_ellipseInc), getOffset(-offset,offset)+cy+0.9*ry*Math.sin(radialOffset-_ellipseInc));

			for (var theta:Number = radialOffset; theta < (Math.PI*2)+radialOffset-0.01; theta += _ellipseInc) {
				_graphics.lineTo(getOffset(-offset,offset)+cx+rx*Math.cos(theta), getOffset(-offset,offset)+cy+ry*Math.sin(theta));
			}

			_graphics.lineTo(getOffset(-offset,offset)+cx+rx*Math.cos(radialOffset+(Math.PI*2)+overlap*0.5), getOffset(-offset,offset)+cy+ry*Math.sin(radialOffset+(Math.PI*2)+overlap*0.5));
			_graphics.lineTo(getOffset(-offset,offset)+cx+0.98*rx*Math.cos(radialOffset+overlap), getOffset(-offset,offset)+cy+0.98*ry*Math.sin(radialOffset+overlap));
			_graphics.lineTo(getOffset(-offset,offset)+cx+0.9*rx*Math.cos(radialOffset+overlap*0.5), getOffset(-offset,offset)+cy+0.9*ry*Math.sin(radialOffset+overlap*0.5));
		}
		
		
		/** 
		 *  Provides a list of the coordinates of interior lines that represent the intersections
		 *  of a given line with a given shape boundary
		 * @param lineCoords The endpoints of the line to intersect
		 * @param xCoords The x coordinates of the boundary of the shape to be intersected with the line
		 * @param yCoords The y coordinates of the boundary of the shape to be intersected with the line
		 * @return List of coordinates representing the intersecting lines
		 */
		private function getIntersectingLines(lineCoords:Array, xCoords:Array, yCoords:Array):Array
		{
			var intersections:Array = new Array();
			var s1:Segment = new Segment(lineCoords[0], lineCoords[1], lineCoords[2], lineCoords[3]);

			// Final all points of intersection between line and shape boundary and ensure they are ordered from the start of the line.
			for (var i:uint = 0; i < xCoords.length; i++) {
				var s2:Segment = new Segment(xCoords[i], yCoords[i], xCoords[(i+1)%xCoords.length], yCoords[(i+1)%xCoords.length]);

				if (s1.compare(s2) == s1.Relation.INTERSECTS)
				{
					intersections.push(new Array(s1.getIntersectionX(), s1.getIntersectionY()));
				}
			}

			return intersections;
		}
		
		
		// --------------------------------- Accessor methods --------------------------------- 
		
		public function get g():Graphics
		{
			return _graphics;
		}
	}
}