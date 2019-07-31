package common.iso.view.containers
{
	import common.iso.model.IsoModel;
	import common.iso.view.display.IsoTile;
	import common.test.flooring.Grass;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;


	public class Background
	{
		private static const TILE_WIDTH:int = 256;
		private static const TILE_HEIGHT:int = 128;
		private static const TILE_WIDTH_HALF:int = TILE_WIDTH * .5;
		private static const TILE_HEIGHT_HALF:int = TILE_HEIGHT * .5;
		private var _layer:StaticLayer;
		private var _bitmap:Bitmap;
		private var _destPoint:Point;
		private var _sourceRect:Rectangle;
		private var _fills:Array;

		public function Background(staticLayer:StaticLayer, gridWidth:uint, gridHeight:uint)
		{
			_layer = staticLayer;

			for (var i:int = 0; i < gridWidth; i += 4)
			{
				for (var j:int = 0; j < gridHeight; j += 4)
				{
					var tile:IsoTile = new IsoTile();
					tile.isoX = i;
					tile.isoY = j;

					var id:String = Grass.getRandom();

					var source:DisplayObject = IsoModel.gi.getFlooring(id);
					// tile.display();
					source.x = tile.x;
					source.y = tile.y;
					if (source) _layer.render(source);
				}
			}
		}
		/*private function createBackground():void
		{
		_layer.render(
		var bitmapData:BitmapData = new MapBackgroundFill();
			
		_bitmap = new Bitmap(bitmapData, PixelSnapping.AUTO, true);
		_bitmap.bitmapData.lock();
		_bitmap.bitmapData.floodFill(0, 0, 0x6F793B);
			
		_destPoint = new Point(0, 0);
		_sourceRect = new Rectangle(0, 0, TILE_WIDTH, TILE_HEIGHT);
		_fills = new Array();
			
		var fills:Array = Grass.ARRAY;
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
			
		var w:int = _bitmap.width;
		var h:int = _bitmap.height;
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
		}*/
	}
}