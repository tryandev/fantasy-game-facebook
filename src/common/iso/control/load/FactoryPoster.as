package common.iso.control.load
{
	import com.greensock.TweenNano;
	import com.raka.iso.utils.IDisposable;
	
	import common.iso.model.IsoPoster;
	import common.iso.view.containers.BitmapLarge;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.setTimeout;

	public class FactoryPoster implements IDisposable
	{
		
		private var _background:BitmapLarge;
		private var _posters:Array;
		private var _callback:Function;
		
		private var _countLoaded:int;
		private var _countTotal:int;
		private var _disposed:Boolean;
		
		public function FactoryPoster(inPosters:Array, inBG:BitmapLarge)
		{
			_posters = inPosters;
			_background = inBG;
			//trace('FactoryPoster constructor');
		}
		
		public function dispose():void 
		{
			_disposed = true;
			_posters = null;
			_background = null;
			_callback = null;
			//trace('FactoryPoster dispose');
		}
		
		public function load(inCallback:Function):void {
			_callback = inCallback;
			_countTotal = _posters.length;
			for (var i:int = 0; (_posters && i < _countTotal); i++)
			{
				var poster:IsoPoster = _posters[i];
				poster.load(onCompletePoster);
			}
			//trace('FactoryPoster load');
		}
		
		public function onCompletePoster():void {
			_countLoaded++;
			//trace('FactoryPoster onCompletePoster ' + _countLoaded + "/" + _countTotal);
			if (_countLoaded == _countTotal) {
				onCompleteAll();
				System.gc();
			}
		}
		
		public function onCompleteAll():void {
			if (_disposed) return;
			drawPosters();
			_callback && _callback();
			//trace('FactoryPoster onCompleteAll');
		}
		
		private function drawPosters():void {
			var poster:IsoPoster;
			var bmp:Bitmap;
			var bmd:BitmapData;
			while (_posters.length) {
				poster = _posters.shift();
				bmp = poster.getBitmap();
				
				if (!bmp) {
					continue;
				}
				
				bmd = bmp.bitmapData;					
				var rect:Rectangle = new Rectangle(0,0,bmp.width,bmp.height);
				var point:Point = new Point(0,0);
				/*bmd.applyFilter(
					bmd,
					rect, 
					point, 
					new ColorMatrixFilter(
						new Array(
							1.0, 	0.0, 	0.0, 	0.0, 	0.0,
							0.0, 	1.0, 	0.0, 	0.0, 	0.0,
							0.0, 	0.0, 	1.0, 	0.0, 	0.0,
							0.0, 	0.0, 	0.0, 	1.0, 	128
						)
					)
				); */
				var matrix:Matrix = new Matrix(
					poster.scale,0,0,poster.scale,
					poster.x,
					poster.y
				);
				_background.draw(bmd,matrix);
				//bmd.dispose();
			}
			//trace('FactoryPoster drawPosters');
		}
	}
}