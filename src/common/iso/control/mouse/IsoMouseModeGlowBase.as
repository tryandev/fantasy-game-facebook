package common.iso.control.mouse
{
	import common.iso.view.display.IsoPlayerBuilding;
	import common.ui.view.tutorial.controller.TutorialController;
	
	import flash.events.EventDispatcher;

	public class IsoMouseModeGlowBase extends EventDispatcher
	{
		protected var _glowingBuildings:Array;
		
		protected var _paused:Boolean;
		
		public function IsoMouseModeGlowBase()
		{
			_glowingBuildings = [];
			_paused = false;
		}
		
		public function pause():void
		{
			_paused = true;
			
			var building:IsoPlayerBuilding;
			for each (building in _glowingBuildings)
			{
				building.highlight = false;
			}
		}
		
		public function resume():void
		{
			_paused = false;
			
			var building:IsoPlayerBuilding;
			for each (building in _glowingBuildings)
			{
				building.highlight = true;
			}
		}
		
		public function dispose():void
		{
			var building:IsoPlayerBuilding;
			for each (building in _glowingBuildings)
			{
				building.highlight = false;
			}
			
			_glowingBuildings = null;
		}
		
		protected function updateBuildingGlows():void
		{
			if (_paused) return;
			
			var building:IsoPlayerBuilding;
			var buildings:Array = getBuildingsInRange();
			var newGlow:Array = relativeComplement(_glowingBuildings, buildings);
			var noGlow:Array = relativeComplement(buildings, _glowingBuildings);
			
			for each (building in newGlow)
			{
				building.highlight = true;
			}
			
			for each (building in noGlow)
			{
				building.highlight = false;
			}
			
			_glowingBuildings = buildings;
		}
		
		protected function getBuildings():Array
		{
			return [];
		}
		
		protected function isBuildingInRange(building:IsoPlayerBuilding):Boolean
		{
			return false;
		}
		
		protected function getBuildingsInRange():Array
		{
			var buildings:Array = getBuildings();
			var buildingsInRange:Array = [];
			
			for each (var building:IsoPlayerBuilding in buildings)
			{
				if (isBuildingInRange(building)) buildingsInRange.push(building);
			}
			
			return buildingsInRange;
		}
		
		protected function isTutoriaBuildingInRange():Boolean
		{
			var buildings:Array = getBuildingsInRange();
			
			for each (var item:IsoPlayerBuilding in buildings)
			{
				if(item.tutorialDisplayObject == TutorialController.getInstance().currentFocusObject) return true;	
			}	
			
			return false;
		}	
		
		protected function isBuildingWithinRect(building:IsoPlayerBuilding, left:int, top:int, width:int, height:int):Boolean
		{
			var bx:int = building.isoX + (building.isoWidth / 2.0);
			var by:int = building.isoY + (building.isoLength / 2.0);
		
			if (bx < left || bx >= left + width)
				return false;
			
			if (by < top || by >= top + height)
				return false;
			
			return true;
		}
		
		/**
		 * 
		 * @param setA
		 * @param setB
		 * @return The elements in setB that are not also in setA
		 * 
		 */
		protected function relativeComplement(setA:Array, setB:Array):Array
		{
			var relComp:Array = [];
			
			for each (var obj:* in setB)
			{
				if (setA.indexOf(obj) == -1) relComp.push(obj);
			}
			
			return relComp;
		}
	}
}