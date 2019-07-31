package common.iso.view.containers.background
{
	import com.raka.iso.utils.IDisposable;
	
	import common.iso.model.IsoModel;
	import common.iso.model.IsoPoster;
	import common.iso.model.IsoTree;
	import common.iso.model.IsoTreeSpawner;
	import common.iso.model.flooring.IsoFlooring;
	import common.iso.model.flooring.IsoMapBackgroundTexture;
	import common.iso.view.containers.BitmapLarge;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.containers.background.blueprint.BackgroundBlueprint;
	import common.iso.view.containers.background.blueprint.BlueprintItem;
	import common.iso.view.containers.background.blueprint.TreeBlueprintItem;
	import common.iso.view.display.IsoBase;
	import common.util.PRNG;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	public class IsoMapBackgroundRenderer implements IDisposable
	{
		/**
		 * Every frame the renderer will call the _nextStep function pointer until either it is set to null
		 * or it RENDER_TIME_PER_FRAME number of milliseconds has passed. Upon completion of a step the function step
		 * should set _nextStep to processQueue so that the next step in the queue can be performed.
		 * 
		 * BEFORE PUSHING SOMETHING IN TO THE QUEUE MAKE SURE IT CALLS processQueue() OR ASSIGNS _nextStep TO SOMETHING 
		 * THAT DOES AT SOME POINT TO KEEP THINGS MOVING
		 */
		
		public static const RENDER_TIME_PER_FRAME:int = 5;
		
		private var _canvas:BitmapLarge;
		private var _nextStep:Function;
		private var _queue:Array;
		private var _blueprint:BackgroundBlueprint;
		private var _renderIndex:int;
		private var _skipFrame:Boolean;
		private var _paused:Boolean;
		private var _backgroundIndex:int;
		private var _blockingRender:Boolean;
		
		public function IsoMapBackgroundRenderer(canvas:BitmapLarge)
		{
			_canvas = canvas;
		}
		
		/**
		 * Generates and parses BackgroundBlueprint
		 * Renders core background which requires that the map background image has loaded
		 */
		public function init(blockingRender:Boolean = false):void
		{
			_queue = [];
			_blueprint = new BackgroundBlueprint();
			_renderIndex = 0;
			_skipFrame = false;
			_paused = false;
			_backgroundIndex = int.MAX_VALUE;
			_blockingRender = blockingRender;
			
			_queue.push(processBackground);
			_queue.push(processDecals);
			_queue.push(processTiles);
			_queue.push(processPosters);
			_queue.push(processTrees);
			_queue.push(render);
			
			processQueue();
			
			_canvas.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function pause():void
		{
			_paused = true;
		}
		
		public function resume():void
		{
			_paused = false;
		}
		
		public function get hasDrawnBackground():Boolean
		{
			return _renderIndex >= _backgroundIndex;
		}
		
		public function redrawRect(rect:Rectangle):void
		{
			var bmd:BitmapData = new BitmapData(rect.width, rect.height, false, IsoMap.DEFAULT_COLOR);
			var bitmap:Bitmap = new Bitmap(bmd);
			var index:int;
			var items:Vector.<BlueprintItem> = _blueprint.items;
			var item:BlueprintItem;
			var dispObj:DisplayObject;
			var matrix:Matrix = new Matrix();
			
			var matrixDx:Number = - rect.x;
			var matrixDy:Number = - rect.y;
			
			bitmap.x = rect.x;
			bitmap.y = rect.y;
			
			bmd.lock();
			
			var queuedRefresh:Function = function():void
			{
				item = items[index];
				dispObj = item.getImage();
				
				if (item.intersectsRect(rect) && item.shouldDrawImage)
				{
					matrix.a = matrix.d = item.scale;
					matrix.tx = item.x + item.offsetX + matrixDx;
					matrix.ty = item.y + item.offsetY + matrixDy;
					bmd.draw(item.getImage(), matrix);
				}
				
				index++;
				if (index >= items.length)
				{
					matrix.a = matrix.d = 1;
					matrix.tx = rect.x;
					matrix.ty = rect.y;
					
					bmd.unlock();
					_canvas.draw(bitmap, matrix);
					processQueue();
				}
			};
				
			_queue.push(queuedRefresh);
			
			refresh();
		}
		
		public function refresh():void
		{
			if (_nextStep == null) processQueue();
		}
		
		public function dispose():void
		{
			_blueprint.dispose();
			_nextStep = null;
			_queue = null;
			_canvas.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function processQueue():void
		{
			if (_queue.length > 0) _nextStep = _queue.shift();
			else _nextStep = null;
		}
		
		private function onEnterFrame(e:Event):void
		{
			if (_paused) return;
			
			var startTime:int = getTimer();
			var time:int = startTime;
			var maxTime:int = RENDER_TIME_PER_FRAME;
			
			if (_blockingRender) maxTime = 15000;
			
			while (_nextStep != null && time - startTime < maxTime && !_skipFrame)
			{
				_nextStep();
				
				time = getTimer();
			}
			
			_skipFrame = false;
		}
		
		private function render():void
		{
			var items:Vector.<BlueprintItem> = _blueprint.items;
			var item:BlueprintItem;
			var matrix:Matrix = new Matrix();
			
			if (_renderIndex >= items.length)
			{
				processQueue();
				return;
			}
			
			_nextStep = function():void
			{
				item = items[_renderIndex];
				
				if (item.hasImage)
				{
					if (item.shouldDrawImage)
					{
						item.parseDimensions();
						
						matrix.a = matrix.d = item.scale;
						matrix.tx = item.x + item.offsetX;
						matrix.ty = item.y + item.offsetY;
						
						_canvas.draw(item.getImage(), matrix);
					}
					
					_renderIndex++;
					if (_renderIndex >= items.length)
					{
						processQueue();
					}
				}
				else
				{
					_skipFrame = true;
				}
			};
		}
		
		private function processBackground():void
		{
			var background:IsoMapBackgroundTexture = IsoModel.gi.background;
			if (!background || !background.hasImage)
			{
				processQueue();
				return;
			}
			
			var dispObj:DisplayObject;
			var matrix:Matrix;
			var tx:Number = 0;
			var ty:Number = 0;
			var prng:PRNG = new PRNG(1234);
			
			_nextStep = function():void
			{
				// todo - snm - remove the need to have a dispobj instance
				// this is ok for the moment because this will only be called after the background image has loaded
				dispObj = background.getRandomOverlayImage(prng.randomNumber());
				_blueprint.addBackgroundTextureItem(background, tx, ty, 1, prng.randomNumber());
				
				tx += dispObj.width;
				
				if (tx >= _canvas.width)
				{
					tx = 0;
					ty += dispObj.height;
					if (ty >= _canvas.height)
					{
						_backgroundIndex = _blueprint.numItems;
						processQueue();
					}
				}
			}
		}
		
		private function processDecals():void
		{
			var prng:PRNG = new PRNG(4321);
			var decals:Array = IsoModel.gi.overlays.concat();
			var decal:IsoMapBackgroundTexture;
			var dispObj:DisplayObject;
			var matrix:Matrix;
			var tx:Number;
			var ty:Number;
			var iy:int = 0;
			var ix:int = 0;
			
			decal = decals.shift();
			
			_nextStep = function():void
			{
				tx = (ix + prng.randomNumber()) * _canvas.width / decal.density;
				ty = (iy + prng.randomNumber()) * _canvas.height / decal.density;
				
				_blueprint.addBackgroundTextureItem(decal, tx, ty, 1, prng.randomNumber(), true);
				
				ix++;
				if (ix >= decal.density)
				{
					ix = 0;
					iy++;
					if (iy >= decal.density)
					{
						iy = 0;
						if (decals.length == 0) processQueue();
						else decal = decals.shift();
					}
				}
			}
		}
		
		private function processTiles():void
		{
			var prng:PRNG = new PRNG(1);
			var floorings:Array = IsoModel.gi.getFlooringList();
			var flooring:IsoFlooring;
			
			_nextStep = function():void
			{
				if (floorings.length == 0)
				{
					processQueue();
					return;
				}
				
				flooring = floorings.pop();
				var drawX:Number = Math.floor(IsoBase.GRID_PIXEL_SIZE * (flooring.x - flooring.y));
				var drawY:Number = Math.floor(IsoBase.GRID_PIXEL_SIZE * (flooring.x + flooring.y) / 2);
				_blueprint.addFlooringItem(flooring, drawX - _canvas.x, drawY - _canvas.y, 1);
			}
		}
		
		private function processPosters():void
		{
			var posters:Array = IsoModel.gi.posters;
			var poster:IsoPoster;
			var bitmap:Bitmap;
			var bmd:BitmapData;
			
			_nextStep = function():void
			{
				if (posters.length == 0)
				{
					processQueue();
					return;
				}
				
				poster = posters.shift();
				_blueprint.addURLItem(poster.url,poster.x, poster.y, poster.scale);
			}
		}
		
		private function processTrees():void
		{
			var treeSpawner:IsoTreeSpawner = IsoModel.gi.treeSpawner;
			var delta:Number = Math.min(IsoMap.VIEWPORT_WIDTH, IsoMap.VIEWPORT_HEIGHT) / treeSpawner.density;
			var treeX:Number;
			var treeY:Number;
			var prng:PRNG = new PRNG(1001);
			var ix:Number = -delta;
			var iy:Number = -delta;
			var bitmap:Bitmap;
			var bmd:BitmapData;
			
			if (!treeSpawner.shouldSpawnTrees)
			{
				processQueue();
				return;
			}
			
			_nextStep = function():void
			{
				if (prng.randomNumber() >= 1 / 5)
				{
					treeX = ix + prng.randomNumber() * delta * 2 / 3;
					treeY = iy + prng.randomNumber() * delta * 2 / 3;
					
					var tree:IsoTree = treeSpawner.getTreeForY(treeY, prng.randomNumber());
					
					if (tree)
					{
						tree.x = treeX;
						tree.y = treeY;
						_blueprint.addItem(new TreeBlueprintItem(tree));
					}
				}
				
				ix += delta;
				if (ix >= _canvas.width)
				{
					ix = 0;
					iy += delta;
					if (iy >= _canvas.height)
					{
						processQueue();
					}
				}
			}
		}
	}
}