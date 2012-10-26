// *****************************************************************************************
/** Set of static classes for loadig preset sketchy styles, such as pencil sketch, ink and
 *  watercolour, 'Sharpie' style etc.
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
	
	public class SketchyPresets {
		
		public function SketchyPresets() {
			
		}
		
		/** 
		 *	Load a preset that draws in a pencil sketch style
		 *  @param s SketchySprite that will use this preset
		 */
		public static function loadPencil(s:SketchySprite):void
		{
			var sketchy:SketchySprite = s;
			
			sketchy.sketchyStyle(-45, 5, 0.8, 1, 1);
			sketchy.lineStyle(1, 0x777777, 0.7);
			sketchy.beginFill(1, 0x777777, 0.9);
		}

		/** 
		 *	Load a preset that draws in a coloured pencil sketch style
		 *  @param s SketchySprite that will use this preset
		 */
		public static function loadColouredPencil(s:SketchySprite):void
		{
			var sketchy:SketchySprite = s;
			
			sketchy.sketchyStyle(-45, 5, 1, 1, 1);
			sketchy.lineStyle(1, 0xFFFFFF, 0);
			sketchy.beginFill(1.5, 0x777777, 0.9);
		}

		/** 
		 *	Load a preset that draws in a watercolour and ink style
		 *  @param s SketchySprite that will use this preset
		 */
		public static function loadWaterAndInk(s:SketchySprite):void
		{
			var sketchy:SketchySprite = s;
			
			sketchy.sketchyStyle(-45, 0, 1, 3, 1);
			sketchy.lineStyle(1, 0x000000);
			sketchy.beginFill(1);
		}

		/** 
		 *	Load a preset that draws in a felt-tip marker ('Sharpie') style
		 *  @param s SketchySprite that will use this preset
		 */
		public static function loadMarker(s:SketchySprite):void
		{
			var sketchy:SketchySprite = s;
			
			sketchy.sketchyStyle(-45, 5, 7, 1.5, 1);
			sketchy.lineStyle(3, 0x000000, 0.6);
			sketchy.beginFill(5);
		}
	}
}