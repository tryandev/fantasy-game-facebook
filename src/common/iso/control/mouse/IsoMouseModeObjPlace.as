package common.iso.control.mouse
{
	import as3isolib.core.IsoContainer;
	
	import com.raka.crimetown.business.command.building.BuyBuildingCommand;
	import com.raka.crimetown.business.command.purchase.BuyPropCommand;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.IStaticGameObject;
	import com.raka.crimetown.model.game.AreaBuilding;
	import com.raka.crimetown.model.game.Building;
	import com.raka.crimetown.model.game.Player;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.PlayerProp;
	import com.raka.crimetown.model.game.Prop;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.crimetown.util.sound.CTSoundsForHometown;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.proxy.ICommand;
	
	import common.iso.control.IsoController;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.containers.IsoWorld;
	import common.iso.view.display.IsoAreaBuilding;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoBuilding;
	import common.iso.view.display.IsoPlayerBuilding;
	import common.iso.view.display.IsoPlayerProp;
	import common.iso.view.display.IsoStationary;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.ui.view.tutorial.model.TutorialObjects;
	import common.util.StageRef;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;

	public class IsoMouseModeObjPlace extends IsoMouseModeGlowBase implements IIsoMouseMode {
		
		//public static const ON_OBJ_PLACED:String = 'onObjPlaced";'

		private var _inObj:IStaticGameObject;
		private var _client:IsoMap;
		private var _isoObj:IsoStationary;
		private var _addFail:Boolean; 
		private var _buyCommand:ICommand;
		private var _borderSize:int = 0;
		private var _objsBlocking:Array = [];
		
		public function IsoMouseModeObjPlace(inObj:IStaticGameObject) 
		{
			_inObj = inObj;	
			_borderSize = (inObj is Building || inObj is Prop) ? IsoWorld.BUILDING_PADDING:0;
		}
		
		public function init(map:IsoMap):void
		{
			var modelPlayerBuilding:PlayerBuilding;
			var modelPlayerProp:PlayerProp;
			_client = map;
			
			if (_inObj is Building) 
			{
				modelPlayerBuilding = new PlayerBuilding();
				modelPlayerBuilding.building = Building(_inObj);
				_isoObj = new IsoPlayerBuilding();
				IsoPlayerBuilding(_isoObj).model = modelPlayerBuilding;
				IsoPlayerBuilding(_isoObj).showCompletedBuildingGraphic();
				IsoPlayerBuilding(_isoObj).transparent(true);
				
				if(TutorialController.getInstance().active)
				{
					TutorialObjects.setObject(_isoObj, TutorialObjects.PLACE_BARRACKS, true);
				}
			}
			else if (_inObj is Prop) 
			{
				modelPlayerProp = new PlayerProp()
				var prop:Prop = Prop(_inObj);
				modelPlayerProp.prop_id = prop.id;
				modelPlayerProp.direction = 'SE';
				_isoObj = new IsoPlayerProp();
				IsoPlayerProp(_isoObj).model = modelPlayerProp;
				IsoPlayerProp(_isoObj).transparent(true);
			}
			else
			{
				return;
			}
			
			_client.addChildPreview(_isoObj);

			_client.addEventListener(Event.ENTER_FRAME, onMouseMove, false, 0, true);
			IsoController.gi.isoWorld.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			IsoController.gi.isoWorld.addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, true);
			IsoController.gi.isoWorld.overlay.addEventListener(MouseEvent.CLICK, onMouseUp, false, 0, true);
			onMouseMove(null);
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			if(_client)
			{
				_client.removeEventListener(Event.ENTER_FRAME, onMouseMove, false);
			}
			IsoController.gi.isoWorld.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp, false);
			IsoController.gi.isoWorld.removeEventListener(MouseEvent.CLICK, onMouseClick, false);
			IsoController.gi.isoWorld.overlay.removeEventListener(MouseEvent.CLICK, onMouseUp, false);
			if (_isoObj) {
				if (_isoObj is IsoPlayerBuilding) {
					if (IsoPlayerBuilding(_isoObj).model) {
						IsoPlayerBuilding(_isoObj).model = null;
					}
				}else if (_isoObj is IsoPlayerProp) {
					if (IsoPlayerProp(_isoObj).model) {
						IsoPlayerProp(_isoObj).model = null;
					}
				}
				_client.removeChildPreview(_isoObj);
				_isoObj.dispose();
				_isoObj = null;
			}			
			_inObj = null;
			_client = null;
			turnOffBlocking();
			_objsBlocking = null;
		}
		
		private function onMouseMove(e:Event = null):void {
			var newX:int, newY:int;
			newX = Math.round((_client.mouseY + 0.5 * _client.mouseX) / IsoBase.GRID_PIXEL_SIZE - (_isoObj.isoSize + 2*_borderSize)/2);
			newY = Math.round((_client.mouseY - 0.5 * _client.mouseX) / IsoBase.GRID_PIXEL_SIZE - (_isoObj.isoSize + 2*_borderSize)/2);
			if (newX < 0 + _borderSize) newX = 0 + _borderSize;
			if (newY < 0 + _borderSize) newY = 0 + _borderSize;
			if (newX + _isoObj.isoSize + _borderSize > _client.gridWidth)	newX = _client.gridWidth - _isoObj.isoSize - _borderSize ;
			if (newY + _isoObj.isoSize + _borderSize > _client.gridHeight)	newY = _client.gridHeight - _isoObj.isoSize - _borderSize ;
			if (_isoObj.isoX != newX || _isoObj.isoY != newY) {
				ExpansionController.instance.placeIsoObjInExpandedAreas(_isoObj, newX, newY, _borderSize);
				turnOffBlocking();
				var validPlace:Boolean = _client.addChildObjTest(_isoObj.isoX,_isoObj.isoY, _isoObj, _borderSize, _objsBlocking);
				_isoObj.drawPlacementFloor(validPlace, false, _borderSize);
				_client.sortBubble(_isoObj);
				turnOnBlocking();
			}
			
			if(TutorialController.getInstance().active)
			{
				TutorialController.getInstance().updatePositions();	
			}
			
			updateBuildingGlows();
		}
		
		private function onMouseUp(e:Event):void 
		{
			if (_client.addChildObjTest(_isoObj.isoX,_isoObj.isoY, _isoObj, _borderSize)) {
				
				trace('IsoMouseModePlaceObj place success');
				
				//_isoObj.model.iso_x = _isoObj.isoX;
				//_isoObj.model.iso_y = _isoObj.isoY;
				_isoObj.positionModel();
				
				_client.removeChildPreview(_isoObj);
				_isoObj.drawPlacementFloor(true, true);
				_isoObj.transparent(false);
				_client.addChildObj(_isoObj, _borderSize);
				_client.sortBubble(_isoObj);
				RakaSoundManager.getInstance().playSoundFX(CTSoundFx.PLACE_BUILDING);
				//e.stopImmediatePropagation();
				//e.stopPropagation();
				
				if (_isoObj is IsoPlayerBuilding) 
				{
					var building:IsoPlayerBuilding = IsoPlayerBuilding(_isoObj);
					
					
					
					_buyCommand = new BuyBuildingCommand(building.model);
					_buyCommand.execute();
					_isoObj = null;
					_inObj = null;
					this.exit();
				}
				else if (_isoObj is IsoPlayerProp) 
				{
					_buyCommand = new BuyPropCommand(IsoPlayerProp(_isoObj).model)
					_buyCommand.execute();
					var sameObj:IStaticGameObject = _inObj;
					_isoObj = null;
					_inObj = null;
					_client.mouseMode = new IsoMouseModeObjPlace(sameObj);
				}
				else
				{
					throw new Error("ERROR - Unknown buyCommand Obj type");
					return;
				}
			}
			else
			{
				trace('IsoMouseModePlaceObj place failed');				
			}
		}
		
		private function onMouseClick(e:Event):void 
		{
			e.stopImmediatePropagation();
			e.stopPropagation();
		}
		
		private function turnOffBlocking():void 
		{
			var blockingObj:IsoBase;
			while(_objsBlocking && _objsBlocking.length) 
			{
				blockingObj = _objsBlocking.pop();
				blockingObj.drawPlacementFloor(false, true);
				blockingObj.filters = null;
			}
		}
		
		private function turnOnBlocking():void 
		{
			var blockingObj:IsoBase;
			for each (blockingObj in _objsBlocking) 
			{
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
		
		public function exit():void 
		{
			_client.mouseMode = new IsoMouseModeLive();
			this.dispose();
		}
		
		override protected function getBuildings():Array
		{
			return _client.getPlayerBuildings();
		}
		
		override protected function isBuildingInRange(building:IsoPlayerBuilding):Boolean
		{
			var defenseBuilding:IsoPlayerBuilding = _isoObj as IsoPlayerBuilding;
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
