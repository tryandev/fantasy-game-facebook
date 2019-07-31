package common.iso.view.display
{
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;

	public class IsoTile {
		private var _content:IsoBase;
		public var isoX:int;
		public var isoY:int;
		public var isWalkable:Boolean;
		private var _isExpansionTile:Boolean;
		//private var _paddingCount:int;
		
		public function IsoTile() {
			super();
		}

		public function get isExpansionTile():Boolean
		{
			refreshExpansionTileCalculation();
			return _isExpansionTile;
		}
		
		public function set content(value:IsoBase):void {
			_content = value;
		}
		
		public function get content():IsoBase {
			return _content;
		}
		
		public function dispose():void {
			_content = null; 
		}

		
		
		/*public function set paddingCount(value:int):void {
			_paddingCount = value;			
			//var special:String = (_paddingCount < 0 || _paddingCount > 1) ? 'special' : '';
			//trace('_paddingCount: \t' +  this.isoX + '\t' + this.isoY + " \t" + _paddingCount + " " + special);
		}
		
		public function get paddingCount():int {
			return _paddingCount;
		}*/

		public function get tilesAttached():Array {
			return null;
		}

		
		private function refreshExpansionTileCalculation():void
		{
			if(ExpansionController.instance.currentPlayerMap == null || ExpansionController.instance.currentPlayerMap.expansion_map == null) 
			{
				_isExpansionTile = true;
				return;
			}
						
			var expansions:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			var convertedX:int = Math.floor(isoX/expSize);
			var convertedY:int = Math.floor(isoY/expSize);
			
			if(expansions.length > convertedY)
			{
				if(expansions[convertedY].length > convertedX)
				{
					var expansion:int = expansions[convertedY][convertedX];
					
					if (expansion == GameObjectLookup.sharedGameProperties.expansion_owned)
					{
						_isExpansionTile = true;
						return;
					}
				}
			} 
			
			_isExpansionTile = false;
		}
		
		/*
		public function display():DisplayObject
		{
		var flooring:common.iso.model.flooring.IsoFlooring= IsoModel.gi.getIsoFlooring(this);
		if (flooring==null) return null;
	
		var displayObject:DisplayObject= IsoModel.gi.getFlooring(flooring.type);
		displayObject.x= x;
		displayObject.y= y;
		return displayObject;
		}
		 */
	}
}
