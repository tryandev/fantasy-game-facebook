package common.iso.view.display
{
	import com.raka.crimetown.model.game.AreaProp;
	
	import common.iso.model.IsoModel;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	public class IsoAreaProp extends IsoProp
	{
		public function IsoAreaProp()
		{
			super();
		}
		
		public function get model():AreaProp
		{
			return _model as AreaProp;
		}
		
		public function set model(value:AreaProp):void {
			if(!value) return;
			_model = value as AreaProp;
			if(!_initialized)
			{
				_initialized = true;
				positionIso();
			}
			_cacheKey = getCacheKey(_model.cacheKey);
			_assetURL = getPropURL(_cacheKey);
			loadStationaryAsset(onAssetFailed);
		}	
		
		protected override function showHighlight(show:Boolean):void
		{
			return;
		}
		
		protected override function positionAsset(asset:DisplayObject):void {
			super.positionAsset(asset);
			var assetDOC:DisplayObjectContainer = DisplayObjectContainer(asset);
			if (!assetDOC) return;
			var hit:Sprite = Sprite(assetDOC.getChildByName('isoHitArea'));
			if (hit) {
				hit.numChildren && hit.removeChildAt(0);
				assetDOC.removeChild(hit); 
			}
		}
	}
}