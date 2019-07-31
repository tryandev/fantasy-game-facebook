package common.iso.view.display
{
	
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.media.sound.RakaSoundManager;
	
	import common.iso.model.IsoModel;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	
	/**
	 *	Abstract class for all game buildings. Class can load a single asset, or a main and destroyed asset
	 * 	depending on whether or not the model has a destroyed_base_cache_key.
	 */	
	
	public class IsoBuilding extends IsoStationary implements IIsoBase
	{
		
		protected var _cacheKeyDestroyed:String;
		protected var _assetDestroyedURL:String;
		
		//protected var _assetFullDisplay:DisplayObject;
		//protected var _assetDestroyedDisplay:DisplayObject;
		
		protected var _useKey:String;
		
		private const TIME_TO_DESTROY:int = 1; // in seconds
		
		public function IsoBuilding()
		{
			super();
		}
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		//  PUBLIC FUNCTIONS
		// -----------------------------------------------------------------//
		public function destroyBuilding(animate:Boolean = true):void
		{
			loadAsset(onAssetLoaded, onAssetFailed);
			RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUILDING_DESTROYED);
		}	
		
		public function rebuildBuilding(animate:Boolean = true):void
		{
			loadAsset(onAssetLoaded, onAssetFailed);
		}	
		
		//  PRIVATE FUNCTIONS
		// -----------------------------------------------------------------//
		
		protected override function loadAsset(onSuccess:Function = null, onFailure:Function = null):void
		{
			positionIso();
			
			_cacheKey = getCacheKey(_model.cacheKey);
			_cacheKeyDestroyed = getCacheKey(_model.destroyCacheKey);
			
			// TODO: 
			if (this.isAlive)
				_useKey = _cacheKey;
			else
				_useKey = _cacheKeyDestroyed;
			
			_assetURL = getBuildingURL(_useKey);
			
			//tr(this, "building assets ", _cacheKeyDestroyed);
			//tr(this, "building assets ", _cacheKey);
			
			super.loadAsset(onSuccess, onFailure);
		}	
		
		/**
		 *	Building assets have completed loading.
		 */	
		protected override function onAssetLoaded():void
		{
			super.onAssetLoaded();
			onLoadBuildingComplete();
		}
		
		protected override function onAssetFailed():void
		{
			super.onAssetFailed();
		}
		
		protected function onLoadBuildingComplete():void
		{
			// override
		}	
		
		//  PRIVATE FUNCTIONS
		// -----------------------------------------------------------------//
		private function onBuildingDestroyed():void
		{
			//_assetFullDisplay.visible = false;
			//_assetFullDisplay.alpha = 1;
		}	
		
		private function onRebuildComplete():void
		{
			//_assetDestroyedDisplay.visible = false;
		}	
		
		//  HELPER FUNCTIONS
		// -----------------------------------------------------------------//
		
		protected function getBuildingURL(value:String):String
		{
			return IsoModel.gi.getBuildingUrl(value);
		}	
		
		protected function getCacheKey(value:String):String
		{
			if(value.toLowerCase().indexOf('destroy') == 0)
			{
				return value
			}
			
			return value + '_' + _model.level + '_' + _model.direction;
		}	
		
		protected function getConstructionCacheKey():String
		{
			return 'Construction'+_model.iso_height+"x"+_model.iso_width+"_"+_model.level + '_SE';
		}
		
		protected function getDestroyedCacheKey():String
		{
			return 'Destroyed'+_model.iso_width+"x"+_model.iso_width+"_"+_model.level + '_SE';
		}
		
		protected override function getAssetInstance():DisplayObject
		{
			return getClassInstance(isAlive ? _cacheKey : _cacheKeyDestroyed, _assetURL);
		}
	}
}
