package common.iso.view.containers
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;

	public class BitmapLarge extends Sprite
	{
		private const SIZE_LIMIT:int = 4096;
		
		private var _transparent:Boolean;
		private var _fillColor:uint;
		
		private var _width:Number;
		private var _height:Number;
		
		private var _countBitmapsWidth:int;
		private var _countBitmapsHeight:int;
		private var _remainderWidth:int;
		private var _remainderHeight:int;
		private var _bitmaps:Array;
		
		public function BitmapLarge(inWidth:Number, inHeight:Number, transparent:Boolean = true, fillColor:uint = 0x00000000)
		{
			_width  = inWidth;
			_height = inHeight;
			_transparent = transparent;
			_fillColor = fillColor;
			
			_countBitmapsWidth  = Math.ceil(_width  / SIZE_LIMIT);
			_countBitmapsHeight = Math.ceil(_height / SIZE_LIMIT);
			
			_remainderWidth  = _width  % SIZE_LIMIT;
			_remainderHeight = _height % SIZE_LIMIT;
		}
		
		public function init():void
		{
			dispose();
			
			_bitmaps = [];
			
			for (var i:int = 0; i < _countBitmapsWidth; i++) {
				
				_bitmaps[i] = [];
				
				for (var j:int = 0; j < _countBitmapsHeight; j++) {
					
					var bmdWidth:int;
					var bmdHeight:int;					
					bmdWidth  = (i == _countBitmapsWidth  - 1) ? _remainderWidth  : SIZE_LIMIT; 
					bmdHeight = (j == _countBitmapsHeight - 1) ? _remainderHeight : SIZE_LIMIT; 
					
					var bmd:BitmapData = new BitmapData(bmdWidth, bmdHeight, _transparent, _fillColor);
					var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.NEVER);
					bmp.x = i * SIZE_LIMIT;
					bmp.y = j * SIZE_LIMIT;
					
					_bitmaps[i][j] = bmp;
					
					addChild(bmp);
					
				}
			}
		}
		
		public function dispose():void {
			while (_bitmaps && _bitmaps.length) {
				var arr:Array = _bitmaps.pop();
				while(arr.length){
					var bmp:Bitmap = arr.pop();
					bmp.bitmapData.dispose();
					removeChild(bmp);
				}
			}
			_bitmaps = null;
			System.gc();
		}
		
		public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:String = null):void {
			
			if (!matrix) {
				matrix = new Matrix();
			}
			
			if (matrix.tx >= _width || matrix.ty >= _height) return;
			
			var dummyWidth:int;
			var dummyHeight:int;
			
			if (source is BitmapData) {
				dummyWidth = BitmapData(source).width;
				dummyHeight = BitmapData(source).height;
			}
			
			if (source is DisplayObject) {
				dummyWidth = DisplayObject(source).width;
				dummyHeight = DisplayObject(source).height;
			}
			
			var minIndexX:int = Math.floor(matrix.tx / SIZE_LIMIT);
			var minIndexY:int = Math.floor(matrix.ty / SIZE_LIMIT);
			var maxIndexX:int = Math.floor((matrix.tx + dummyWidth  * matrix.a) / SIZE_LIMIT);
			var maxIndexY:int = Math.floor((matrix.ty + dummyHeight * matrix.d) / SIZE_LIMIT);
			
			minIndexX = (minIndexX < 0) ? 0 : minIndexX;
			minIndexY = (minIndexY < 0) ? 0 : minIndexY;
			
			maxIndexX = (maxIndexX > _countBitmapsWidth  - 1) ? _countBitmapsWidth  - 1: maxIndexX;
			maxIndexY = (maxIndexY > _countBitmapsHeight - 1) ? _countBitmapsHeight - 1: maxIndexY;
			
			var bmp:Bitmap;
			var bmd:BitmapData;
			var matrixRelative:Matrix;
			
			for (var i:int = minIndexX; i <= maxIndexX; i++) {
				for (var j:int = minIndexY; j <= maxIndexY; j++) {
					bmp = _bitmaps[i][j];
					bmd = bmp.bitmapData;
					matrixRelative = new Matrix(
						matrix.a,
						0,
						0,
						matrix.d,
						matrix.tx - bmp.x,
						matrix.ty - bmp.y
					);
					bmd.lock();
					bmd.draw(
						source, 
						matrixRelative, 
						colorTransform, 
						blendMode
					);
					bmd.unlock();
				}
			}
		}
		
		public override function get width():Number {
			return _width;
		}
		
		public override function get height():Number {
			return _height;
		}
		
		public function applyFilter(filter:BitmapFilter):void {
			for (var i:int = 0; i < _countBitmapsWidth; i++) {
				for (var j:int = 0; j < _countBitmapsHeight; j++) {
					var bmp:Bitmap = _bitmaps[i][j];
					var bmd:BitmapData = bmp.bitmapData;					
					bmd.applyFilter(
						bmd, 
						new Rectangle(0,0,bmd.width,bmd.height), 
						new Point(0,0), 
						filter
					);
				}
			}
		}
	}
}