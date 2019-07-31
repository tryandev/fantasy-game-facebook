package common.iso.view.containers {
	import com.greensock.TweenNano;
	import com.greensock.easing.Quad;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.crimetown.view.popup.PopupManager;
	import com.raka.utils.logging.Log;
	
	import common.iso.view.display.IsoBase;
	import common.test.debug.FPS;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.util.StageRef;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ka.control.ControllerViewContainers;
	
	public class IsoWorld extends Sprite
	{
		private static const DRAG_PAN_THRESHOLD:int = 10;
		public static const BUILDING_PADDING:int = 1;
		
		private var _isoMap:IsoMap;
		private var _scalableContainer:Sprite;
		private var _isoOverlay:IsoOverlay;
		
		private var _isWorldDragged:Boolean;
		private var _isMouseDown:Boolean;
		private var _worldDownX:Number;
		private var _worldDownY:Number;
		
		private var _zoomScale:Number;
		private var _zoomLevels:Array;
		private var _zoomIndex:int;
		private var _zoomIndexMax:int;
		private var _zoomIndexMin:int;
		private var _zoomScaleMax:Number;
		private var _zoomScaleMin:Number;

		private var _isoMapWidth:int = 56;
		private var _isoMapHeight:int = 56;
		
		private var _busyZoom:Boolean = false;
		private var _isWorldConstrained:Boolean = true;
		private var _isScrollingAllowed:Boolean = true;
		
		public function IsoWorld()
		{
			loadConfigZoomLevels();
			calculateZoomConstraints();
			_zoomScale = _zoomScaleMin;
			
			_scalableContainer = new Sprite();
			_isoOverlay = new IsoOverlay();
			
			addChild(_scalableContainer);
			ControllerViewContainers.gi.overlayContainer.addChild(_isoOverlay);
			
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function loadConfigZoomLevels():void
		{
			var configZooms:Array = AppConfig.game.getNumberArray(GameConfigEnum.MAP_ZOOM_LEVELS);
			
			_zoomLevels = configZooms.sort(Array.NUMERIC);
			_zoomIndex = -1;
		}
		
		public function dispose():void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, 		init, 				false);
			stage.removeEventListener(Event.RESIZE, 			stageResize, 		false);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, 	worldMouseDown,		false);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, 	worldMouseDrag,		false);
			stage.removeEventListener(MouseEvent.MOUSE_UP, 		worldMouseUp,		false);
			this.removeEventListener(MouseEvent.CLICK, 			worldMouseClick,	false);
			this.removeEventListener(MouseEvent.MOUSE_WHEEL, 	worldMouseWheel,	false);
			
			if (_isoMap)
			{
				removeChild(_scalableContainer);
				_isoMap.dispose();
				_isoMap = null;
				_scalableContainer = null;
				
				removeChild(_isoOverlay);
				_isoOverlay.dispose();
				_isoOverlay = null;
			}
		}
		
		public function isoMapReset(zoomIndex:int = -1, inMapWidth:int = -1, inMapHeight:int = -1, inFlags:String = ''):void 
		{
			//trace(this + " @@@@@@@@@@@@@@@@@@@@@@ isoMapReset");
			var firstIsoMap:Boolean = _isoMap == null;
			if (_isoMap)
			{
				_scalableContainer.removeChild(_isoMap);
				_isoMap.dispose();
			}
			
			_isoMap = new IsoMap(
				(inMapWidth > 0) ? inMapWidth : _isoMapWidth, //(newWidth != -1) ? newWidth:_isoMapWidth, 
				(inMapHeight > 0) ? inMapHeight : _isoMapHeight, //(newHeight != -1) ? newHeight:_isoMapHeight
				inFlags
			);
			
			if (firstIsoMap) PopupManager.instance.pauseAllActivePopups();
			
			_isoOverlay.dispose();
			
			_scalableContainer.addChild(_isoMap);
			
			stageResize();
			
			if (zoomIndex > -1) 
				zoomToIndex(zoomIndex, true);
			else
				zoomToIndex(minimumZoomIndex, true);
			
			_isoMap.init();
			worldConstrain();
		}
		
		public function startBattle():void
		{
			lockBusyZoom();
			isWorldConstrained = false;
			isScrollingAllowed = false;
			
			calculateZoomConstraints();
			
			isoMap.startBattle();
		}
		
		public function endBattle():void
		{
			isScrollingAllowed = true;
			isWorldConstrained = true;
			unlockBusyZoom();
			
			calculateZoomConstraints();
			
			isoMap.endBattle();
		}
		
		public function get isWorldDragged():Boolean
		{
			return _isWorldDragged;
		}	
		
		private function init(e:Event = null):void
		{
			stageResize();
			
			removeEventListener(Event.ADDED_TO_STAGE, init, false);
			
			stage.addEventListener(Event.RESIZE, 			stageResize,		false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, 	worldMouseDown, 	false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, 	worldMouseDrag, 	false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, 	worldMouseUp, 		false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, 	worldMouseWheel,	false, 0, true);
//			we don't add a MOUSE_SCROLL handler because IsoController uses a javascript callback to scroll the isoMap
			this.addEventListener(MouseEvent.CLICK, 		worldMouseClick, 	false, 0, true);
		}
		
		private function stageResize(e:Event = null):void
		{
			_scalableContainer.x = Math.round(stage.stageWidth/2);
			_scalableContainer.y = Math.round(stage.stageHeight/2);

			if (!_isoMap) return;
			
			calculateZoomConstraints();
			
			if (_zoomScale < _zoomScaleMin) 
			{
				_zoomIndex = _zoomIndexMin;
				worldZoom = _zoomLevels[_zoomIndexMin];
			}
			
			worldConstrain();
		}
		
		public function worldMouseDown(e:Event):void
		{
			_isMouseDown = true;
			_worldDownX = stage.mouseX;
			_worldDownY = stage.mouseY;
			_isWorldDragged = false;
		}
		
		private function worldMouseDrag(e:Event):void
		{
			if (!_isMouseDown || !_isScrollingAllowed)
				return;
			
			var dx:int = stage.mouseX - _worldDownX;
			var dy:int = stage.mouseY - _worldDownY;
			
			if (dx * dx + dy * dy > DRAG_PAN_THRESHOLD * DRAG_PAN_THRESHOLD && !_isWorldDragged){
				_isWorldDragged = true;
				this.mouseEnabled = false;
				this.mouseChildren = false;
			}
			
			if (_isWorldDragged)
			{
				_worldDownX = stage.mouseX;
				_worldDownY = stage.mouseY;
				
				_isoMap.x += dx / _scalableContainer.scaleX;
				_isoMap.y += dy / _scalableContainer.scaleY;
				
				worldConstrain();
			}
		}
		
		public function set mapX(value:Number):void {
			_isoMap.x = value;
			worldConstrain();
		}
		
		public function set mapY(value:Number):void {
			_isoMap.y = value;
			worldConstrain();
		}
		
		public function get mapX():Number {
			return _isoMap.x;
		}
		
		public function get mapY():Number {
			return _isoMap.y;
		}
		
		public function calcZoomLevelForArea(isoWidth:int, isoHeight:int, fitOutside:Boolean = true):Number
		{
			var width:Number = IsoBase.GRID_PIXEL_SIZE * (isoWidth + isoHeight);
			var height:Number = IsoBase.GRID_PIXEL_SIZE * (isoWidth + isoHeight) / 2;
			
			var inside:Number = Math.max(stage.stageWidth / width, stage.stageHeight / height);
			var outside:Number = Math.min(stage.stageWidth / width, stage.stageHeight / height);
			
			return fitOutside ? outside : inside;
		}
		
		public function getObjWorldPoint(inObj:IsoBase):Point {
			var wPoint:Point = inObj.screenPoint;
			wPoint.x -= StageRef.stage.stageWidth/2;
			wPoint.y -= StageRef.stage.stageHeight/2;
			wPoint.x *= 1/this.scale;
			wPoint.y *= 1/this.scale;
			return wPoint;
		}
		
		public function getWorldScreenPoint(inIsoX:Number, inIsoY:Number):Point
		{
			var pX:Number = IsoBase.GRID_PIXEL_SIZE * (inIsoX - inIsoY);
			var pY:Number = IsoBase.GRID_PIXEL_SIZE * (inIsoX + inIsoY) / 2;
			var wPoint:Point = _isoMap.localToGlobal(new Point(pX,pY));
			wPoint.x -= StageRef.stage.stageWidth/2;
			wPoint.y -= StageRef.stage.stageHeight/2;
			wPoint.x *= 1/this.scale;
			wPoint.y *= 1/this.scale;
			return wPoint;
		}
		
		private function worldMouseUp(e:Event):void
		{
			_isMouseDown = false;
			
			if (_isWorldDragged)
			{
				e.stopPropagation();
				e.stopImmediatePropagation();
				
				_isoMap.cancelMouseClick();
				
				this.mouseEnabled = true;
				this.mouseChildren = true;
			}
			else
			{
				FPS.timerGet();
			}			
		}
		
		private function worldMouseClick(e:Event):void
		{
			if (_isWorldDragged) {
				e.stopPropagation();
				e.stopImmediatePropagation();
			}
		}
		
		private function worldMouseWheel(e:MouseEvent):void
		{
			if (Math.abs(e.delta) < 1 || _busyZoom || !_isoMap || _isoMap.isMouseModePaused) return;
			
			var newIndex:int = _zoomIndex + (e.delta >= 0 ? 1 : -1);
			
			zoomToIndex(newIndex);
		}
		
		public function set zoomIndex(value:int):void
		{
			zoomToIndex(value, true);
		}
		
		public function get zoomIndex():int
		{
			return _zoomIndex;
		}
		
		public function zoomIn(doInstantly:Boolean = false, amount:Number = 1):void
		{
			zoomToIndex(_zoomIndex + amount, doInstantly);
		}
		
		public function zoomOut(doInstantly:Boolean = false, amount:Number = 1):void
		{
			zoomToIndex(_zoomIndex - amount, doInstantly);
		}
		
		public function zoomToIndex(index:int, doInstantly:Boolean = false):void
		{
			if (!doInstantly && (!_isoMap || !_isoMap.isoMouseModeZoomAllowed)) return;
			
			index = Math.max(_zoomIndexMin, Math.min(_zoomIndexMax, index));
			
			if (!_busyZoom && index != _zoomIndex )
			{
				lockBusyZoom();
				_zoomIndex = index;
				
				if (doInstantly)
				{
					worldZoom = _zoomLevels[_zoomIndex];
					worldZoomComplete();
				}
				else
				{
					animateWorldZoom(_zoomLevels[_zoomIndex]);
				}
			}
		}
		
		public function get minimumZoomIndex():int
		{
			return _zoomIndexMin;
		}
		
		public function get worldZoom():Number
		{
			return _zoomScale;
		}
		
		public function set worldZoom(newScale:Number):void
		{
			//trace(this + " worldZoom: " + newScale);
			if (!_isoMap || isNaN(newScale)) return;
			
			var preHeight:Number = _isoMap.height;
			var postHeight:Number = _isoMap.height;
			
			_zoomScale = newScale;
			
			_scalableContainer.x = (_scalableContainer.x - StageRef.stage.stageWidth / 2) / scaleX;
			_scalableContainer.y = (_scalableContainer.y - StageRef.stage.stageHeight / 2) / scaleY;
			
			_zoomScale = Math.min(_zoomScaleMax, Math.max(_zoomScaleMin, _zoomScale));
			
			_scalableContainer.scaleX = _zoomScale;
			_scalableContainer.scaleY = _zoomScale;
			postHeight = _isoMap.height;
			
			_scalableContainer.x = Math.round(_scalableContainer.x * scaleX + StageRef.stage.stageWidth / 2);
			_scalableContainer.y = Math.round(_scalableContainer.y * scaleY + StageRef.stage.stageHeight / 2);
			
			worldConstrain();
			_isoOverlay.updatePositions();
		}
		
		public function animateWorldZoom(newScale:Number):void
		{
			TweenNano.to(this, 0.35, { worldZoom: newScale, ease: Quad.easeInOut, onComplete: worldZoomComplete });
		}
		
		public function lockBusyZoom():void
		{
			//trace(this + " lockBusyZoom");
			_busyZoom = true;
			try
			{
				ExternalInterface.call('wheelDisable');
			}
			catch(err:Error)
			{
				Log.warn(this, 'Cannot call ExternalInterface wheelDisable');
			}
		}
		
		public function unlockBusyZoom():void
		{
			//trace(this + "unlockBusyZoom");
			_busyZoom = false;
			try 
			{
				ExternalInterface.call('wheelEnable');
			}
			catch(err:Error)
			{
				Log.warn(this, 'Cannot call ExternalInterface wheelEnable');
			}
		}
		
		public function get isWorldConstrained():Boolean
		{
			return _isWorldConstrained;
		}
		
		public function set isWorldConstrained(value:Boolean):void
		{
			_isWorldConstrained = value;
		}
		
		public function set isScrollingAllowed(value:Boolean):void
		{
			_isScrollingAllowed = value;
		}
		
		public function get isScrollingAllowed():Boolean
		{
			return _isScrollingAllowed;
		}
		
		public function get isMapReady():Boolean
		{
			return _isoMap && _isoMap.isMinimumBackgroundRendered;
		}
		
		private function worldZoomComplete():void
		{
			//trace(this + " worldZoomComplete");
			unlockBusyZoom();
		}
		
		private function calculateZoomConstraints():void
		{
			_zoomIndexMax = _zoomLevels.length - 1;
			_zoomIndexMin = 0;
			
			_zoomScaleMax = _zoomLevels[_zoomIndexMax];
			_zoomScaleMin = _zoomLevels[_zoomIndexMin];
			
			if (isoMap == null) return;
			
			var i:int = 0;
			var zoom:Number;
			var viewport:Rectangle;
			var maxWidth:Number;
			var maxHeight:Number;
			
			if (isWorldConstrained)
			{
				viewport = isoMap.getViewRect();
				maxWidth = Math.min(isoMap.width, viewport.width);
				maxHeight = Math.min(isoMap.height, viewport.height);
			}
			else
			{
				maxWidth = isoMap.width;
				maxHeight = isoMap.height;
			}
			_zoomScaleMin = Math.max(stage.stageWidth / maxWidth, stage.stageHeight / maxHeight);
			
			do 
			{
				zoom = _zoomLevels[i];
				_zoomIndexMin = i;
				i++;
			} while(zoom < _zoomScaleMin && i < _zoomIndexMax);
		}
		
		private function worldConstrain():void
		{
			var mapRect:Rectangle = _isWorldConstrained? _isoMap.getViewRect() : _isoMap.getMapSizedViewRect();
			
			var bx:Number = -_scalableContainer.x / _scalableContainer.scaleX;
			var by:Number = -_scalableContainer.y / _scalableContainer.scaleY;
			var bw:Number = stage.stageWidth / _scalableContainer.scaleX;
			var bh:Number = stage.stageHeight / _scalableContainer.scaleY;
			
			var viewPort:Rectangle = new Rectangle(bx, by, bw, bh);
			
			if (viewPort.height > mapRect.height) mapRect.height = viewPort.height;
			if (viewPort.width > mapRect.width) mapRect.width = viewPort.width;
			
			if (mapRect.left > viewPort.left)  _isoMap.x += viewPort.left - mapRect.left;
			if (mapRect.right < viewPort.right) _isoMap.x += viewPort.right - mapRect.right;
			
			if (mapRect.top > viewPort.top) _isoMap.y += viewPort.top - mapRect.top;
			if (mapRect.bottom < viewPort.bottom) _isoMap.y += viewPort.bottom - mapRect.bottom;
			
			_isoOverlay.x = _scalableContainer.x + _isoMap.x * _scalableContainer.scaleX;
			_isoOverlay.y = _scalableContainer.y + _isoMap.y * _scalableContainer.scaleX;
			
			if (TutorialController.getInstance().active)
			{
				TutorialController.getInstance().updatePositions();
			}
		}
		
		public function addOverlay(item:Sprite):Sprite
		{
			if(item is IIsoOverlay)
				_isoOverlay.addChild(item);
			
			return item;
		}	
		
		public function get isoMap():IsoMap
		{
			return _isoMap;
		}
		
		public function get overlay():IsoOverlay
		{
			return _isoOverlay;
		}	
		
		public function get scale():Number {
			return _scalableContainer.scaleY;
		}
	}
}
