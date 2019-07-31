package common.iso.control.load
{
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.iso.utils.IDisposable;
	
	import common.iso.model.IsoTree;
	import common.iso.view.containers.BitmapLarge;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class FactoryTree implements IDisposable
	{
		private var _background:BitmapLarge;
		private var _trees:Array;
		private var _callback:Function;
		
		private var _countLoaded:int;
		private var _countTotal:int;
		private var _disposed:Boolean;
		
		public function FactoryTree(inTrees:Array, inBG:BitmapLarge) {
			_trees = inTrees;
			_background = inBG;
		}
		
		public function dispose():void {
			_disposed = true;
			_trees = null;
			_background = null;
			
		}
		
		public function load(inCallback:Function):void {
			_callback = inCallback;
			_countTotal = _trees.length;
			for (var i:int = 0; (_trees && i < _countTotal); i++)
			{
				var tree:IsoTree = _trees[i];
				tree.load(onCompleteTree);
			}
			
		}
		
		public function onCompleteTree():void {
			_countLoaded++;
			//trace('FactoryTree onCompleteTree ' + _countLoaded + "/" + _countTotal);
			if (_countLoaded == _countTotal) {
				onCompleteAll();
			}
		}
		
		public function onCompleteAll():void {
			if (_disposed) return;
			drawTrees();
			_callback && _callback();
			//trace('FactoryTree onCompleteAll');
		}
		
		private function drawTrees():void {
			//trace('FactoryTree drawTrees');
			var tree:IsoTree;
			var bmp:Bitmap;
			var bmd:BitmapData;
			while (_trees.length) {
				tree = _trees.shift();
				bmp = tree.getBitmap();
				
				if (!bmp) {
					//trace('\t no bmp[' + _trees.length + ']');
					continue;
				}
				
				if (tree && tree.getBitmap() && ExpansionController.instance.doesDispObjRectIntersectExpandedArea(tree, _background.x, _background.y)) {
					continue;
				}

				bmd = bmp.bitmapData;				
				var rect:Rectangle = new Rectangle(0,0,bmp.width,bmp.height);
				var point:Point = new Point(0,0);
				
				//bmd.applyFilter(
				//	bmd,
				//	rect, 
				//	point, 
				//	new ColorMatrixFilter(
				//		new Array(
				//			1.0, 	0.0, 	0.0, 	0.0, 	0.0,
				//			0.0, 	1.0, 	0.0, 	0.0, 	0.0,
				//			0.0, 	0.0, 	1.0, 	0.0, 	0.0,
				//			0.0, 	0.0, 	0.0, 	1.0, 	128
				//		)
				//	)
				//);
				
				var matrix:Matrix = new Matrix(
					tree.scale,0,0,tree.scale,
					tree.x,
					tree.y
				);
				_background.draw(bmd,matrix);
				//trace('\ttree[' + _trees.length + '] drawn');
			}
		}
	}
}