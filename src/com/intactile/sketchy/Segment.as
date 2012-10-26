// ******************************************************************************************
/** Stores a directional 2d straight line segment. Can be used for geometric queries such as
 *  line intersection.
 *  @author Thomas Paillot, intactile DESIGN, based on Handy, a processing library by Jo wood.
 *  @version 1.0, 26th October, 2012.
 */
//*******************************************************************************************

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
	
	import flash.geom.Point;
	
	public class Segment {
		
		public var Relation:Object = {LEFT: "LEFT", RIGHT: "RIGHT", INTERSECTS: "INTERSECTS", AHEAD: "AHEAD", BEHIND: "BEHIND", SEPARATE: "SEPARATE", UNDEFINED: "UNDEFINED"};

		private var px1:Number;			// Start and end point of the segment.
		private var py1:Number;      
		private var px2:Number;
		private var py2:Number;  

		private var a:Number;			// Cartesian line equation parameters aX+bY+c=0
		private var b:Number;
		private var c:Number;

		private var undefined:Boolean;  // True if segment undefined.
		private var xi:Number;			// Point of intersection.
		private var yi:Number;
		
		
		/** Creates a line segment from the two given end points.
		 *  @param px1 x-coordinate of first point on segment.
		 *  @param py1 y-coordinate of first point on segment.
		 *  @param px2 x-coordinate of second point on segment.
		 *  @param py2 y-coordinate of second point on segment.
		 */
		public function Segment(px1:Number, py1:Number, px2:Number, py2:Number)
		{ 
			this.px1 = px1;
			this.py1 = py1;
			this.px2 = px2;
			this.py2 = py2;

			xi = Number.MAX_VALUE;
			yi = Number.MAX_VALUE;

			// Calculate Cartesian equation of the line.
			a = py2-py1;
			b = px1-px2;
			c = px2*py1-px1*py2;

			// Check p1 and p2 are two separate points.
			if ((a == 0) && (b == 0) && (c == 0))
			{
				undefined = true;
			}
			else
			{
				undefined = false;
			}
		}
		
		/** Determines if and where the given segment intersects with this one.
		 *  @param otherSegment Segment which which to compare.
		 *  @return Either INTERSECTS if the two segments cross, SEPARATE if 
		 *          they do not or UNDEFINED if either segment is undefined.
		 */
		public function compare(otherSegment:Segment):String
		{   
			if ((isUndefined()) || (otherSegment.isUndefined())) 
			{
				return Relation.UNDEFINED;  
			}

			var grad1:Number = Number.MAX_VALUE;        // The two gradients.
			var grad2:Number = Number.MAX_VALUE;    
			var int1:Number = 0;                        // The two intercepts.
			var int2:Number = 0;        

			// Find gradient and intercept of first line.
			if (Math.abs(b) > 0.00001)
			{
				grad1 = -a/b;
				int1  = -c/b;
			}

			// Find gradient and intercept of second line.
			if (Math.abs(otherSegment.getB()) > 0.00001)
			{
				grad2 = -otherSegment.getA()/otherSegment.getB();
				int2  = -otherSegment.getC()/otherSegment.getB();
			}

			// Solve simultaneous equations.

			if (grad1 == Number.MAX_VALUE)  // Line 1 vertical.
			{
				if (grad2 == Number.MAX_VALUE)  // 2 parallel vertical lines.
				{
					// Segments two distinct parallel lines.
					if (-c/a != -otherSegment.getC()/otherSegment.getA())
					{
						return Relation.SEPARATE;
					}

					// Segments overlap along same vertical line.           
					if ((py1 >= Math.min(otherSegment.getPy1(),otherSegment.getPy2())) &&
							(py1 <= Math.max(otherSegment.getPy1(),otherSegment.getPy2())))
					{
						xi = px1;
						yi = py1;
						return Relation.INTERSECTS;
					}

					if ((py2 >= Math.min(otherSegment.getPy1(),otherSegment.getPy2())) &&
							(py2 <= Math.max(otherSegment.getPy1(),otherSegment.getPy2())))
					{
						xi = px2;
						yi = py2;
						return Relation.INTERSECTS;
					}

					// Separate segments on same vertical parallel line.
					return Relation.SEPARATE;
				}

				// Line 1 vertical, line 2 not parallel to it.
				xi = px1;       // was -c/a;
				yi = grad2*xi+int2;

				if (((py1-yi)*(yi-py2) < -0.00001) || ((otherSegment.getPy1()-yi)*(yi-otherSegment.getPy2()) < -0.00001))
				{
					return Relation.SEPARATE;
				}
				// Line 2 is horizontal, line 1 is vertical.
				if (Math.abs(otherSegment.getA()) < 0.00001)
				{
					if ((otherSegment.getPx1()-xi)*(xi-otherSegment.getPx2()) < -0.00001)
					{
						return Relation.SEPARATE;
					}
					return Relation.INTERSECTS;
				}
				return Relation.INTERSECTS;
			}

			// Line 2 vertical, line 1 not-parallel to it.
			if (grad2 == Number.MAX_VALUE)  
			{
				xi = otherSegment.getPx1(); //(float)(-otherSegment.getC()/otherSegment.getA());
				yi = grad1*xi+int1;

				if (((otherSegment.getPy1()-yi)*(yi-otherSegment.getPy2()) < -0.00001) || ((py1-yi)*(yi-py2) < -000001))
				{
					return Relation.SEPARATE;
				}
				
				// Line 1 is horizontal, line 2 is vertical.
				if (Math.abs(a) < 0.00001)
				{
					if ((px1-xi)*(xi-px2) < -0.00001)
					{
						return Relation.SEPARATE;
					}
					return Relation.INTERSECTS;
				}
				return Relation.INTERSECTS;
			}

			// Two lines are parallel but not vertical.
			if (grad1 == grad2)
			{
				// Two lines are parallel and separate.
				if (int1 != int2)
				{
					return Relation.SEPARATE;
				}

				// Segments overlap along same non-vertical line.           
				if ((px1 >= Math.min(otherSegment.getPx1(),otherSegment.getPx2())) &&
					(px1 <= Math.max(otherSegment.getPy1(),otherSegment.getPy2())))
				{
					xi = px1;
					yi = py1;
					return Relation.INTERSECTS;
				}

				if ((px2 >= Math.min(otherSegment.getPx1(),otherSegment.getPx2())) &&
					(px2 <= Math.max(otherSegment.getPx1(),otherSegment.getPx2())))
				{
					xi = px2;
					yi = py2;
					return Relation.INTERSECTS;
				}

				// Separate segments on same non-vertical parallel line.
				return Relation.SEPARATE;  
			}

			// If we get this far, all special cases have been dealt with.
			xi = (int2-int1)/(grad1-grad2);
			yi = grad1*xi + int1;

			if (((px1-xi)*(xi-px2) < -0.00001) || ((otherSegment.getPx1()-xi)*(xi-otherSegment.getPx2()) < -0.00001))
			{
				return Relation.SEPARATE;
			}
			return Relation.INTERSECTS;    
		}
		
		/** Determines where the given point is in relation to the segment.
		 *  @param px x-coordinate of point to compare.
		 *  @param py y-coordinate of point to compare.
		 *  @return Relative position of point (LEFT, RIGHT, AHEAD, BEHIND, INTERSECTS or UNDEFINED).
		 */
		public function compare2(px:Number, py:Number):String
		{
			if (undefined)
			{
				return Relation.UNDEFINED;
			}

			// Test whether point falls on extended line.
			var s:Number = a*px + b*py + c;

			if (s > 0.01)
			{
				return Relation.RIGHT;
			}

			if (s < -0.01)
			{
				return Relation.LEFT;
			}

			// Find out where on line point falls.
			var d:Number;

			if (px2 == px1)
			{
				d = (py-py1)/(py2-py1);
			}
			else 
			{
				d = (px-px1)/(px2-px1);
			}

			if (d < -0.001)
			{
				return Relation.BEHIND;
			}

			if (d > 1.001)
			{
				return Relation.AHEAD;
			}

			return Relation.INTERSECTS;
		}     

		/** Reports the distance between the given point and this segment.
		 *  @param px x coordinate of point to consider.
		 *  @param py y coordinate of point to consider.
		 *  @return distance between point and segment.
		 */
		private function calcDistance(px:Number, py:Number):Number
		{
			// Check for segment of zero length.
			if ((px1==px2) && (py1==py2))
			{
				return Math.sqrt((px-px1)*(px-px1) + (py-py1)*(py-py1));
			}


			var dx:Number = px1-px2;
			var dy:Number = py1-py2;
			var dist2:Number = dx*dx + dy*dy;

			var u:Number = ((px-px1)*(px2-px1) + (py-py1)*(py2-py1)) / dist2;


			if (u < 0)  // Nearest point is 'behind' line segment.
			{
				return getLength2(px,py,px1,py1);
			}

			if (u > 1)  // Nearest point is 'in front' of line segment.
			{
				return getLength2(px,py,px2,py2);
			}

			// Nearest point lies in line segment.
			return Math.abs((((py2-py1)*(px-px1) - (px2-px1)*(py-py1)) / Math.sqrt(dist2)));
		}
		
		/** Reports the nearest point on the segment to the given point. If shortest distance
		 *  between point and line of infinite length through the segment is outside the segment's
		 *  bounds, the nearest segment endpoint is returned.
		 *  @param px x coordinate of point to consider.
		 *  @param py y coordinate of point to consider.
		 *  @return Location of nearest point on segment.
		 */
		private function nearestPoint(px:Number, py:Number):Point
		{
			// Check for segment of zero length.
			if ((px1==px2) && (py1==py2))
			{
				return new Point(px1,py1);
			}

			var dx:Number = px1-px2;
			var dy:Number = py1-py2;
			var dist2:Number = dx*dx + dy*dy;

			var u:Number = ((px-px1)*(px2-px1) + (py-py1)*(py2-py1)) / dist2;


			if (u < 0)  // Nearest point is 'behind' line segment.
			{
				return new Point(px1,py1);
			}

			if (u > 1)  // Nearest point is 'in front' of line segment.
			{
				return new Point(px2,py2);
			}

			// Nearest point lies in line segment.
			return new Point((px1 +u*(px2-px1)), (py1 + u*(py2-py1)));
		}

		/** Reports whether intersection is with one of the segment's endpoints.
		 *  @return true if intersection is with one of the endpoints.
		 */
		private function intersectsEndpoint():Boolean
		{
			if ((xi == Number.MAX_VALUE) || (yi == Number.MAX_VALUE))
				return false;

			var diff1:Number = Math.abs(px1-xi)+ Math.abs(py1-yi);
			var diff2:Number = Math.abs(px2-xi)+ Math.abs(py2-yi);

			if ((diff1 <0.1) || (diff2 <0.1))
			{
				return true;
			}
			return false;
		}
		
		
		// ----------------------- Accessor Methods ------------------------

		/** Reports the x coordinate of the start point of the segment.
		 *  @return x coordinate of the start point.
		 */
		public function getPx1():Number
		{
			return px1;
		}

		/** Reports the y coordinate of the start point of the segment.
		 *  @return y coordinate of the start point.
		 */
		public function getPy1():Number
		{
			return py1;
		} 

		/** Reports the x coordinate of the end point of the segment.
		 *  @return x coordinate of the end point.
		 */
		public function getPx2():Number
		{
			return px2;
		}

		/** Reports the y coordinate of the end point of the segment.
		 *  @return y coordinate of the end point.
		 */
		public function getPy2():Number
		{
			return py2;
		} 

		/** Reports whether segment is undefined (endpoints identical).
		 *  @return True if undefined line.
		 */
		public function isUndefined():Boolean
		{
			return undefined;
		}

		/** Reports the 'a' coefficient of the Cartesian equation of the segment.
		 *  Cartesian equation is in the form aX + bY + c = 0.
		 *  @return a coefficient.
		 */
		public function getA():Number
		{
			return a;
		}

		/** Reports the 'b' coefficient of the Cartesian equation of the segment.
		 *  Cartesian equation is in the form aX + bY + c = 0.
		 *  @return b coefficient.
		 */
		public function getB():Number
		{
			return b;
		}

		/** Reports the 'c' coefficient of the Cartesian equation of the segment.
		 *  Cartesian equation is in the form aX + bY + c = 0.
		 *  @return c coefficient.
		 */
		public function getC():Number
		{
			return c;
		}

		/** Reports the x coordinate of the intersection with last segment to be compared.
		 *  @return x coordinate of the intersection.
		 */
		public function getIntersectionX():Number
		{
			return xi;
		}

		/** Reports the y coordinate of the intersection with last segment to be compared.
		 *  @return y coordinate of the intersection.
		 */
		public function getIntersectionY():Number
		{
			return yi;
		}

		/** Reports the length of the segment.
		 *  @return Length of the segment.
		 */
		public function getLength():Number
		{ 
			return getLength2(px1,py1,px2,py2);
		}

		/** Reports the coordinates of this segment.
		 *  @return Textual representation of this segment.
		 */
		public function toString():String
		{       
			return new String("Segment with vertices ("+px1+","+py1+") ("+px2+","+py2+")");
		}

		// ---------------------- Private methods ---------------------

		/** Calculates the length of the line given by the two end point coordinates.
		 */
		private function getLength2(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			var dx:Number = x2-x1;
			var dy:Number = y2-y1;

			return Math.sqrt(dx*dx + dy*dy);
		}
	}
}