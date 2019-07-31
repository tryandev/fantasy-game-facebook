package common.iso.view.display
{
	import com.raka.crimetown.model.game.PlayerProp;
	
	import common.iso.control.IsoController;
	import common.iso.control.mouse.IsoMouseModeLive;
	import common.iso.model.IsoModel;
	
	import flash.filters.GlowFilter;

	public class IsoPlayerProp extends IsoProp
	{
		public function IsoPlayerProp()
		{
			super();
		}
		
		public function get model():PlayerProp
		{
			return _model as PlayerProp;
		}
		
		public function set model(value:PlayerProp):void {
			if(!value) return;
			_model = value as PlayerProp;
			if(!_initialized)
			{
				_initialized = true;
				positionIso(); //loadAsset(onAssetLoaded);
			}
			_cacheKey = getCacheKey(_model.cacheKey);
			_assetURL = getPropURL(_cacheKey);
			loadStationaryAsset(onAssetFailed);
		}	
		
		public function startPlacement():void
		{
			alpha = 0.5;
		}	
		
		public function finishPlacement():void {
			alpha = 1;
		}
		
		override protected function showHighlight(show:Boolean):void
		{
			if (!_assetDisplay) 
				return;
			
			if (show && !(IsoController.gi.isoWorld.isoMap.mouseMode is IsoMouseModeLive))
			{
					var filter:GlowFilter = IsoState.HOME_HIGHLIGHT_FILTER;
				
					_assetDisplay.filters = [filter];
			}
			else
				_assetDisplay.filters = [];
		}
	}
}