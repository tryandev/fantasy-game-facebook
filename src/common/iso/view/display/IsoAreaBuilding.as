package common.iso.view.display
{
	import com.raka.crimetown.business.command.enemy.SelectEnemyCommand;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.AreaBuilding;
	import com.raka.crimetown.model.game.Building;
	import com.raka.crimetown.model.game.BuildingActive;
	import com.raka.crimetown.model.game.EnemyRequirement;
	import com.raka.crimetown.model.game.Player;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	
	import common.iso.model.EnemyOverlayVO;
	import common.ui.view.overlay.EnemyNameAndHealth;
	import common.ui.view.overlay.EnemyOverlay;
	import common.ui.view.overlay.GoalArrowOverlay;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;

	public class IsoAreaBuilding extends IsoBuilding implements IAttackableIso, IIsoGoal
	{
		private const NAME_PADDING:Number = 30;
		
		private var _nameOverlay:EnemyNameAndHealth;
		private var _overlay:EnemyOverlay;
		private var _overlayData:EnemyOverlayVO;
		private var _goalArrowOverlay:GoalArrowOverlay;
		private var _queueCount:int = 0;
		
		public function IsoAreaBuilding()
		{
			super();
		}
		
		public override function dispose():void {
			super.dispose();
			if (_goalArrowOverlay){
				_goalArrowOverlay.dispose();
				_goalArrowOverlay = null;
			}
			if (_nameOverlay) {
				_nameOverlay.dispose();
			}
			if (_overlay) {
				_overlay.dispose();
			}
			_overlayData = null;
		}

		private function addTooltip():void
		{
			
			_nameOverlay = new EnemyNameAndHealth();
			
			// TODO: TJ - 	This shoud change based on elite status.
			_overlay = new EnemyOverlay(EnemyOverlay.STANDARD_OVERLAY);
			_overlayData = new EnemyOverlayVO();
		}
		
		override protected function onLoadBuildingComplete():void
		{	
			
			addUI(_nameOverlay);
			updateNamePostition();
			updateGoalArrowPostition();
		}
		
		private function updateNamePostition():void
		{
			if(_nameOverlay)
			{
				_nameOverlay.x = _assetDisplay.x;
				_nameOverlay.y = -(_gridShift.y) - _nameOverlay.height - NAME_PADDING;
			}
			
		}
			
		private function updateGoalArrowPostition():void
		{
			if(_goalArrowOverlay)
				_goalArrowOverlay.setMapPosition(new Point(this.x, mapOverlayPostion.y - NAME_PADDING * 3));
		}	
		
		// ISOSTATE OVERRIDES
		// -----------------------------------------------------------------//
		override protected function showHighlight(show:Boolean):void
		{
			super.showHighlight(show);
			
			if(model.player_building_active.isInjured)
				_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
			else
				_nameOverlay.state = EnemyNameAndHealth.NAME;
			
			if (show)
			{	
				_overlay.setMapPosition(mapOverlayPostion);
				_overlay.show();
				_nameOverlay.hide();
			}
			else{
				_overlay.hide();
				_nameOverlay.show();
			}
		}	
		
		override protected function showJobActive(show:Boolean):void
		{
			if (show || model.player_building_active.isInjured)
				_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
			else 
				_nameOverlay.state = EnemyNameAndHealth.NAME;
		}
		
		override public function mouseUp():void
		{
			if(isAlive) 
				new SelectEnemyCommand(this).execute();
		}
		
		//  GETTERS & SETTERS
		// -----------------------------------------------------------------//
		
		public function get model():AreaBuilding
		{
			return _model as AreaBuilding;
		}
		
		public function set model(value:AreaBuilding):void
		{
			_model = value as AreaBuilding;
			
			if(!_initialized)
			{
				_initialized = true;
				
				addTooltip();

				updateStats();

				loadAsset(onAssetLoaded, onAssetFailed);		
			}
		}
		
		public function get tooltipData():EnemyOverlayVO
		{
			return _overlayData;
		}
		
		protected override function placeHolderColor():int
		{
			if (!this.isAlive) 
			{
				return 0xAA5555;
			}
			return 0xFFAAAA;
		}
		
		//  IAttackableIso FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function updateStats():void
		{
			if (model && model.isInjured)
				_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
			else
				_nameOverlay.state = EnemyNameAndHealth.NAME;
			
			_overlayData.name = model.building.name;
			_overlayData.type = "Building"; //value.building.type; 		// TODO VC: change this to 'type' after Jim adds to data
			_overlayData.health = model.health;
			_overlayData.maxHealth = model.max_health;
			_overlayData.energyCost = model.building.energy_cost;
			_overlayData.queueCount = queueCount;
			
			_overlay.data = _overlayData;
			_nameOverlay.data = _overlayData;
		}	
		
		public function handleAttackResult(result:Object):void
		{
			this.model.player_building_active = result.building_active as BuildingActive
			updateStats();
		}

		override public function get isAlive():Boolean
		{
			return model.isAlive;
		}
		
		public function get energyPerAttack():Number
		{
			return model.building.energy_cost;
		}
		
		public function reset():void
		{
			model.reset();
			rebuildBuilding();
			updateStats();
			goalArrowShow(true);
		}
		
		public function spawn():void
		{
			reset();
		}	
		
		public function kill():void
		{
			goalArrowShow(false);
			destroyBuilding();
		}	
		
		public function get queueCount():int
		{
			return _queueCount;
		}
		
		public function set queueCount(value:int):void
		{
			_queueCount = value;
			updateStats();
		}
		
		public function get respawnTime():Number
		{
			return model.player_building_active.respawnTime;
		}
		
		public function set respawnTime(value:Number):void
		{
			model.player_building_active.respawnTime = value;
		}
		
		public function get resetTime():Number
		{
			return model.player_building_active.resetTime;
		}
		
		public function get requirements():Array
		{
			var reqs:Array = [];
			for each (var req:EnemyRequirement in model.player_building_active.generated_requirements)
			{
				if (req.requirement_fulfill_id && req.requirement_fulfill_id != 0)
					reqs.push(req);
			}	
			
			return reqs;
		}

		public function areRequirementsMet():Boolean
		{
			var player:Player = GameObjectManager.player;
			for each (var req:EnemyRequirement in requirements)
			{
				if (req.getMissingQuantity(player) > 0) return false;
			}
			return true;
		}
		
		public function goalArrowEnable(value:Boolean):void {
			if (!value && _goalArrowOverlay) {
				_goalArrowOverlay.dispose();
				_goalArrowOverlay = null;
			}else if (value && !_goalArrowOverlay) {
				_goalArrowOverlay = new GoalArrowOverlay();
				updateGoalArrowPostition();
			}
		}
		
		public function goalArrowShow(value:Boolean):void {
			if (!_goalArrowOverlay) {
				return; //goalArrowEnable(true);
			}
			
			if (value && isAlive) {
				_goalArrowOverlay.show();
				updateGoalArrowPostition()
			}else{
				_goalArrowOverlay.hide();
			}
		}

	}
}
