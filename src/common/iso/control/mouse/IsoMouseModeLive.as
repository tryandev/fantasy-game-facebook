package common.iso.control.mouse
{
	
	import com.raka.crimetown.control.GameController;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.ai.AStarNode;
	import common.iso.view.containers.BitmapLarge;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IMousableIso;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoState;
	import common.iso.view.display.IsoTile;
	import common.ui.view.overlay.BuildingFlagOverlay;
	import common.ui.view.overlay.MouseBlockerSprite;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.util.StageRef;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class IsoMouseModeLive extends IsoMouseModeExpansion implements IIsoMouseMode
	{
		private const MAX_PARENT_LEVEL_SEARCH:int = 6;
		private const MIN_IDLEMOUSE_UPDATE_INTERVAL:int = 15;
		
		private var _idleMouseFrameCount:int = 0;
		private var _lastMousePoint:Point;
		
		private var _hoverObj:IMousableIso = null;
		private var _lastMousableObj:IMousableIso;
		private var _clickMousePoint:Point;
		private var _isMouseDown:Boolean;
		private var _cancelWalkTile:Boolean;
		private var _isMouseClick:Boolean;
		private var _isPaused:Boolean;
		private var _mouseClickAnimation:IsoMouseClickAnimation;
		
		public function IsoMouseModeLive()
		{
			super();
			
			_isPaused = false;
			_lastMousePoint = new Point();
		}
		
		override public function init(map:IsoMap):void
		{
			super.init(map);
			
			_clickMousePoint = new Point();
			
			_mouseClickAnimation = new IsoMouseClickAnimation();
			_map.addOverlayItem(_mouseClickAnimation);
		}
		
		override public function pause():void
		{
			super.pause();
			
			_isPaused = true;
			
			if(_hoverObj)
			{
				_hoverObj.mouseOut();
			}
		}
		
		override public function resume():void
		{
			super.resume();
			
			_isPaused = false;
			
			if(_hoverObj)
			{
				_hoverObj.mouseOver();
			}
		}
		
		override public function dispose():void
		{
			_lastMousePoint = null;
			
			if (_mouseClickAnimation)
			{
				_mouseClickAnimation.dispose();
				if (_mouseClickAnimation.parent) _map.removeOverlayItem(_mouseClickAnimation);
				_mouseClickAnimation = null;
			}
			
			if (_hoverObj)
			{
				_hoverObj.mouseOut();
			}
			_hoverObj = null;
			
			super.dispose();
		}
		
		override protected function styleReticule(graphics:Graphics):void
		{
			graphics.beginFill(0x000000, 0.15);
		}
		
		override protected function get clickToExpandCursorFrame():String
		{
			return "notReady";
		}
		
		override protected function shouldShowReticule():Boolean
		{
			return ExpansionController.instance.shouldDrawExpansionCursorAt(_expX, _expY) && _canBuyExpansion && _hoverObj == null;
		}
		
		override protected function removeMouseEventListeners():void
		{
			super.removeMouseEventListeners();
			
			_map.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			IsoController.gi.isoWorld.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		override protected function addMouseEventListeners():void
		{
			super.addMouseEventListeners();
			
			_map.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			IsoController.gi.isoWorld.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		override protected function onMouseClick(event:MouseEvent):void
		{
			var avatar:IsoAvatar = IsoController.gi.isoWorld.isoMap.avatar;
			var map:IsoMap = IsoController.gi.isoWorld.isoMap;
			
			if (!avatar)
			{
				Log.warn(this, 'mouseClick cant walk, avatar = null');
				return;
			}
			
			if (avatar.isFighting)
			{
				Log.warn(this, 'mouseClick cant walk, avatar isFighting');
				return;
			}
			
			_mouseClickAnimation.click(event.stageX, event.stageY);
			
			var newX:int, newY:int;
			newX = (map.mouseY + 0.5 * map.mouseX) / IsoBase.GRID_PIXEL_SIZE;
			newY = (map.mouseY - 0.5 * map.mouseX) / IsoBase.GRID_PIXEL_SIZE;
			
			var tileGoal:IsoTile = map.getIsoTile(newX, newY);
			if (!tileGoal)
			{
				Log.warn(this, "Attempted to walk to null tile", newX, newY);
				return;
			}
			
			var nodeStart:AStarNode = new AStarNode(avatar.isoX, avatar.isoY);
			var nodeEnd:AStarNode = new AStarNode(newX, newY);
			
			if (tileGoal.isWalkable)
			{
				avatar.walkNodeGoal([nodeEnd]);
			}
			else
			{
				// this walks out of the unwalkable area in to walkable area to find the closest point that is not occupied
				nodeEnd = map.findClosestWalkableTile(nodeStart, nodeEnd);
				avatar.walkNodeGoal([nodeEnd]);
				Log.warn(this, "Player is walking to closest possible tile near target");
			}
		}
		
		
		override protected function onMouseMove(event:Event):void
		{
			super.onMouseMove(event);
			
			var map:IsoMap = IsoController.gi.isoWorld.isoMap;
			
			_isMouseClick = _isMouseClick && (map.mouseX == _clickMousePoint.x) && (map.mouseY == _clickMousePoint.y);
			
			if (_isMouseDown)
				return;
			
			// get point under mouse (_lastMousePoint not used for onEnterFrame version of this code)
			var newPoint:Point = new Point(_map.mouseX, _map.mouseY);
			if (newPoint.x == _lastMousePoint.x && newPoint.y == _lastMousePoint.y)
			{
				_idleMouseFrameCount++;
				if (_idleMouseFrameCount < MIN_IDLEMOUSE_UPDATE_INTERVAL) 
				{
					_idleMouseFrameCount++;
					return;
				}
			}
			
			_idleMouseFrameCount = 0;
			_lastMousePoint = newPoint;
			
			// get array of all display objects under mouse and reverse so topmost item is at index 0
			//var objsUnderPoint:Array = IsoController.gi.isoWorld.getObjectsUnderPoint(_client.localToGlobal(newPoint));
			var objsUnderPoint:Array = StageRef.stage.getObjectsUnderPoint(_map.localToGlobal(newPoint));
			objsUnderPoint.reverse();
			
			// stop items under mouse blocker from haveing mouse events.
			var stageObjects:Array = objsUnderPoint.slice(0,2);
			for each (var item:DisplayObject in stageObjects)
			{
				var stageObj:DisplayObject = item;
				
				while(stageObj && item is Sprite)
				{
					if(stageObj is MouseBlockerSprite) 
						return;	
					//trace("\t\t ------[ ", stageObj);
					stageObj = stageObj.parent;
				}
			}	
			
			// if we are over the same object as we were last check, fuhget about it
			/*if (objsUnderPoint[0] == _lastUnderPointObj){
				return;
			}else{
				_lastUnderPointObj = objsUnderPoint[0];
			}*/
			
			var counter:Number;
			
			for (var i:int = 0; i < objsUnderPoint.length; i++) 
			{
				var obj:DisplayObject = objsUnderPoint[i];
				//trace('objsUnderPoint[' + i + '] ' + obj.name + ' ' + obj);
				counter = 0;

				while(obj && counter < MAX_PARENT_LEVEL_SEARCH)
				{
					if(obj.name == IsoBase.IGNORE_MOUSE_DISPLAY || obj.name == IsoBase.IGNORE_GRAPHICS_DISPLAY ||  obj.name == 'art')
					{
						break;
					}
					else if (TutorialController.getInstance().active && obj != TutorialController.getInstance().currentFocusObject && TutorialController.getInstance().currentFocusObject is IsoBase)
					{
						// if tutorial is running hijack all clicks except ones on our focus object
						// do nothing
					}
					else if(obj is BuildingFlagOverlay && BuildingFlagOverlay(obj).isMouseOver)
					{
						if (_hoverObj != BuildingFlagOverlay(obj).iso)
						{
							if(_hoverObj)
								_hoverObj.mouseOut();
							
							_hoverObj = BuildingFlagOverlay(obj).iso;
							_hoverObj.mouseOver();
						}
						
						return;
					}
					else if (obj is IMousableIso)
					{
						if(obj != _hoverObj)
						{
							if (_hoverObj)
							{
								_hoverObj.mouseOut();
							}
							
							_hoverObj = obj as IMousableIso;
							if(_hoverObj is IsoState) 
							{
								if (IsoState(_hoverObj).mouseActive) 
								{
									_hoverObj.mouseOver();
								}
							}
							else
							{
								_hoverObj.mouseOver();
							}
						}
						return;
					}
					obj = obj.parent;
					counter++;
				}
			}
			
			if(_hoverObj) {
				_hoverObj.mouseOut();
				_hoverObj = null;
			}
		}
		
		private function mouseDown(e:Event = null):void 
		{
			_isMouseDown = true;
			_isMouseClick = true;
			_clickMousePoint.x = IsoController.gi.isoWorld.isoMap.mouseX;
			_clickMousePoint.y = IsoController.gi.isoWorld.isoMap.mouseY;
			
			// ensure the clicked object is the hoverObj
			// while this check seems redundant, it prevents potential errors
			if (_hoverObj){
				if (_hoverObj is IsoState) {
					if (IsoState(_hoverObj).mouseActive) {
						_hoverObj.mouseDown();	
					}
				}else{			
					_hoverObj.mouseDown();		
				}
			}
		}
		
		private function mouseUp(e:MouseEvent = null):void 
		{
			_isMouseDown = false;
			
			// check to make sure object is the hoverObj, in case the user dragged outside of
			// hoverObj before releasing mouse
			if (_hoverObj)
			{
				if (_hoverObj is IsoState)
				{
					if (IsoState(_hoverObj).mouseActive)
					{
						IsoState(_hoverObj).mouseUp();
						_cancelWalkTile = true;
					}
				}
				else
				{
					_hoverObj.mouseUp();
					_cancelWalkTile = true;
				}
			}
			else if (_isMouseClick && ExpansionController.instance.shouldListenForClicks)
			{
				ExpansionController.instance.handleMouseClick(e);
			}
		}
		
		public function mouseCancel():void
		{
			_isMouseDown = false;
		}
		
		public function releaseAvatar():void {
			_cancelWalkTile = false;
		}
	}
}
