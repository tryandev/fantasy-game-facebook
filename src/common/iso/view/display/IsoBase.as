package common.iso.view.display
{

	import com.raka.commands.datastructures.CommandQueue;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.cmd.IsoCommandLoadAsset;
	import common.iso.model.IsoModel;
	import common.iso.view.containers.IsoMap;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;

	public class IsoBase extends Sprite implements IIsoBase
	{
		public static const GRID_PIXEL_SIZE:int = 32;		
		public static const IGNORE_MOUSE_DISPLAY:String = "ignoreAssetLayer";
		public static const IGNORE_GRAPHICS_DISPLAY:String = "ignoreGraphicsLayer";
		
		private const UIDISPLAY_PADDING:int = 30;
		
		protected var _isoX:Number = -1;
		protected var _isoY:Number = -1;
		protected var _isoWidth:Number = 1;
		protected var _isoLength:Number = 1;
		protected var _isoSize:int = 1;
		protected var _tiles:Array = [];
		
		protected var _initialized:Boolean = false;
		protected var _assetLoaded:Boolean = false;
		
		protected var _graphicsDisplay:Sprite;
		protected var _assetDisplay:Sprite;
		protected var _uiDisplay:Sprite;
		
		protected var _transparent:Boolean = false;
		
		protected var _cacheKey:String;
		protected var _assetURL:String;
		
		protected var _successCallback:Function;
		protected var _failureCallback:Function;
	

		public function IsoBase()
		{
			if (!(this is IsoTile))
			{
				_graphicsDisplay = addChild(new Sprite()) as Sprite;
				_graphicsDisplay.name = IGNORE_GRAPHICS_DISPLAY;
				_assetDisplay = addChild(new Sprite()) as Sprite;
				_uiDisplay = addChild(new Sprite()) as Sprite;
				_uiDisplay.name = IGNORE_MOUSE_DISPLAY;
			}

			this.mouseChildren = false;
			this.mouseEnabled = false;
			this.buttonMode = false;
			this.useHandCursor = false;

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		//  PUBLIC FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function dispose():void
		{
			while(numChildren > 0)
				removeChildAt(0);
			
			_successCallback = null;
			graphics.clear();
			_tiles = null;
			this.clearAssets();
			this.clearUI();
			_assetDisplay = null;
			_uiDisplay = null;
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		public function isInMapBounds(borderSize:int = 0, iX:int = int.MIN_VALUE, iY:int = int.MIN_VALUE):Boolean
		{
			if (iX == int.MIN_VALUE) iX = isoX;
			if (iY == int.MIN_VALUE) iY = isoY;
			
			var isInX:Boolean = (iX - borderSize >= 0 && iX + isoWidth + borderSize < map.gridWidth);
			var isInY:Boolean = (iY - borderSize >= 0 && iY + isoWidth + borderSize < map.gridHeight);
			
			return isInX && isInY;
		}
		
		public function addToMap(inBorderSize:int = 0):void
		{
			map.addChildObj(this, inBorderSize);
		}
		
		public function removeFromMap():void
		{
			map.removeChildObj(this);
		}	
		
		//  PROTECTED FUNCTIONS
		// -----------------------------------------------------------------//
	
		protected function loadAsset(onSuccess:Function = null, onFailure:Function = null):void
		{
			_successCallback = onSuccess;
			_failureCallback = onFailure;
			_assetLoaded = false;
			
			new IsoCommandLoadAsset(_assetURL, assetLoadComplete, assetLoadFailure).execute();
		}	
		
		protected function loadAssetGroup(arr:Array, onSuccess:Function):void
		{
			_successCallback = onSuccess;
			_assetLoaded = false;
			
			var queue:CommandQueue = new CommandQueue(assetLoadComplete, assetLoadFailure);
			
			for each (var url:String in arr)
			{
				queue.add(new IsoCommandLoadAsset(url));
			}	
			
			queue.execute();
		}	
		
		protected function assetLoadComplete(data:Object):void
		{
			_assetLoaded = true;
			
			if (_successCallback != null)
			{
				_successCallback();
				_successCallback = null;
			}
		}	
		
		protected function assetLoadFailure(data:Object):void
		{
			Log.error(this, "Cannot load assets "+_cacheKey);
			_failureCallback && _failureCallback();
			_failureCallback = null;
		}	
		
		protected function getAssetInstance():DisplayObject
		{
			return getClassInstance(_cacheKey, _assetURL);
		}
		
		protected function getLibraryItemInstance(linkageName:String):DisplayObject
		{
			return getClassInstance(linkageName, _assetURL);
		}
		
		protected function getClassInstance(item:String, url:String):DisplayObject
		{	
			var ClassReff:Class = IsoModel.gi.getCachedAsset(item, url);
	
			if(ClassReff)
			{
				return new ClassReff() as DisplayObject;
			}else{
				Log.error(this, "Can not create instance of "+ item);
				return null;		
			}
				
//			return new Sprite();
		}	
		
		protected function loadAssetFromURL(url:String, onSuccess:Function):void
		{
			new IsoCommandLoadAsset(url, onSuccess).execute();
		}	
		
		protected function addAsset(value:DisplayObject):DisplayObject
		{
			if (_assetDisplay) 
			{
				return _assetDisplay.addChild(value);
			}
			else
			{
				return null;
			}
		}
		
		protected function clearAssets():void
		{
			// TODO - rt - if mc, stop playing before removing, or it plays in memory until gc comes
			while(_assetDisplay && _assetDisplay.numChildren > 0)
				_assetDisplay.removeChildAt(0);
		}	
		
		protected function clearUI():void
		{
			while(_uiDisplay && _uiDisplay.numChildren > 0)
				_uiDisplay.removeChildAt(0);
		}	
		
		protected function clearGraphics():void
		{
			_graphicsDisplay.graphics.clear();
		}
		
		protected function removeAsset(value:DisplayObject):DisplayObject
		{
			if (value is MovieClip)
				MovieClip(value).stop();
			
			return _assetDisplay.removeChild(value);
		}
		
		protected function addUI(value:DisplayObject):DisplayObject
		{
			return _uiDisplay.addChild(value);
		}
		
		protected function removeUI(value:DisplayObject):DisplayObject
		{
			return _uiDisplay.removeChild(value);
		}
		
		protected function positionUI():void
		{
			_uiDisplay.x = -(_uiDisplay.width / 2);
			_uiDisplay.y = -(_assetDisplay.height + UIDISPLAY_PADDING);
		}
		
		//  GETTER SETTER FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function get mapOverlayPostion():Point
		{
			return localPosition;	
		}
		
		public function get localPosition():Point
		{
			return new Point(this.x, this.y);
		}	
		
		public function get assetURL():String
		{
			return _assetURL;
		}
		
		public function set assetURL(value:String):void
		{
			_assetURL = value;
		}
		
		public function get cacheKey():String
		{
			return _cacheKey;
		}
		
		public function set cacheKey(value:String):void
		{
			_cacheKey = value;
		}
		
		public function get screenPoint():Point
		{
			return localToGlobal(new Point(0, 0.5 * _isoSize * GRID_PIXEL_SIZE));
		}

		public function get isoX():Number
		{
			return _isoX;
		}

		public function get isoY():Number
		{
			return _isoY; 
		}

		public function get isoWidth():Number
		{
			return _isoWidth;
		}

		public function get isoLength():Number
		{
			return _isoLength;
		}

		public function get isoSize():Number
		{
			return _isoSize;
		}

		public function set isoX(value:Number):void
		{
			_isoX = value;
			reposition();
		}

		public function set isoY(value:Number):void
		{
			_isoY = value;
			reposition();
		}

		public function set isoWidth(value:Number):void
		{
			_isoWidth = value;
			_isoSize = (_isoWidth + _isoLength) * 0.5;
		}

		public function set isoLength(value:Number):void
		{
			_isoLength = value;
			_isoSize = (_isoWidth + _isoLength) * 0.5;
		}
		
		public function set isoSize(value:Number):void
		{
			_isoSize = (value < 1) ? 1:value;
			
			if (_isoSize != _isoWidth || _isoSize != _isoLength)
			{
				_isoWidth = _isoSize;
				_isoLength = _isoSize;
			}
			
			redraw();
		}

		public function get tilesAttached():Array
		{
			return _tiles;
		}

		public function get occupy():Boolean
		{
			return true;
		}

		public function get sortY():Number
		{
			return 0.5 * GRID_PIXEL_SIZE * (_isoX + _isoY + _isoSize) + GRID_PIXEL_SIZE * (_isoX - _isoY) * 0.00001;
		}

		protected function redraw():void
		{
			/*graphics.lineStyle();
			graphics.beginFill(0xFF0000, 1);
			graphics.drawRect(-1, -1, 2, 2);
			graphics.endFill();

			graphics.lineStyle();
			graphics.beginFill(0x0000FF, 1);
			graphics.drawRect(-1, (GRID_PIXEL_SIZE * _isoSize * 0.5) - 1, 2, 2);
			graphics.endFill();*/
		}

		protected function reposition():void
		{
			this.x = GRID_PIXEL_SIZE * (_isoX - _isoY);
			this.y = GRID_PIXEL_SIZE * (_isoX + _isoY) / 2;
		}
		
		protected function get map():IsoMap
		{
			return IsoController.gi.isoWorld.isoMap;
		}
			
		//  OVERRIDE FUNCTIONS
		// -----------------------------------------------------------------//		
		
		protected function addedToStage():void
		{
			// override if needed
		}	
		
		//  HANDLER FUNCTIONS
		// -----------------------------------------------------------------//
		private function onAddedToStage(event:Event):void
		{
			addedToStage();
		}
		
		//  UTIL FUNCTIONS
		// -----------------------------------------------------------------//
		
		/*
		public function tr(...args):void
		{
			args = ["\t\t[++>]" , this].concat(args);
			trace.apply(this, args);
		}	
		*/
		
		public function drawPlacementFloor(validPlace:Boolean, remove:Boolean = false, inBorderSize:int = 0, hideDefense:Boolean = false):void {
			var g:Graphics = _graphicsDisplay.graphics;
			clearGraphics();
			
			if (remove) {
				return;
			}
			var color:int;
			color = (validPlace) ? 0x00FF00:0xFF0000;
			
			/*g.lineStyle(2 + (inBorderSize > 0) ? 3:0, color, 1);
			g.beginFill(color, 0.25 + (inBorderSize > 0) ? 0.25:0);
			g.moveTo(0, 0);
			g.lineTo(_isoSize * 1.0 * IsoBase.GRID_PIXEL_SIZE,	_isoSize * 0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(0, 										_isoSize * 1.0 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(_isoSize * -1. * IsoBase.GRID_PIXEL_SIZE,	_isoSize * 0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(0, 0);
			g.endFill();*/
			
			g.lineStyle(5, color, 0.75);
			g.beginFill(color, 0.375);
			g.moveTo(0, -inBorderSize * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo((_isoSize + inBorderSize*2) * 1.0 * IsoBase.GRID_PIXEL_SIZE, _isoSize * 0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(0, (_isoSize + inBorderSize) * 1.0 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo((_isoSize + inBorderSize*2) * -1. * IsoBase.GRID_PIXEL_SIZE, _isoSize * 0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(0, -inBorderSize * IsoBase.GRID_PIXEL_SIZE);
			g.endFill();
		}
		
		public function transparent(value:Boolean):void
		{
			_assetDisplay.alpha = (value) ? 0.5 : 1;
		}
	}
}
