package common.iso.control.mouse
{
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.crimetown.view.components.ui.HoverTooltip;
	
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoRivalBuilding;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ka.control.ControllerHud;
	import ka.control.ControllerViewContainers;
	
	public class IsoMouseModeExpansion implements IIsoMouseMode
	{
		protected var _map:IsoMap;
		
		protected var _expandToolTip:HoverTooltip;
		protected var _reticule:Sprite;
		protected var _canBuyExpansion:Boolean;
		
		protected var _expX:int;
		protected var _expY:int;
		protected var _lastExpX:int;
		protected var _lastExpY:int;
		
		protected var _expansionSize:int;
		
		public function IsoMouseModeExpansion()
		{
			createReticule();
			createExpandTooltip();
		}

		private function createExpandTooltip():void
		{
			var cursor:MovieClip = new ClickToExpandCursor();
			cursor.gotoAndStop(clickToExpandCursorFrame);
			_expandToolTip = new HoverTooltip();
			_expandToolTip.addChild(cursor);
			
			ControllerViewContainers.gi.overlayContainer.addChild(_expandToolTip);
		}
		
		public function init(map:IsoMap):void
		{
			_map = map;
			
			addMouseEventListeners();
			
			_map.addTileOverlayItem(_reticule);
			
			updateExpansionCoordinates();
			updateReticule();
		}
		
		protected function createReticule():void
		{
			_reticule = new Sprite();
			_reticule.mouseEnabled = false;
			
			_expansionSize = GameObjectLookup.sharedGameProperties.expansion_size;
			var g:Graphics = _reticule.graphics;
			styleReticule(g);
			
			var ps:Number = _expansionSize * IsoBase.GRID_PIXEL_SIZE;
			g.moveTo(ps * (0 - 0), ps * (0 + 0) / 2);
			g.lineTo(ps * (1 - 0), ps * (1 + 0) / 2);
			g.lineTo(ps * (1 - 1), ps * (1 + 1) / 2);
			g.lineTo(ps * (0 - 1), ps * (0 + 1) / 2);
			g.lineTo(ps * (0 - 0), ps * (0 + 0) / 2);
			g.endFill();
			
			_reticule.visible = false;
		}
		
		protected function get clickToExpandCursorFrame():String
		{
			return "ready";
		}
		
		protected function styleReticule(graphics:Graphics):void
		{
			graphics.lineStyle(5, 0x569932, 1);
			graphics.beginFill(0x7cd641, 0.1);
		}
		
		protected function removeMouseEventListeners():void
		{
			_map.removeEventListener(Event.ENTER_FRAME, onMouseMove);
			_map.removeEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		protected function addMouseEventListeners():void
		{
			_map.addEventListener(Event.ENTER_FRAME, onMouseMove);
			_map.addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		public function pause():void
		{
			removeMouseEventListeners();
			_expandToolTip.hide();
			_reticule.visible = false;
		}
		
		public function resume():void
		{
			addMouseEventListeners();
			
			updateExpansionCoordinates();
			updateReticule();
		}
		
		protected function onMouseClick(event:MouseEvent):void
		{
			updateExpansionCoordinates();
			
			if (_canBuyExpansion)
			{
				ExpansionController.instance.buyExpansion(_expX, _expY);
			}
			
			_map.removeTileOverlayItem(_reticule);
			_map.mouseMode = new IsoMouseModeLive();
		}
		
		protected function onMouseMove(event:Event):void
		{
			updateExpansionCoordinates();
			updateReticule();
		}
		
		protected function updateReticule():void
		{
			_reticule.visible = shouldShowReticule();
			
			if (_reticule.visible)
			{
				_reticule.x = _expansionSize * IsoBase.GRID_PIXEL_SIZE * (_expX - _expY);
				_reticule.y = _expansionSize * IsoBase.GRID_PIXEL_SIZE * (_expX + _expY) / 2;
				
				var reticulePosition:Point = _reticule.localToGlobal(new Point(0, _reticule.height/2));
				_expandToolTip.x = reticulePosition.x - _expandToolTip.width/2;
				_expandToolTip.y = reticulePosition.y - _expandToolTip.height/2;
				
				if (!_expandToolTip.visible)
				{
					_expandToolTip.show(false);
				}
			}
			else if (_expandToolTip.visible)
			{
				_expandToolTip.hide();
			}
		}
		
		protected function shouldShowReticule():Boolean
		{
			return _canBuyExpansion;
		}
		
		protected function updateExpansionCoordinates():void
		{
			_lastExpX = _expX;
			_lastExpY = _expY;
			
			var exp:Point = _map.localPixelToIso(_map.mouseX, _map.mouseY);
			exp.x = Math.floor(exp.x / _expansionSize);
			exp.y = Math.floor(exp.y / _expansionSize);
			
			_expX = exp.x;
			_expY = exp.y;
			
			_canBuyExpansion = ExpansionController.instance.canBuyExpansion(_expX, _expY);
		}
		
		public function dispose():void
		{
			removeMouseEventListeners();
			_expandToolTip.parent.removeChild(_expandToolTip);
			
			if (_reticule && _reticule.parent)
			{
				_map.removeTileOverlayItem(_reticule);
			}
			
			_map = null;
		}
	}
}