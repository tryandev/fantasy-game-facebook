package common.iso.control.mouse
{
	import common.iso.control.IsoController;
	import common.iso.view.display.IsoPlayerBuilding;

	public class IsoMouseBuildingHelper extends IsoMouseModeGlowBase
	{
		private var _building:IsoPlayerBuilding;
		public function IsoMouseBuildingHelper(building:IsoPlayerBuilding)
		{
			super();
			
			_building = building
		}
		
		public function addGlows():void
		{
			updateBuildingGlows();
		}	
		
		public function removeGlows():void
		{
			dispose();
		}	
		
		override protected function getBuildings():Array
		{
			return IsoController.gi.isoWorld.isoMap.getPlayerBuildings();
		}
		
		override protected function isBuildingInRange(building:IsoPlayerBuilding):Boolean
		{

			if (!(_building && _building.isDefenseBuilding)) return false;
			
			if (building == _building) return false;
			
			var bx:int = building.isoX + (building.isoWidth / 2.0);
			var by:int = building.isoY + (building.isoLength / 2.0);
			
			var left:int = _building.isoX - _building.defenseWidth / 2 + 1;
			var top:int  = _building.isoY - _building.defenseLength / 2 + 1;
			
			return isBuildingWithinRect(building, left, top, _building.defenseWidth + 1, _building.defenseLength + 1);
		}
		
		
	}
}