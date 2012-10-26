//*****************************************************************************************
/** Provides a set of line coordinates that progress across a rectangular area at a given
 *  angle.
 *  @author Thomas Paillot, intactile DESIGN, based on Handy, a processing library by Jo wood.
 *  @version 1.0, 26th October, 2012
 */ 
// *****************************************************************************************

/* This file is part of Sketchy library. Sketchy is free software: you can 
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
	
	public class HachureIterator {
		
		private var sinAngle:Number;
		private var tanAngle:Number;
		private var top:Number;
		private var bottom:Number;
		private var left:Number;
		private var right:Number;
		private var gap:Number;
		private var pos:Number;
		private var deltaX:Number;
		private var hGap:Number;
		private var sLeft:Segment;
		private var sRight:Segment;
		
		public function HachureIterator(top:Number, bottom:Number, left:Number, right:Number, gap:Number, sinAngle:Number, cosAngle:Number, tanAngle:Number)
		{
			this.top      = top;
			this.bottom   = bottom;
			this.left     = left;
			this.right    = right;
			this.gap      = gap;
			this.sinAngle = sinAngle;
			this.tanAngle = tanAngle;

			if (Math.abs(sinAngle) < 0.0001)
			{
				// Special case 1: Vertical lines
				pos = left+gap;
			}
			else if (Math.abs(sinAngle) > 0.9999)
			{
				// Special case 2: Horizontal lines
				pos = top+gap;
			}
			else
			{
				deltaX = (bottom-top)*Math.abs(tanAngle);
				pos = left-Math.abs(deltaX);
				hGap   = Math.abs(gap /cosAngle);
				sLeft = new Segment(left,bottom,left,top);
				sRight = new Segment(right,bottom,right,top);
			}		
		}
		
		/** Reports the next line that fits within the rectangle.
		 *  @return Coordinates of the line (x1,y1,x2,y2) or null if no more lines to find.
		 */
		public function getNextLine():Array
		{
			var line:Array;
			
			if (Math.abs(sinAngle) < 0.0001)
			{
				// Special case 1: Vertical hachuring
				if (pos < right)
				{
					line = new Array(pos, top, pos, bottom);
					pos += gap;
					return line;
				}
			}
			else if (Math.abs(sinAngle) > 0.9999)
			{
				// Special case 2: Horizontal hachuring
				if (pos<bottom)
				{

					line = new Array(left, pos, right, pos);
					pos += gap;
					return line;
				}
			}
			else
			{
				var xLower:Number = pos-deltaX/2;
				var xUpper:Number = pos+deltaX/2;
				var yLower:Number = bottom;
				var yUpper:Number = top;

				if (pos < right+deltaX)
				{
					while (((xLower < left) && (xUpper < left)) ||
							((xLower > right) && (xUpper > right)))
					{
						pos += hGap;
						xLower = pos-deltaX/2;
						xUpper = pos+deltaX/2;

						if (pos > right+deltaX)
						{
							return null;
						}
					}

					var s:Segment = new Segment(xLower,yLower,xUpper,yUpper);

					if (s.compare(sLeft) == s.Relation.INTERSECTS)
					{
						xLower = s.getIntersectionX();
						yLower = s.getIntersectionY();
					}
					if (s.compare(sRight) == s.Relation.INTERSECTS)
					{
						xUpper = s.getIntersectionX();
						yUpper = s.getIntersectionY();
					}
					if (tanAngle > 0)
					{
						xLower = right-(xLower-left);
						xUpper = right-(xUpper-left);
					}
					
					line = new Array(xLower,yLower,xUpper,yUpper);
					pos += hGap;
					return line;
				}
			}

			// If we get to this point, we must have finished all hachures
			return null;
		}
	}
}