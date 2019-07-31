package common.iso.control.mouse {
	import com.raka.crimetown.business.command.MoveBuildingCommand;
	import com.raka.crimetown.business.command.MovePropCommand;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.proxy.ICommand;
	
	import common.iso.control.IsoController;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.containers.IsoWorld;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoPlayerBuilding;
	import common.iso.view.display.IsoPlayerProp;
	import common.iso.view.display.IsoState;
	import common.iso.view.display.IsoStationary;
	import common.ui.view.overlay.MouseBlockerSprite;
	import common.util.StageRef;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	
	public class IsoMouseModeObjMove extends IsoMouseModeGlowBase implements IIsoMouseMode {
		private static const MOUSE_ICON_X_OFFSET : Number = 2;
		private static const MOUSE_ICON_Y_OFFSET : Number = 2;
		
		private const MIN_IDLEMOUSE_UPDATE_INTERVAL:int = 60;
		
		private var _idleMouseFrameCount:int = 0;
		private var _lastMousePoint:Point;
		
		private var _map:IsoMap;
		protected var _hoverObj:IsoStationary;
		private var _lastHoverObj:*;
		private var _isMouseDown:Boolean;
		
		private var _targetObj:IsoStationary;
		
		private var _targetSavedIsoX:int;
		private var _targetSavedIsoY:int;
		
		private var _icon:DisplayObject;
		
		private var _commandMove:ICommand;
		private var _borderSize:int;
		
		private var _oldX:int = -1;
		private var _oldY:int = -1;
		
		private var _objsBlocking:Array = [];
		
		public function IsoMouseModeObjMove()
		{
			_lastMousePoint = new Point();
		}
		
		public function init(map:IsoMap):void
		{
			_map = map;
			addMouseEvents();
			addIcon();
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			if (_targetObj) {
				// if there is a targetobj, that means it wasn't placed, restore original iso position
				_targetObj.isoX = _targetSavedIsoX;
				_targetObj.isoY = _targetSavedIsoY;
				if (_targetObj is IsoPlayerBuilding) 
				{
					IsoPlayerBuilding(_targetObj).updateOverylay();
				}
				_targetObj.transparent(false);
				_targetObj.drawPlacementFloor(true, true);
				_map.sortBubble(_targetObj);
				_targetObj = null;
			}
			StageRef.stage.removeEventListener(MouseEvent.MOUSE_MOVE, iconFollowMouse, false);
			StageRef.stage.removeEventListener(Event.MOUSE_LEAVE, mouseLeaveStage, false);
			_map.removeEventListener(Event.ENTER_FRAME, mouseMove, false);
			_map.removeEventListener(MouseEvent.CLICK, mouseClick, false);
			IsoController.gi.isoWorld.overlay.removeEventListener(MouseEvent.CLICK, mouseClick, false);
			_map = null;
			if (_hoverObj) {
				highlightObj(_hoverObj, false);
				_hoverObj = null;
			}
			_lastHoverObj = null;
			icon = null;
			turnOffBlocking();
			_objsBlocking = null;
		}
		
		protected function addIcon():void {
			icon = new DlgBtnMove();
		}
		
		public function iconFollowMouse(e:MouseEvent = null):void {
			_icon.visible = true;
			if (_icon && _icon.parent) {
				_icon.x = e.stageX + MOUSE_ICON_X_OFFSET;
				_icon.y = e.stageY + MOUSE_ICON_Y_OFFSET;
			}
		}
		
		private function mouseLeaveStage(e:Event):void {
			if (_icon) _icon.visible = false;
		}
		
 		private function addMouseEvents(e:Event = null):void
		{
			StageRef.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeaveStage, false, 0, true);
			StageRef.stage.addEventListener(MouseEvent.MOUSE_MOVE, iconFollowMouse, false, 0, true);
			_map.addEventListener(Event.ENTER_FRAME, mouseMove, false, 0, true);
			_map.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
			IsoController.gi.isoWorld.overlay.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
		}
		private function mouseUp(e:MouseEvent = null):void {
			e.stopPropagation();
			e.stopImmediatePropagation();
		}
		protected function mouseClick(e:Event = null):void 
		{
			//trace(this + ' mouseClick - ' + e.target);
			
			if (!_targetObj && _hoverObj) {
				// Pick up the obj here, and begin following the mouse
				//trace('IsoMouseModeMoveObj: pickUp');
				_targetObj = _hoverObj;
				_borderSize = (_targetObj is IsoStationary) ? IsoWorld.BUILDING_PADDING:0;
				_targetSavedIsoX = _targetObj.isoX;
				_targetSavedIsoY = _targetObj.isoY;
				highlightObj(_targetObj, false);
				_targetObj.transparent(true);
				followMove(true);
				
				RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUTTON_CLICK);
			}
			else if (_targetObj)
			{
				if (_map.addChildObjTest(_targetObj.isoX,_targetObj.isoY, _targetObj, _borderSize)) {
					_map.tilesDetach(_targetObj, _targetSavedIsoX, _targetSavedIsoY);
					_map.tilesAttach(_targetObj, -1,-1, _borderSize);
					_targetObj.transparent(false);
					_targetObj.drawPlacementFloor(true, true);
					_targetObj.positionModel();
					
					// TODO - alk - how to handle failure?
					if (_hoverObj is IsoPlayerBuilding) {
						var targetIsoPB:IsoPlayerBuilding = IsoPlayerBuilding(_targetObj);
						RakaSoundManager.getInstance().playSoundFX(CTSoundFx.PLACE_BUILDING);
						targetIsoPB.updateOverylay();
						_commandMove = new MoveBuildingCommand(targetIsoPB.model);
						_commandMove.execute();
					}else if (_hoverObj is IsoPlayerProp) {
						var targetIsoPP:IsoPlayerProp = IsoPlayerProp(_targetObj);
						RakaSoundManager.getInstance().playSoundFX(CTSoundFx.PLACE_BUILDING);
						//targetIsoPP.updateOverylay();
						_commandMove = new MovePropCommand(targetIsoPP.model);
						_commandMove.execute();
					}
					
					_targetObj = null;
					_hoverObj = null;
					_lastHoverObj = null;
				}
			}
		}
		
		private function followMove(inForceDraw:Boolean = false):void {
			//trace('IsoMouseModeMoveObj: followMove ' + inForceDraw);
			if (!_targetObj) return;
			var newX:int, newY:int;
			newX = Math.round((_map.mouseY + 0.5 * _map.mouseX) / IsoBase.GRID_PIXEL_SIZE - (_targetObj.isoSize + 2*_borderSize)/2);
			newY = Math.round((_map.mouseY - 0.5 * _map.mouseX) / IsoBase.GRID_PIXEL_SIZE - (_targetObj.isoSize + 2*_borderSize)/2);
			if (newX < 0 + _borderSize) newX = 0 + _borderSize;
			if (newY < 0 + _borderSize) newY = 0 + _borderSize;
			if (newX + _targetObj.isoSize + _borderSize > _map.gridWidth)	newX = _map.gridWidth - _targetObj.isoSize - _borderSize;
			if (newY + _targetObj.isoSize + _borderSize > _map.gridHeight)	newY = _map.gridHeight - _targetObj.isoSize - _borderSize;
			
			if (newX == _oldX && newY == _oldY && !inForceDraw) {
				return;
			}
			_oldX = newX;
			_oldY = newY;
			
			if (_targetObj.isoX != newX || _targetObj.isoY != newY || inForceDraw) {
				ExpansionController.instance.placeIsoObjInExpandedAreas(_targetObj, newX, newY, _borderSize);			
				if (_targetObj is IsoPlayerBuilding) {
					IsoPlayerBuilding(_targetObj).updateOverylay();
				}
				turnOffBlocking();
				var validPlace:Boolean = _map.addChildObjTest(_targetObj.isoX,_targetObj.isoY, _targetObj, _borderSize, _objsBlocking);
				//trace('IsoMouseModeMoveObj: drawPlacementFloor');
				_targetObj.drawPlacementFloor(validPlace, false, _borderSize);
				_map.sortBubble(_targetObj);
				turnOnBlocking();
			}
		}
		
		private function turnOffBlocking():void {
			var blockingObj:IsoBase;
			while(_objsBlocking.length) {
				blockingObj = _objsBlocking.pop();
				blockingObj.drawPlacementFloor(false, true);
				blockingObj.filters = null;
			}
		}
		
		private function turnOnBlocking():void {
			var blockingObj:IsoBase;
			for each (blockingObj in _objsBlocking) {
				blockingObj.drawPlacementFloor(false, false, 0, true);
				blockingObj.filters = [
					new ColorMatrixFilter(
						new Array(
							0.5, 0.0, 0.0, 0, 128,
							0.0, 0.5, 0.0, 0, 0,
							0.0, 0.0, 0.5, 0, 0,
							0.0, 0.0, 0.0, 1, 0
						)
					)
				];
			}
		}
		
		private function mouseMove(e:Event = null):void
		{
			if (_targetObj)
			{
				followMove();
				updateBuildingGlows();
				return;
			}
			else
			{
				updateBuildingGlows();
			}
			
			if (_isMouseDown)
				return;
			
			// get point under mouse
			var newPoint:Point = new Point(_map.mouseX, _map.mouseY);
			if (newPoint.x == _lastMousePoint.x && newPoint.y == _lastMousePoint.y) {
				_idleMouseFrameCount++;
				if (_idleMouseFrameCount < MIN_IDLEMOUSE_UPDATE_INTERVAL) {
					_idleMouseFrameCount++;
					return;
				}
			}
			
			_idleMouseFrameCount = 0;
			_lastMousePoint = newPoint;
			
			// get array of all display objects under mouse and reverse so topmost item is at index 0
			var objsUnderPoint:Array = StageRef.stage.getObjectsUnderPoint(_map.localToGlobal(newPoint));
			objsUnderPoint.reverse();
			
			// stop items under mouse blocker from haveing mouse events.
			var stageObjects:Array = objsUnderPoint.slice(0,2);
			for each (var item:DisplayObject in stageObjects)
			{
				var stageObj:DisplayObject = item;
				
				while(stageObj && item is Sprite)
				{
					if(stageObj is MouseBlockerSprite) return;	
					//trace("\t\t ------[ ", stageObj);
					stageObj = stageObj.parent;
				}
			}	
			
			// if we are over the same object as we were last check, fuhget about it
			/*if (objsUnderPoint[0] == _lastHoverObj)
				return;
			
			_lastHoverObj = objsUnderPoint[0];*/
			
			// if previous hover object, mouse out.
			if(_hoverObj)
			{
				highlightObj(_hoverObj, false);
				_hoverObj = null;
			}
			
			for each (var obj:DisplayObject in objsUnderPoint)
			{
				var counter:Number = 0;
				var ignore:Boolean = false;
				while(obj && !(obj is IsoStationary) && counter++ < 4) {
					if(obj.name == IsoBase.IGNORE_MOUSE_DISPLAY || obj.name == 'art')
						ignore = true;
					obj = obj.parent;
				}
				
				if ((obj is IsoStationary) && !ignore) {
					_hoverObj = IsoStationary(obj);
					highlightObj(_hoverObj, true);
					break;
				}
			}
		}
		
		private function highlightObj(inObj:IsoStationary, inToggle:Boolean):void {
			inObj.filters = inToggle ? [IsoState.HOME_HIGHLIGHT_FILTER]:[];
			//inObj.filters = inToggle ? [new GlowFilter(0xFF8000, 1, 8, 8, 8, BitmapFilterQuality.HIGH)]:[];
		}
		
		protected function set icon(value:DisplayObject):void {
			if (_icon && _icon.parent) {
				_icon.parent.removeChild(_icon);
			}
			_icon = value;
			if (_icon) {
				StageRef.stage.addChild(_icon);
				_icon.x = StageRef.stage.mouseX + MOUSE_ICON_X_OFFSET;
				_icon.y = StageRef.stage.mouseY + MOUSE_ICON_Y_OFFSET;
			}
		}
		
		protected function get icon():DisplayObject {
			return _icon;
		}
		
		override protected function getBuildings():Array
		{
			return _map.getPlayerBuildings();
		}
		
		override protected function isBuildingInRange(building:IsoPlayerBuilding):Boolean
		{
			var defenseBuilding:IsoPlayerBuilding = _targetObj as IsoPlayerBuilding;
			if (!(defenseBuilding && defenseBuilding.isDefenseBuilding)) return false;
			
			if (building == defenseBuilding) return false;
			
			var bx:int = building.isoX + (building.isoWidth / 2.0);
			var by:int = building.isoY + (building.isoLength / 2.0);
			
			var left:int = defenseBuilding.isoX - defenseBuilding.defenseWidth / 2 + 1;
			var top:int  = defenseBuilding.isoY - defenseBuilding.defenseLength / 2 + 1;
			
			return isBuildingWithinRect(building, left, top, defenseBuilding.defenseWidth + 1, defenseBuilding.defenseLength + 1);
		}
	}
}
