package common.iso.view.containers
{
	import com.funzio.ka.KingdomAgeMain;
	import com.greensock.TweenLite;
	import com.raka.iso.utils.IDisposable;
	
	import common.iso.control.IsoController;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class IsoOverlayItem extends Sprite implements IIsoOverlay,IDisposable
	{
		protected var _mapPosition:Point = new Point(0,0);
		
		public var globalPosition:Point = new Point();
		
		protected var _asset:DisplayObject;
		protected var _isInIso:Boolean = false;
		
		private var _useMouseEvents:Boolean;
		
		public function IsoOverlayItem()
		{
			super();
					
			useMouseEvents = false;
			
			init();
			
			hide();
		}
		
		
		public function dispose():void
		{
			if(useMouseEvents) 
			{
				removeListeners();
			}
			
			if (_asset && DisplayObject(_asset).parent)
			{
				DisplayObject(_asset).parent.removeChild(_asset);
				_asset = null;
			}
			
			if (parent) 
			{
				parent.removeChild(this);
			}
		}	
		
		protected function init():void
		{
			// override
		}	
		
		public function show():void
		{
			updatePosition();
			this.visible = true;
		}	
		
		public function hide():void
		{
			this.visible = false;
		}	

		public function fadeIn():void
		{
			if(_asset)
			{
				_asset.alpha = 0;
				_asset.y = 20;
				
				show();
				TweenLite.to(_asset, 0.4, {alpha:1, y:0});
			}
		}	
		
		public function fadeOut():void
		{
			if(_asset)
				TweenLite.to(_asset, 0.4, {alpha:0, y:20,  onComplete: onFadeOutComplete});
		}	
		
		private function onFadeOutComplete():void
		{
			hide();
			alpha = 1; 
			resetAssetPosition();
		}	
		
		public function addToMap():void
		{
			overlay.addChild(this);
		}	
		
		/**
		 *	Use this if you are using overlay in the iso world.
		 */	
		public function setMapPosition(point:Point):void
		{
			_isInIso = true;
			_mapPosition = new Point(point.x, point.y);	
			
			if(this.parent != overlay) 
				addToMap();
			
			updatePosition();
		}	
		
		public function setLocalMapPosition(x:Number = 0, y:Number = 0):void
		{
			_mapPosition = map.globalToLocal(overlay.localToGlobal(new Point(this.x + x, this.y + y)));
		}	

		/**
		 *	Add overlay to the global overlay layer using
		 * 	a display object as a positioning reference.
		 */	
		public function setOverlayPosition(displayObject:DisplayObject, centerOnObject:Boolean = true):void
		{
			_isInIso = false;
			globalPosition = displayObject.localToGlobal(new Point());
			if(centerOnObject){
				globalPosition.x += displayObject.width/2;
				globalPosition.y += displayObject.height/2;
			}

			updatePosition();
			overlayContainer.addChild(this);
		}	
		
		/**
		 *	Center the overlay on its local position.
		 */	
		public function updatePosition():void
		{
			this.x = localPosition.x - this.width / 2;
			this.y = localPosition.y - this.height;
		}	
		
		/**
		 *	Move the overlay in the overlay scope and update its 
		 * 	relative map position to match
		 */	
		public function moveLocaltoIso(x:Number, y:Number):void
		{
			this.x = x;
			this.y = y;
			
			setMapPosition(mapPosition);
		}	
		
		private function resetAssetPosition():void
		{
			if(_asset)
			{
				_asset.x = 0;
				_asset.y = 0;
			}
		}	
		
		private function drawTemp():void
		{
			this.graphics.beginFill(0x444488, 0.8);
			this.graphics.drawRoundRect(-30,-20,60,40,10,10);
			this.graphics.endFill();
			this.graphics.beginFill(0x222222, 1);
			this.graphics.drawRoundRect(-2,-2,4,4,2,2);
			this.graphics.endFill();
		}	
		
		protected function get map():IsoMap
		{
			return IsoController.gi.isoWorld.isoMap;	
		}	
		
		protected function get overlay():IsoOverlay
		{
			return IsoController.gi.isoWorld.overlay;
		}	
		
		protected function get overlayContainer():Sprite
		{
			return KingdomAgeMain.instance.tooltipContainer;
		}	
		
		//  HANDLER FUNCTIONS
		// -----------------------------------------------------------------//
		protected function addListeners():void
		{
			this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverHandler);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutHandler);
			this.addEventListener(MouseEvent.CLICK, onMouseClickHandler);
		}	
		
		protected function removeListeners():void
		{
			this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverHandler);
			this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutHandler);
			this.removeEventListener(MouseEvent.CLICK, onMouseClickHandler);
		}	
		
		protected function onMouseOverHandler(event:MouseEvent):void
		{
			mouseOver();
		}
		
		protected function onMouseOutHandler(event:MouseEvent):void
		{
			mouseOut()
		}
		
		protected function onMouseClickHandler(event:MouseEvent):void
		{
			mouseClick();
		}
		
		protected function mouseOver():void  {}
		
		protected function mouseOut():void {}
		
		protected function mouseClick():void {}
		
		
		//  GETTER SETTER FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function get useMouseEvents():Boolean
		{
			return _useMouseEvents;
		}
		
		public function set useMouseEvents(value:Boolean):void
		{
			this.mouseChildren = value;
			_useMouseEvents = value;
			
			if(value)
				addListeners()
			else
				removeListeners();
				
		}
		
		public function get localPosition():Point
		{
			if(_isInIso)				
				return overlay.globalToLocal(map.localToGlobal(_mapPosition));
			else
				return overlayContainer.globalToLocal(globalPosition);
		}	
		
		public function get mapPosition():Point
		{
			return map.globalToLocal(overlay.localToGlobal(new Point(x,y)));
		}	
		
	}
}