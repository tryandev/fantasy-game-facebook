package common.iso.model
{
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class IsoMapViewport
	{
		/**
		 *  The tile coordinates of the top left point on the screen 
		 */
		public var topLeft:Point;
		
		/**
		 *  The tile coordinates of the bottom right point on the screen 
		 */
		public var bottomRight:Point;
		
		public var leftPadding:int;
		public var rightPadding:int;
		public var topPadding:int;
		public var bottomPadding:int;
		
		public function IsoMapViewport()
		{
			topLeft = new Point();
			bottomRight = new Point();
		}
		
		public function calculatePixelViewport(pixelXOffset:int = 0, pixelYOffset:int = 0):Rectangle
		{
			var rect:Rectangle = new Rectangle();
			var tileSize:int = IsoBase.GRID_PIXEL_SIZE;
			
			var px:int = (topLeft.x - topLeft.y) * tileSize;
			var py:int = (topLeft.x + topLeft.y) * tileSize / 2;
			
			rect.x = pixelXOffset + px - leftPadding;
			rect.y = pixelYOffset + py - topPadding;
			
			rect.width = (bottomRight.x - bottomRight.y) * tileSize - px + leftPadding + rightPadding;
			rect.height = (bottomRight.x + bottomRight.y) * tileSize / 2 - py + topPadding + bottomPadding;
			
			return rect;
		}
		
		public function set padding(value:int):void
		{
			leftPadding = value;
			rightPadding = value;
			topPadding = value;
			bottomPadding = value;
		}
		
		public function set horizontalPadding(value:int):void
		{
			leftPadding = value;
			rightPadding = value;
		}
		
		public function set verticalPadding(value:int):void
		{
			topPadding = value;
			bottomPadding = value;
		}
	}
}