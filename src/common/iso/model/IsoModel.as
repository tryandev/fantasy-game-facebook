package common.iso.model
{

	import com.raka.crimetown.util.AppConfig;
	import com.raka.iso.map.MapConfig;
	import com.raka.loader.RakaLoadService;
	import com.raka.loader.cache.IRakaCacheManager;
	import com.raka.utils.Config;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.ai.MoverProjectile;
	import common.iso.model.flooring.IsoFlooring;
	import common.iso.model.flooring.IsoMapBackgroundTexture;
	import common.iso.model.projectile.Projectile;
	import common.iso.view.display.IsoTile;
	import common.util.FlashVars;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class IsoModel
	{
		private static const KEY_DELIMITER:String = ",";
		private static const GRID_INSTANCE_NAME:String = "grid";
		private static var _instance:IsoModel;
		
		public static function get gi():IsoModel
		{
			return _instance || (_instance = new IsoModel(new SE()));
		}

		public function IsoModel(se:SE)
		{
			se;
		}

		private var _avatarOutfitId:String = FlashVars.starting_avatar_outfit;
		private var _mapId:String = FlashVars.starting_area_name;
		private var _data:XML;
		private var _flooringList:Array = [];
		private var _flooringLookup:Dictionary = new Dictionary();
		private var _posters:Array = [];
		private var _gridHeight:int = 100;
		private var _gridWidth:int = 100;
		private var _tileSets:Array = [];
		private var _overlays:Array = [];
		private var _treeSpawns:Array = [];
		private var _treeSpawner:IsoTreeSpawner = new IsoTreeSpawner();
		private var _background:IsoMapBackgroundTexture;
		private var _viewport:IsoMapViewport;
		private var _projectiles:Object;
		private var _projectileDefault:Projectile;
		private var _avatarSpawn:Point;
		private var _camera:Point;
		
		public function getMappingKey(x:int, y:int):String
		{
			return x.toString() + KEY_DELIMITER + y.toString();
		}

		private function getUrl(pathKey:String, fileName:String):String
		{
			return MapConfig.getInstance().getValue(pathKey).replace(MapConfig.PLACEHOLDER, fileName);
		}

		public function getAvatarBodyUrl():String
		{
			// TODO: RKP: Get Avatar Body Url for load
			return "";
		}
		
		public function getMapUrl(id:String = null):String
		{
			id = id || _mapId;
			return getUrl("new_maps_url", id);
		}
		
		public function getProjectilesUrl(id:String = null):String
		{
			id = id || _mapId;
			return getUrl("projectiles_url", id);
		}
		
		public function getProjectileAssetsUrl(id:String = null):String
		{
			id = id || _mapId;
			return getUrl("projectile_assets_url", id);
		}
		
		public function getSoundsUrl(id:String = null):String
		{
			return getUrl("sound_assets_url", id);
		}
		
		public function getLoopingSoundsUrl(id:String = null):String
		{
			return getUrl("looping_sounds_assets_url", id);
		}

		public function getTilesetUrl(id:String = null):String
		{
			//			id = id || Grass.getRandom();
			return getUrl("new_tilesets_url", id);
		}
		
		public function getOverlayUrl(id:String = null):String
		{
			return getUrl("overlays_url", id);
		}
		
		public function getBackgroundUrl(id:String = null):String
		{
			return getUrl("backgrounds_url", id);
		}
		
		public function getPosterUrl(id:String = null):String
		{
			return getUrl("posters_url", id);
		}
		
		public function getBuildingUrl(id:String = null):String
		{
			return getUrl("new_building_assets_url", id);
		}

		public function getPropUrl(id:String = null):String
		{
			return getUrl("new_prop_assets_url", id);
		}

		public function getMonsterUrl(id:String = null):String
		{
			return getUrl("new_monster_assets_url", id);
		}

		public function getAvatarOutfitUrl(id:String = null):String
		{
			id = id || _avatarOutfitId;
			return getUrl("new_avatar_assets_url", id);
		}
		
		public function getUnitUrl(id:String = null, type:String = null):String
		{	
			return AppConfig.env.getValue(type + "_unit_assets_url").replace(Config.PLACEHOLDER, id);
		}	
		
		public function getCachedBitmap(url:String, newInstance:Boolean = false):Bitmap 
		{
			var cacheManager:IRakaCacheManager = RakaLoadService.getInstance().cacheManager;
			if (cacheManager.containsKey(url))
			{
				return cacheManager.get(url, newInstance);
			}
			else
			{
				Log.warn(this, 'Not found in cacheManager: ' + url);
			}
			return null;
		}
		
		public function hasCachedBitmap(url:String):Boolean
		{
			return RakaLoadService.getInstance().cacheManager.containsKey(url);
		}
		
		public function getCachedAsset(className:String, key:String = null):Class
		{
			var cacheManager:IRakaCacheManager = RakaLoadService.getInstance().cacheManager;

			if (cacheManager.hasDomainClassDefinition(key, className))
				return cacheManager.getDomainClassDefinition(key, className);
		
			if (cacheManager.hasClassDefinition(className))
				return cacheManager.getClassDefinition(className);

			Log.warn(this, "There is no asset for class name: " + className);

			return null;
		}
		
		public function hasCachedAsset(className:String, key:String = null):Boolean
		{
			var cacheManager:IRakaCacheManager = RakaLoadService.getInstance().cacheManager;
			
			if (cacheManager.hasDomainClassDefinition(key, className))
				return true;
			
			if (cacheManager.hasClassDefinition(className))
				return true;
			
			return false;
		}

		public function getFlooring(id:String):DisplayObject
		{
			var Klass:Class;

			if (RakaLoadService.getInstance().hasClassDefinition(id))
			{
				Klass = RakaLoadService.getInstance().getClassDefinition(id);
			}
			else
			{
				Klass = Sprite;

				trace("No Class Definition found for: " + id);
			}

			var dob:DisplayObject = new Klass() as DisplayObject;
			var grid:DisplayObject = DisplayObjectContainer(dob).getChildByName(GRID_INSTANCE_NAME);

			if (grid != null)
			{
				DisplayObjectContainer(dob).removeChild(grid);
			}

			return dob;
		}
		
		public function hasFlooring(id:String):Boolean
		{
			return RakaLoadService.getInstance().hasClassDefinition(id);
		}
		
		public function getFlooringList():Array
		{
			return _flooringList.concat();
		}

		public function getIsoFlooring(key:*):IsoFlooring
		{
			var tile:IsoTile = key as IsoTile;

			key = getMappingKey(tile.isoX, tile.isoY);

			return _flooringLookup[key];
		}
		
		public function getProjectile(inCacheKey:String):Projectile 
		{
			var projectile:Projectile =  Projectile(_projectiles[inCacheKey]);
			if (projectile)  {
				return projectile.clone();
			}else{
				Log.error(this, "Projectile cachekey not found: '" + inCacheKey + "'");
				var projectileDefault:Projectile = _projectileDefault.clone();
				projectileDefault.parent = null;
				projectileDefault.failedSWF = true;
				projectileDefault.drawDefaultMCs(true);
				return projectileDefault;
			}
			return null;
		}
		
		public function get gridHeight():int
		{
			return _gridHeight;
		}

		public function get gridWidth():int
		{
			return _gridWidth;
		}
		
		public function get avatarSpawnPoint():Point
		{
			return _avatarSpawn;
		}
		
		public function get cameraPosition():Point
		{
			return _camera;
		}

		public function setAvatarOutfitId(id:String):void
		{
			_avatarOutfitId = id;
		}
		
		public function setProjectilesData(data:*):void
		{
			updateProjectilesData(data);
		}

		public function setMapData(data:*):void
		{
			updateMapData(data);
		}

		public function setMapId(id:String):void
		{
			_mapId = id;
		}

		public function get tileSets():Array
		{
			return _tileSets.slice(0);
		}
		
		public function get overlays():Array
		{
			return _overlays;
		}
		
		public function get background():IsoMapBackgroundTexture
		{
			return _background;
		}
		
		public function get viewport():IsoMapViewport
		{
			return _viewport;
		}
		
		public function get posters():Array
		{
			return _posters;
		}
		
		public function get treeSpawner():IsoTreeSpawner
		{
			return _treeSpawner;
		}
		
		public function preloadProjectiles():void
		{
			for each (var projectile:Projectile in _projectiles)
			{
				// preload projectile assets
				projectile.loadAssets(onPreloadProjectileSuccess, onPreloadProjectileFail);
			}		
		}	
		
		private function updateProjectilesData(xml:XML):void
		{
			_projectiles = new Object();
			_data = xml;
			var node:XML;
			var projectile:Projectile;
			var motionName:String;
			for each (node in _data..Projectile)
			{
				projectile = new Projectile();
				projectile.cacheKey		= node.@cachekey;
				projectile.name 		= node.@name;
				projectile.swf 			= node.@swf;
				projectile.maxRange		= node.@maxrange;
				projectile.shake		= node.@shake;
				projectile.offsetX 		= node.@offsetx;
				projectile.offsetY 		= node.@offsety;
				projectile.speed 		= node.@speed;
				projectile.soundSpawn 	= node.@soundspawn;
				projectile.soundFly 	= node.@soundfly;
				projectile.soundHit 	= node.@soundhit;
				motionName 				= node.@motion;
				if (motionName == 'curve') projectile.motion = MoverProjectile.MOTIONSTYLE_CURVE;
				if (motionName == 'straight') projectile.motion = MoverProjectile.MOTIONSTYLE_STRAIGHT;
				if (motionName == 'drop') projectile.motion = MoverProjectile.MOTIONSTYLE_DROP;
				_projectiles[node.@cachekey] = projectile;
				if (_projectileDefault == null) {
					_projectileDefault = projectile.clone();
				}
			}
		}
		
		private function onPreloadProjectileSuccess(projectile:Projectile):void
		{
			Log.info(this, "Projectile loaded: "+ projectile);
		}
		
		private function onPreloadProjectileFail(projectile:Projectile):void
		{
			Log.error(this, "Failed to load projectile: "+ projectile);
		}
		
		private function updateMapData(xml:XML):void
		{
			_data = xml;
			
			_avatarSpawn = new Point(_data.Avatar.@x, _data.Avatar.@y);
			
			_camera = new Point(_data.Camera.@x, _data.Camera.@y);
			
			_gridWidth = _data.@width;
			_gridHeight = _data.@height;
			
			_tileSets = parseTilesets(_data);
			_overlays = parseOverlays(_data);
			_background = parseBackground(_data);
			
			_viewport = null;
			if (_data.ViewPort[0])
			{
				_viewport = new IsoMapViewport();
				_viewport.topLeft.x = _data.ViewPort.GridPoint[0].@x;
				_viewport.topLeft.y = _data.ViewPort.GridPoint[0].@y;
				
				_viewport.bottomRight.x = _data.ViewPort.GridPoint[1].@x;
				_viewport.bottomRight.y = _data.ViewPort.GridPoint[1].@y;
			}
			
			// Clear out old list
			_flooringList.splice(0);
			_flooringLookup = new Dictionary();
			
			var flooringData:XML;
			var isoFlooring:IsoFlooring;
			var id:String;
			var xPos:int;
			var yPos:int;
			
			for each (flooringData in _data..Flooring)
			{
				xPos = flooringData.@x;
				yPos = flooringData.@y;
				id = getMappingKey(xPos, yPos);
				
				isoFlooring = _flooringLookup[id] ? _flooringLookup[id] : (_flooringLookup[id] = new IsoFlooring());
				
				isoFlooring.populate(id, xPos, yPos, flooringData.@type, flooringData.@tileset);
				
				_flooringList.push(isoFlooring);
			}
			
			_posters = [];
			
			var posterData:XML;
			var poster:IsoPoster;
			
			for each (posterData in _data..Poster)
			{
				poster = new IsoPoster();
				poster.populate(posterData.@image, posterData.@index, posterData.@x, posterData.@y, posterData.@scale);
				
				_posters.push(poster);
			}
			
			_posters.sortOn("index", Array.NUMERIC);
			
			_treeSpawns = [];
			
			var treeSpawnData:XML;
			var treeSpawn:IsoTreeSpawn;
			
			for each (treeSpawnData in _data..Tree)
			{
				treeSpawn = new IsoTreeSpawn();
				treeSpawn.image = treeSpawnData.@image;
				treeSpawn.ymin = treeSpawnData.@ymin;
				treeSpawn.ymax = treeSpawnData.@ymax;
				treeSpawn.yminSelectionWeight = treeSpawnData.@ymin_selection_weight;
				treeSpawn.ymaxSelectionWeight = treeSpawnData.@ymax_selection_weight;
				
				_treeSpawns.push(treeSpawn);
			}
			
			_treeSpawner.density = _data.Trees.@density;
			_treeSpawner.spawns = _treeSpawns;
		}
		
		public function parseTilesets(data:XML):Array
		{
			var tilesets:Array = [];
			var tilesetKeys:String = String(_data.@tileset);
			if (tilesetKeys)
				tilesets = tilesetKeys.split(",");
			
			return tilesets;
		}
		
		public function parseOverlays(data:XML):Array
		{
			var overlays:Array = [];
			var overlayData:XML;
			var overlay:IsoMapBackgroundTexture;
			
			for each (overlayData in _data..Overlay)
			{
				overlay = new IsoMapBackgroundTexture(overlayData.@type, overlayData.@index, overlayData.@density);
				overlays.push(overlay);
			}
			
			overlays.sortOn("index", Array.NUMERIC);
			return overlays;
		}
		
		public function parseBackground(data:XML):IsoMapBackgroundTexture
		{
			return new IsoMapBackgroundTexture(String(_data.@background), 0, 0);
		}
	}
}

internal class SE
{
}
