package common.iso.control
{
	import common.iso.model.IsoModel;
	import common.test.flooring.Grass;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class IsoControllerBackground
	{
		private static const TILE_WIDTH:int = 256;
		private static const TILE_HEIGHT:int = 128;
		private static const TILE_WIDTH_HALF:int = TILE_WIDTH * .5;
		private static const TILE_HEIGHT_HALF:int = TILE_HEIGHT * .5;
		private static var _instance:IsoControllerBackground;
		private var _bitmap:Bitmap;
		private var _destPoint:Point;
		private var _sourceRect:Rectangle;
		private var _fills:Array;

		public function IsoControllerBackground(se:SE)
		{
			se;

			createBackground();
		}

		private function createBackground():void
		{
			var w:int = 4096;
			var h:int = 3200;
			
			var bitmapData:BitmapData = new BitmapData(w,h,false,0x6F793B);
//			var bitmapData:BitmapData = new MapBackgroundFill();
			
			_bitmap = new Bitmap(bitmapData, PixelSnapping.AUTO, true);
			_bitmap.bitmapData.lock();
			_bitmap.bitmapData.floodFill(0, 0, 0x6F793B);
			
//			w = _bitmap.width;
//			h = _bitmap.height;

			_destPoint = new Point(0, 0);
			_sourceRect = new Rectangle(0, 0, TILE_WIDTH, TILE_HEIGHT);
			_fills = new Array();

			var fills:Array = Grass.ARRAY
			// Grass.getArray();
			var id:String;
			var source:DisplayObject;
			var sourceBitmapData:BitmapData;

			for each (id in fills)
			{
				source = IsoModel.gi.getFlooring(id);
				sourceBitmapData = new BitmapData(TILE_WIDTH, TILE_HEIGHT, true, 0x000000);
				sourceBitmapData.lock();
				sourceBitmapData.draw(source);
				sourceBitmapData.unlock();

				_fills.push(sourceBitmapData);
			}

			var x:int;
			var y:int;

			x = 0;

			for (x;x < w;x += TILE_WIDTH)
			{
				y = 0;

				for (y;y < h;y += TILE_HEIGHT)
				{
					_destPoint.x = x;
					_destPoint.y = y;
					_bitmap.bitmapData.copyPixels(getRandomFill(), _sourceRect, _destPoint);
				}
			}

			x = -TILE_WIDTH_HALF;

			for (x;x < w;x += TILE_WIDTH)
			{
				y = -TILE_HEIGHT_HALF;

				for (y;y < h;y += TILE_HEIGHT)
				{
					_destPoint.x = x;
					_destPoint.y = y;
					_bitmap.bitmapData.copyPixels(getRandomFill(), _sourceRect, _destPoint);
				}
			}

			_bitmap.bitmapData.unlock();
		}

		private function getRandomFill():BitmapData
		{
			var i:int = Math.random() * (_fills.length - 1);
			return _fills[i];
		}

		public function get background():Bitmap
		{
			return _bitmap;
		}

		public static function get gi():IsoControllerBackground
		{
			return _instance || (_instance = new IsoControllerBackground(new SE()));
		}
	}
}
internal class SE
{
}