package common.iso.control.load {
	import com.raka.crimetown.model.game.AreaBuilding;
	import com.raka.crimetown.model.game.AreaProp;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.EnemyActive;
	import com.raka.crimetown.model.game.PlayerProp;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.iso.map.MapConfig;
	import com.raka.iso.objects.map.IPlayerAsset;
	import com.raka.iso.utils.cache.IMapObjectCache;
	import com.raka.iso.utils.cache.MapObjectCache;
	import com.raka.loader.RakaLoadImage;
	import com.raka.loader.RakaLoadPriorities;
	import com.raka.loader.RakaLoadService;
	import com.raka.loader.events.RakaLoadEvent;
	import com.raka.utils.logging.Log;
	
	import common.iso.view.display.IsoBase;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.getQualifiedClassName;
	import common.iso.model.IsoModel;

	/**
	 * @author ryantan
	 */
	public class LoaderAsset {
		/*
		//private static var _cache:IMapObjectCache = new MapObjectCache();
		//private static var _cacheEnabled:Boolean = true;
		
		private var _client:IsoBase;
		private var _loader:RakaLoadImage;
		private var _url:String;
		private var _cacheKey:String;
		private var _callback:Function;
		*/
		public function LoaderAsset(inModel:*):void {
		/*	var className:String = getQualifiedClassName(inModel).split('::')[1];
			//if (className == 'AreaBuilding' || className == 'PlayerBuilding') {
			if (inModel is AreaBuilding || inModel is PlayerBuilding) {
				_cacheKey = inModel.cacheKey + '_' + inModel.level + '_' + inModel.direction;
				_url = IsoModel.gi.getBuildingUrl(_cacheKey);
			}else if (inModel is AreaProp || inModel is PlayerProp) {
				_cacheKey = inModel.cacheKey + '_' + inModel.direction;
				_url = IsoModel.gi.getPropUrl(_cacheKey);
//				_url = MapConfig.getInstance().url('new_prop_assets_url').replace(MapConfig.PLACEHOLDER, _cacheKey);
			}///*else if (inModel is EnemyActive) {
			//	_cacheKey = GameObjectLookup.getEnemyById(inModel.enemy_id).base_cache_key;
			//	_url = MapConfig.getInstance().url("monster_assets_url").replace(MapConfig.PLACEHOLDER, _cacheKey);
			//}
			trace('className: ' + className + '\turl: ' + _url);*/
		}
		
		/*public function dispose():void {
			_client = null;
			_callback = null;
			
			// FIXME: Anybody: Get rid of this whole business
			if (!_loader) return;
			
			_loader.removeEventListener(RakaLoadEvent.LOAD_COMPLETE, onLoad);
			_loader.cancel();
			_loader.dispose();
			_loader = null;
		}
		
		public function start(inCallback:Function):void {
			_callback = inCallback;
			_loader = new RakaLoadImage(_url, RakaLoadPriorities.MAP_PRIORITY);
			_loader.addEventListener(RakaLoadEvent.LOAD_COMPLETE, onLoad);
			RakaLoadService.getInstance().load(_loader);
		}
		
		private function onLoad(loadEvent:RakaLoadEvent):void {
			
			_loader.removeEventListener(RakaLoadEvent.LOAD_COMPLETE, onLoad);
			//if (_cacheEnabled && _cache.contains(_cacheKey))
			//{
			//	///cloneFromCache();
			//	return;
			//}
			if (_callback == null) {
				return;
			}
			var classDef:Class = RakaLoadService.getInstance().getDomainClassDefinition(_url, _cacheKey);
			if (!classDef)
			{
				return;
			}
			var displayObject:DisplayObject = DisplayObject(new classDef());
			var grid:DisplayObject = DisplayObjectContainer(displayObject).getChildByName('grid');
			var art:DisplayObject = DisplayObjectContainer(displayObject).getChildByName('art');
			var hit:DisplayObject = DisplayObjectContainer(displayObject).getChildByName('isoHitArea');
			if (grid)  {
				if (art) {
					art.x -= grid.x;
					art.y -= grid.y;
				}
				if (hit) {
					hit.x -= grid.x;
					hit.y -= grid.y;
				}
				DisplayObjectContainer(displayObject).removeChild(grid);
			}
			_callback(displayObject);
		}*/
	}
}
