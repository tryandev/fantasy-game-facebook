package common.iso.view.display
{
	import common.iso.model.IsoModel;

	public class IsoProp extends IsoStationary implements IIsoBase
	{
		public function IsoProp()
		{
			super();
		}
		
		protected function getPropURL(value:String):String
		{
			return IsoModel.gi.getPropUrl(value);
		}	
		
		protected function getCacheKey(value:String):String
		{
			return value + '_' + _model.direction;
		}	
		
		protected override function loadAsset(onSuccess:Function = null, onFailure:Function = null):void
		{
			positionIso();
			_cacheKey = getCacheKey(_model.cacheKey);
			_assetURL = getPropURL(_cacheKey);
			//tr(this, "prop assets ", _cacheKey);
			super.loadAsset(onSuccess, onFailure);
		}	
	}
}