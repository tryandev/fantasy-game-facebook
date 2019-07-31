package common.iso.view.display
{
	import com.raka.crimetown.business.command.building.RepairNeighborBuildingCommand;
	import com.raka.crimetown.control.GameController;
	import com.raka.crimetown.model.game.AttackResult;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.PlayerBuildingStateChangeEvent;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	
	import common.ui.view.overlay.BuildingFlagOverlay;
	
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	public class IsoNeighborBuilding extends IsoPlayerBuilding 
	{
		public static const NEIGHBOR_HIGHLIGHT_COLOR:int = 0x33f40b;
		public static const NEIGHBOR_HIGHLIGHT_FILTER:GlowFilter = new GlowFilter(NEIGHBOR_HIGHLIGHT_COLOR, 1, 8, 8, 8, BitmapFilterQuality.HIGH);
		
		private var _lootDropperId:int;
		
		
		public function IsoNeighborBuilding()
		{
			super();
			_highlightColor = NEIGHBOR_HIGHLIGHT_COLOR;
		}
		
		override protected function initializeOverlay():void
		{
			// dont initialize overlay because we dont want to show it
		}
		
		override protected function onModelStateChange(event:PlayerBuildingStateChangeEvent=null):void
		{
			
			switch (model.state)
			{
				case PlayerBuilding.CONSTRUCTING:
				case PlayerBuilding.UPGRADING:
				case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
					showUnderConstructionGraphic();
					break;
				
				case PlayerBuilding.REPAIRING:
					showUnderConstructionGraphic();
					showRepairingProgressBar();
					setBuildingData("", "Repairing...", model.repairTimePeriod.start, model.repairTimePeriod.end);
					break;
				
				case PlayerBuilding.DESTROYED:
				case PlayerBuilding.WAITING_TO_REPAIR:
					showDestroyedGraphic();
					showWaitingToRepair(BuildingFlagOverlay.REPAIR_NEIGHBOR);
					setBuildingData("Click to Repair");
					break;
				
				default:
					hideOverlays();
					showCompletedBuildingGraphic();
					break;
			}
		}
		
		override public function startRepairing(isReparingAll:Boolean=false):void
		{
			super.startRepairing();
			
			GameObjectLookup.sharedGameProperties.neighbor_repair_energy_reward;
			
			var result:AttackResult = new AttackResult();
			result.energy_payout = GameObjectLookup.sharedGameProperties.neighbor_repair_energy_reward;
			
			if(!_lootDropperId)
			{
				_lootDropperId = GameController.getInstance().lootDropManager.createLootDropper(this);
			}
			
			GameController.getInstance().lootDropManager.startDroppingLoot(_lootDropperId, result);
		}
		
		override public function mouseUp():void 
		{
			switch(model.state)
			{
				case PlayerBuilding.DESTROYED:
				case PlayerBuilding.WAITING_TO_REPAIR:
					repair();
					break;
			}
		}
		
		override protected function repair():void
		{
			new RepairNeighborBuildingCommand(model).execute();
		}
		
		override protected function showWaitingToRepair(flagType:String):void
		{
			hideOverlays();
			
			if(model.canRepair)
				super.showWaitingToRepair(flagType);
		}	
		
		override protected function showHighlight(show:Boolean):void
		{	
			Mouse.cursor = MouseCursor.ARROW;
			
			if (show && canInteract)
			{
				_assetDisplay.filters = [IsoState.HOME_HIGHLIGHT_FILTER];
				
				Mouse.cursor = MouseCursor.BUTTON;
				
				updateOverlayData();
				
				if (_flag) 
					_flag.show();
			}
			else
			{	
				if (_assetDisplay)
					_assetDisplay.filters = [];
				if (_flag)
					_flag.hide();
			}
		}
		
		public function appearDestroyed():void
		{
			model.state = PlayerBuilding.DESTROYED;
		}
		
		public function get isAttackable():Boolean
		{
			return false;
		}

		public function setDestination(destX:int, destY:int):void
		{
			trace("IsoNeighborBuilding does not acknowledge setDestnation calls");
		}
		
		private function get canInteract():Boolean
		{
			switch(model.state)
			{
				case PlayerBuilding.DESTROYED:
				case PlayerBuilding.WAITING_TO_REPAIR:
					return true;
					break;
			}
			
			return false;
		}	
	}
}
