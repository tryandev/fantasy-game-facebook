package common.iso.view.containers
{
	import com.funzio.ka.KingdomAgeMain;
	import com.greensock.TweenLite;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.Building;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.PlayerProp;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.crimetown.view.hud.menu.HudMenu;
	import com.raka.crimetown.view.popup.PopupEvent;
	import com.raka.crimetown.view.popup.PopupManager;
	import com.raka.iso.map.events.MapEvent;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.IsoControllerFight;
	import common.iso.control.ai.AStar;
	import common.iso.control.ai.AStarNode;
	import common.iso.control.ai.MoverHomeAndFriendTownNPC;
	import common.iso.control.mouse.IIsoMouseMode;
	import common.iso.control.mouse.IsoMouseModeLive;
	import common.iso.control.mouse.IsoMouseModeRival;
	import common.iso.model.IsoMapViewport;
	import common.iso.model.IsoModel;
	import common.iso.view.containers.background.IsoMapBackgroundRenderer;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoBuilding;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoFPCAvatar;
	import common.iso.view.display.IsoMonster;
	import common.iso.view.display.IsoPlayerBuilding;
	import common.iso.view.display.IsoPlayerProp;
	import common.iso.view.display.IsoProp;
	import common.iso.view.display.IsoRivalBuilding;
	import common.iso.view.display.IsoStationary;
	import common.iso.view.display.IsoTile;
	import common.util.StageRef;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ka.control.ControllerHud;
	import ka.control.ControllerViewContainers;
	
	public class IsoMap extends Sprite
	{
		public static const DEFAULT_COLOR:int = 0x6F793B;
		public static var VIEWPORT_WIDTH:int = 5120;
		public static var VIEWPORT_HEIGHT:int = 3072;
		
		public static const VERTICAL_PADDING:int = 500;
		public static const HORIZONTAL_PADDING:int = 200;
		
		private static const MIN_SORT_FRAMES:int = 3;
		
		// sorting vars
		private var _sortPending:Boolean;
		private var _framesSinceSort:int;
		private var _projectiles:Sprite;
		
		private var _objects:Sprite;
		private var _fog:IsoFog;
		private var _tileOverlay:Sprite;
		private var _background:BitmapLarge;
		private var _renderer:IsoMapBackgroundRenderer;
		private var _overlay:Sprite;
		
		private var _viewport:IsoMapViewport;
		
		// isoobj and tile references
		private var _objArray:Array;
		private var _grid:Array;
		// size of map
		private var _gridWidth:int;
		private var _gridHeight:int;
		// mouse event vars
		private var _isoMouseMode:IIsoMouseMode;
		private var _pauseCount:int;
		private var _mouseModePausers:Dictionary;
		
		private var _characterPools:Dictionary;
		private var _avatar:IsoAvatar;
		private var _flagsWalkable:String;
		private var _npcs:Array = [];
		
		private var _isPlayerMap:Boolean;
		
		public function IsoMap(inWidth:int, inHeight:int, inFlags:String = '')
		{
			_flagsWalkable = inFlags;
			_isPlayerMap = (ExpansionController.instance.currentPlayerMap != null);
			
			if (_isPlayerMap)
			{
				var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
				var expansions:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
				
				if (expansions != null)
				{
					_gridWidth = expansions[0].length * expSize;
					_gridHeight = expansions.length * expSize;
				}
				else
				{
					// if there is no expansion map, just make the map the same size as the player map 
					var playerExpansions:Array = GameObjectLookup.player_map.expansion_map;
					_gridWidth = playerExpansions[0].length * expSize;
					_gridHeight = playerExpansions.length * expSize;
					
					_isPlayerMap = false;
				}
			}
			else if (GameObjectManager.area.isNpcArea)
			{
				_gridWidth = IsoModel.gi.gridWidth;
				_gridHeight = IsoModel.gi.gridHeight;
			}
			else
			{
				_gridWidth = inWidth;
				_gridHeight = inHeight;
			}
			
			_tileOverlay = new Sprite(); 	//_tileOverlay.visible = false;
			_objects = new Sprite();
			_projectiles = new Sprite();
			_overlay = new Sprite();
			
			_objArray = [];
			_grid = [];
			
			_characterPools = new Dictionary();
			
			initViewport();
			var viewRect:Rectangle = getMapRect();
			_background = new BitmapLarge(viewRect.width, viewRect.height, false, DEFAULT_COLOR);
			_background.x = viewRect.x;
			_background.y = viewRect.y;
			
			VIEWPORT_WIDTH = viewRect.width;
			VIEWPORT_HEIGHT = viewRect.height;
			
			_renderer = new IsoMapBackgroundRenderer(_background);
			
			_mouseModePausers = new Dictionary();
			
			addChild(_background);
			createFog();
			drawFogVector();
			addChild(_tileOverlay);
			addChild(_objects);
			addChild(_projectiles);
			addChild(_overlay);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			PopupManager.instance.addEventListener(PopupEvent.OPEN, onPopupOpened);
			PopupManager.instance.addEventListener(PopupEvent.CLOSE, onPopupClosed);
			
			_objects.mouseChildren = false;
			_objects.mouseEnabled = false;
			
			_tileOverlay.mouseChildren = false;
			_tileOverlay.mouseEnabled = false;
			
			_overlay.mouseChildren = false;
			_overlay.mouseEnabled = false;
			
			makeTiles();
			drawBackground();
		}
		
		public function init():void
		{
			initCameraPosition();
		}
		
		protected function initViewport():void
		{
			switch(GameObjectManager.areaType)
			{
				case GameObjectManager.AREA_TYPE_NEIGHBOR:
					_viewport = null;
					break;
				
				case GameObjectManager.AREA_TYPE_RIVAL:
					_viewport = generateExpansionMapSizedViewport();
					break;
				
				case GameObjectManager.AREA_TYPE_HOMETOWN:
					_viewport = null;
					break;
				
				default:
					_viewport = IsoModel.gi.viewport;
					break;
			}
		}
		
		public function generateExpansionMapSizedViewport():IsoMapViewport
		{
			var viewport:IsoMapViewport = new IsoMapViewport();
			
			// the edges of the viewport in relative screenspace
			var top:Number = Number.MAX_VALUE;
			var left:Number = Number.MAX_VALUE;
			var bottom:Number = Number.MIN_VALUE;
			var right:Number = Number.MIN_VALUE;
			
			var t:int;
			
			var expansions:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			
			if (expansions == null) return null;
			
			for (var iy:int = 0; iy < expansions.length; iy++)
			{
				for (var ix:int = 0; ix < expansions[iy].length; ix++)
				{
					var expansion:int = expansions[iy][ix];
					
					if (expansion == GameObjectLookup.sharedGameProperties.expansion_owned)
					{
						t = (ix + iy);
						if (t < top) top = t;
						if (t > bottom) bottom = t;
						
						t = (ix - iy);
						if (t < left) left = t;
						if (t > right) right = t;
					}
				}
			}
			
			bottom += 2;
			left -= 1;
			right += 1;
			
			// converting relative screenspace to tile coords
			viewport.topLeft.x = expSize * (top + left) / 2;
			viewport.topLeft.y = expSize * (top - left) / 2;
			
			viewport.bottomRight.x = expSize * (bottom + right) / 2;
			viewport.bottomRight.y = expSize * (bottom - right) / 2;
			
			viewport.padding = 150;
			viewport.bottomPadding = 250;
			
			return viewport;
		}
		
		protected function initCameraPosition():void
		{
			var cameraPosition:Point = IsoModel.gi.cameraPosition;
			var hasCameraPosition:Boolean = cameraPosition && !isNaN(cameraPosition.x) && !isNaN(cameraPosition.y);
			
			if (GameObjectManager.areaType == GameObjectManager.AREA_TYPE_NPC && hasCameraPosition)
			{
				x = -cameraPosition.x;
				y = -cameraPosition.y;
			}
			else
			{
				var rect:Rectangle;
				
				if (GameObjectManager.area.isPlayerArea) rect = generateExpansionMapSizedViewport().calculatePixelViewport(0, 0);
				else rect = getViewRect();
				
				x = -rect.x - rect.width/2;
				y = -rect.y - rect.height/2;
			}
		}
		
		public function getMapRect():Rectangle
		{
			return (GameObjectManager.area.isNpcArea) ? getViewRect() : getMapSizedViewRect();
		}
		
		public function getViewRect():Rectangle
		{
			var rect:Rectangle;
			
			if (_viewport)
			{
				rect = _viewport.calculatePixelViewport(x, y);
			}
			else
			{
				rect = getMapSizedViewRect();
			}
			
			return rect;
		}
		
		public function getMapSizedViewRect():Rectangle
		{
			// this hack is to ensure there is enough room on the map for pvp in areas that have the leftmost expansion
			// otherwise there isn't enough map to battle on
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			var needsExtraHorizontal:Boolean = GameObjectManager.areaType == GameObjectManager.AREA_TYPE_RIVAL && ExpansionController.instance.hasBoughtExpansion(0, ExpansionController.instance.expansionMapSize - 1);
			var extraHorizontal:Number = needsExtraHorizontal ? 3 * expSize * IsoBase.GRID_PIXEL_SIZE : 0;
			
			var rect:Rectangle = new Rectangle();
			rect.width = (_gridWidth + _gridHeight) * IsoBase.GRID_PIXEL_SIZE + HORIZONTAL_PADDING * 2 + extraHorizontal;
			rect.height = (_gridWidth + _gridHeight) * IsoBase.GRID_PIXEL_SIZE / 2 + VERTICAL_PADDING * 2;
			
			rect.width = Math.max(rect.width, VIEWPORT_WIDTH);
			rect.height = Math.max(rect.height, VIEWPORT_HEIGHT);
			
			rect.x = x - rect.width/2;
			rect.y = y - VERTICAL_PADDING;
			
			return rect;
		}
		
		public function drawBackground():void
		{
			_background.init();
			_renderer.init(GameObjectManager.area.isNpcArea);
		}
		
		public function updateExpansion(expX:int, expY:int):void
		{
			drawFogVector();
			
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;

			var rect:Rectangle = new Rectangle();
			var padding:int = 120;
			rect.width = 2 * IsoBase.GRID_PIXEL_SIZE * expSize + 2 * padding;
			rect.height = IsoBase.GRID_PIXEL_SIZE * expSize + 2 * padding;
			rect.x = IsoBase.GRID_PIXEL_SIZE * expSize * (expX - expY - 1)+ _background.width/2 - padding;
			rect.y = IsoBase.GRID_PIXEL_SIZE * expSize * (expX + expY) / 2 + VERTICAL_PADDING - padding;
			
			_renderer.redrawRect(rect);
		}
		
		private function createFog():void
		{
			if (_isPlayerMap)
			{
				_fog = new IsoFog(_background);
				addChild(_fog);
			}
		}
		
		public function fogExpandPrebake(inX:int, inY:int):void 
		{
			_fog && _fog.bakeExpand(inX, inY);
		}
			
		public function drawFogVector():void
		{
			_fog && _fog.drawFogVector();
		}
		
		private function drawFogBake():void
		{
			_fog && _fog.drawFogBake();
		}
		
		private function onPopupOpened(e:PopupEvent):void
		{
			pauseMouseMode(e.popup);
		}
		
		private function onPopupClosed(e:PopupEvent):void
		{
			resumeMouseMode(e.popup);
		}
		
		public function dispose():void
		{
			var obj:IsoBase;
			var i:int, j:int;
			var tile:IsoTile;
			
			if (_isoMouseMode) {
				_isoMouseMode.dispose();
				_isoMouseMode = null;
			}
			
			for (i = 0; i < _objArray.length; ++i) {
				obj = _objArray[i];
				obj.dispose();
				_objArray[i] = null;
			}
			
			
			for (i = 0; i < _gridWidth; ++i) {
				for (j = 0; j < _gridHeight; ++j) {
					tile = _grid[i][j];
					tile.dispose();
					_grid[i][j] = null;
				}
			}
			_grid = null;
			
			// delete pools
			for (var key:Object in _characterPools) {
				_characterPools[key] = null;
				delete _characterPools[key]
			}
			
			_characterPools = null;
			
			while (_tileOverlay.numChildren)
				_tileOverlay.removeChildAt(0);
			
			removeChild(_tileOverlay);
			_tileOverlay = null;
			
			while (_objects.numChildren)
				removeChildObj(_objects.getChildAt(0) as IsoBase, false);
			
			removeChild(_objects);
			_objects = null;
			
			while (_overlay.numChildren)
				removeOverlayItem(_overlay.getChildAt(0) as Sprite);
			
			removeChild(_overlay);
			_overlay = null;
			
			while (_projectiles.numChildren)
				_projectiles.removeChildAt(0);
			
			removeChild(_projectiles);
			_projectiles = null;
			
			_objArray = null;
			_npcs = null;
			
			if (_fog) {
				_fog.parent && removeChild(_fog);
				_fog.dispose();
				_fog = null;
			}
			
			if (_renderer) {
				_renderer.dispose();
				_renderer = null;
			}
			
			//this.removeEventListener(Event.ADDED_TO_STAGE, onAddStage, false);
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
			
			PopupManager.instance.removeEventListener(PopupEvent.OPEN, onPopupOpened);
			PopupManager.instance.removeEventListener(PopupEvent.CLOSE, onPopupClosed);
		}
		
		public function avatarReset():void {
			if (!_avatar) {
				//trace('|||||||||||| avatar change: NO AVATAR');
				return;
			}
			
			if (IsoControllerFight.isBusy) {
				IsoAvatar.changePending = true;
				//trace('|||||||||||| avatar change: AVATAR IS BUSY');
				return;
			}
			
			//trace('|||||||||||| avatar change: CHANGING AVATAR');
			
			var modelIsoX:Number = _avatar.isoX;
			var modelIsoY:Number = _avatar.isoY;
			
			removeChildObj(_avatar);
			_avatar.dispose();
			
			_avatar = new IsoAvatar(GameObjectManager.player.playerOutfit, GameObjectManager.player.playerSettings.show_armor);
			_avatar.isoX = modelIsoX;
			_avatar.isoY = modelIsoY;
			addChildObj(_avatar);
			_avatar.initialize(true);
			
			sort();
		}
		
		/*	public function addFloatingTooltip(view:FloatingTooltip):void
		{
		overlay.addChild(view);
		}	
		
		public function removeFloatingTooltip(view:FloatingTooltip):void
		{
		
		}	*/
		
		public function addOverlayItem(item:DisplayObject):DisplayObject
		{
			return _overlay.addChild(item);
		}
		
		public function getCenterIsoPoint():Point
		{
			var center:Point = new Point(StageRef.stage.stageWidth / 2, StageRef.stage.stageHeight / 2);
			center = globalToLocal(center);
			center = localPixelToIso(center.x, center.y);
			
			return center;
		}
		
		public function removeOverlayItem(item:Sprite):void
		{
			try{
				_overlay.removeChild(item);
			} catch(e:Error){
				Log.warn(this, "Can not remove tooltip "+ item);
			}	
		}
		
		public function addTileOverlayItem(item:DisplayObject):DisplayObject
		{
			var returnVal:DisplayObject = _tileOverlay.addChild(item) as DisplayObject;
			_tileOverlay.visible = true;
			return returnVal;
		}	
		
		public function removeTileOverlayItem(item:DisplayObject):void
		{
			try{
				_tileOverlay.removeChild(item);
				if (!_tileOverlay.numChildren) {
					_tileOverlay.visible = false;
				}
			} catch(e:Error){
				Log.warn(this, "Can not remove tile overlay item: "+ item);
			}	
		}	
		
		/*	public function get overlay():Sprite
		{
		return _overlay;
		}
		
		public function set overlay(value:Sprite):void
		{
		_overlay = value;
		}*/
		
		/*public function get hoverObject():IsoBase
		{
			return _hoverObject;
		}*/
		
		public function get gridWidth():int
		{
			return _gridWidth;
		}
		
		public function get gridHeight():int
		{
			return _gridHeight;
		}
		
		public function hideFog(duration:Number = 0):void
		{
			TweenLite.to(_fog, duration, {alpha: 0});
		}
		
		public function showFog(duration:Number = 0):void
		{
			TweenLite.to(_fog, duration, {alpha: 1});
		}
		
		private function makeTiles():void {
			var i:int;
			var flagsWalkable:Array = _flagsWalkable.split(',');
			var walkableIndex:int;
			
			for (i = 0; i < _gridWidth; ++i)
			{
				_grid[i] = [];
				var j:int;
				for (j = 0; j < _gridHeight; ++j)
				{
					walkableIndex = i * _gridHeight + j;
					var tileWalkable:Boolean = !(walkableIndex < flagsWalkable.length && flagsWalkable[walkableIndex] == '0');
					tileMake(i, j, tileWalkable);
				}
			}
		}
		
		public function tileMake(inX:int, inY:int, inWalkable:Boolean = true):void
		{
			var tile:IsoTile = new IsoTile();
			tile.isoX = inX;
			tile.isoY = inY;
			tile.isWalkable = inWalkable;
			_grid[inX][inY] = tile;
		}
		
		public function sort():void
		{
			_sortPending = true;
		}
		
		protected function onEnterFrame(e:Event):void
		{
			sortPendingDo();
		}
		
		private function sortPendingDo(e:Event = null):void
		{
			if (_sortPending)
			{
				if (_framesSinceSort == 0)
				{
					_framesSinceSort = MIN_SORT_FRAMES;
					_sortPending = false;
					sort2();
				}
				else
				{
					_framesSinceSort--;
				}
			}
		}
		
		private function sort2():void
		{
			// trace('sort2() ' + Math.random());
			
			// var startTime:int = getTimer();
			
			// for (var j:int = 0; j < 45; j++) {
			_objArray.sortOn("sortY", Array.NUMERIC | Array.DESCENDING);
			var max:int = _objArray.length;
			var i:int = 0;
			
			for (i; i < max; ++i)
			{
				_objects.addChildAt(_objArray[i], 0);
			}
			// }
			
			// trace('sort time: ' + (getTimer() - startTime));
		}
		
		public function sortBubble(isoObj:IsoBase):void
		{
			while (1)
			{
				var myIndex:int = _objects.getChildIndex(isoObj);
				var prevObj:IsoBase = (myIndex == 0) ? 							null : _objects.getChildAt(myIndex - 1) as IsoBase;
				var nextObj:IsoBase = (myIndex == _objects.numChildren - 1) ? 	null : _objects.getChildAt(myIndex + 1) as IsoBase;
				
				if (nextObj && nextObj.sortY < isoObj.sortY)
				{
					_objects.swapChildren(isoObj, nextObj);
				}
				else if (prevObj && prevObj.sortY > isoObj.sortY)
				{
					_objects.swapChildren(isoObj, prevObj);
				}
				else
				{
					break;
				}
			}
			// trace('bubble time: ' + (getTimer() - startTime));
		}
		
		public function addProjectile(inProjectile:Sprite):void {
			_projectiles.addChild(inProjectile);
		}
		
		public function addChildObj(value:IsoBase, inBorderSize:int = 0):void
		{
			if (value.occupy)
				tilesAttach(value, -1, -1, inBorderSize);
			_objArray.push(value);
			_objects.addChildAt(value, 0);
			IsoController.gi.isoWorld.dispatchEvent(new MapEvent(MapEvent.OBJECT_ADDED, value));
		}
		
		public function removeAllNPCs():void
		{
			if(_npcs == null) return;
			
			while(_npcs.length > 0)
			{
				removeChildObj(_npcs[_npcs.length-1]);
				_npcs.pop();
			}
		}
		
		public function addAvatarNPC(avatar:IsoFPCAvatar):void
		{
			_npcs.push(avatar);
			addChildObj(avatar);
		}
		
		public function showNPCs():void
		{
			for(var i:int; i < _npcs.length; i++)
			{
				MoverHomeAndFriendTownNPC(IsoFPCAvatar(_npcs[i]).mover()).togglePause(true)
				IsoFPCAvatar(_npcs[i]).visible = true;
			}
		}
		
		public function hideNPCs():void
		{
			for(var i:int; i < _npcs.length; i++)
			{
				MoverHomeAndFriendTownNPC(IsoFPCAvatar(_npcs[i]).mover()).togglePause(false);
				IsoFPCAvatar(_npcs[i]).visible = false;
			}
		}
		
		public function startBattle():void
		{
			hideNPCs();
			hideFog(0.15);
			
			_renderer.pause();
		}
		
		public function endBattle():void
		{
			showNPCs();
			showFog(0.15);
			
			_renderer.resume();
		}
		
		public function addChildPreview(value:IsoBase):void
		{
			_objects.addChildAt(value, 0);
			//_objArray.push(value);
		}
		public function removeChildPreview(value:IsoBase):void
		{
			_objects.removeChild(value);
			//_objArray.push(value);
		}
		
		public function addChildRandomLocation(iso:IsoBase, inBorderSize:int = 0):void
		{
			
			for (var attempts:int = 0; attempts <= 500; attempts++)
			{
				iso.isoX = Math.round(Math.random() * this.gridWidth);
				iso.isoY = Math.round(Math.random() * this.gridHeight);
				if (this.addChildObjTest(iso.isoX, iso.isoY, iso, inBorderSize)) {
					this.addChildObj(iso);
					return;
				}
			}
			iso.isoX = Math.round(Math.random() * 50);
			iso.isoY = Math.round(Math.random() * 50);
			this.addChildObj(iso);
		}
		
		public function removeChildObj(value:IsoBase, notify:Boolean = true):void
		{
			if (value.occupy)
				tilesDetach(value);
			
			for (var i:int = 0; i < _objArray.length; i++)
			{
				if (_objArray[i] == value)
				{
					_objArray.splice(i, 1);
					break;
				}
			}
			
			_objects.removeChild(value);
			value.dispose();
			
			if(notify)
			{
				IsoController.gi.isoWorld.dispatchEvent(new MapEvent(MapEvent.OBJECT_REMOVED, value));	
			}
			
		}
		
		public function hasIsoObject(iso:IsoBase):Boolean
		{
			return _objArray.indexOf(iso) > -1;
		}	
		
		/**
		 *	Remove an iso character form the map and store it in 
		 * 	an object pool.
		 */	
		public function poolCharacter(iso:IsoCharacter, ClassRef:Class):void
		{
			iso.isoX = -1;
			iso.isoY = -1;
			iso.alpha = 1;
			
			if (!_characterPools[ClassRef])
				_characterPools[ClassRef] = [];
			
			_characterPools[ClassRef].push(removeChildObj(iso as IsoBase));
			
		}
		
		/**
		 *	Get a pre instantiated iso from a pool for a certain class.
		 */	
		public function getCharacterFromPool(ClassRef:Class):IsoCharacter
		{
			if (_characterPools[ClassRef] && _characterPools[ClassRef].length)
			{
				return _characterPools[ClassRef].shift() as IsoCharacter;
			}
			else
			{
				return new ClassRef();
			}
		}
		
		public function tilesAttach(isoObj:IsoBase, inX:int = -1, inY:int = -1, inBorderSize:int = 0):void
		{
			var i:int, j:int;
			var isoObjTiles:Array = isoObj.tilesAttached;
			var useX:int = (inX != -1) ? inX : isoObj.isoX - inBorderSize;
			var useY:int = (inY != -1) ? inY : isoObj.isoY - inBorderSize;
			
			if (!isoObj.isInMapBounds(inBorderSize, useX, useY))
			{
				Log.warn(this, "Attempted to attach {0} to map tiles but object was out of bounds", isoObj);
				return;
			}
			
			for (j = useY; j < useY + isoObj.isoSize + inBorderSize*2; ++j)
			{
				for (i = useX; i < useX + isoObj.isoSize + inBorderSize*2; ++i)
				{
					var tile:IsoTile = _grid[i][j];
					if (!(i < isoObj.isoX || 
						j < isoObj.isoY || 
						i >= isoObj.isoX + isoObj.isoSize || 
						j >= isoObj.isoY + isoObj.isoSize))
					{
						tile.content = isoObj;
					}
					
					isoObjTiles.push(tile);
				}
			}
		}
		
		public function tilesDetach(isoObj:IsoBase, inX:int = -1, inY:int = -1):void
		{
			//trace('tilesDetach ' + Math.random());
			var isoObjTiles:Array = isoObj.tilesAttached;
			var isoTile:IsoTile;
			
			if (inX == -1 || inY == -1) {
				inX = isoObj.isoX;
				inY = isoObj.isoY;
			}
			
			//var rowLength:int = Math.sqrt(isoObjTiles.length);
			//var rowTrace:Array = [];
			
			while (isoObjTiles && isoObjTiles.length) {
				isoTile = isoObjTiles.shift();
				isoTile.content = null;
				/*if (inX > -1 && inY > -1) {
					if (isoTile.isoX < inX || 
						isoTile.isoY < inY ||
						isoTile.isoX >= inX + isoObj.isoSize ||
						isoTile.isoY >= inY + isoObj.isoSize) {
						isoTile.paddingCount--;
						//rowTrace.push(isoTile.paddingCount);
					}else{
						//rowTrace.push(' ');
					}
				}*/
				
				/*if (rowTrace.length == rowLength) {
					trace(rowTrace.join(','));
					rowTrace = [];
				}*/
			}
		}
		
		public function addChildObjTest(inX:int, inY:int, isoObj:IsoBase, inBorderSize:int = 0, inBlockingObjs:Array = null):Boolean
		{
			var i:int, j:int;
			if (!isoObj) {
				return false;
			}
			
			var returnValue:Boolean = true;
			
			for (i = inX - inBorderSize; i < inX + isoObj.isoSize + inBorderSize; ++i) {
				for (j = inY - inBorderSize; j < inY + isoObj.isoSize + inBorderSize; ++j) {
					var tile:IsoTile;
					
					// check for valid indexes, should always pass                           
					if (i < _grid.length && i > -1 && j < _grid[i].length && j > -1) {
						tile = _grid[i][j];             
					}else{
						//trace('addChildObjTest failed: invalid tile');
						return false;
					}
					
					// check for walkable tile, only applies for character walking
					if (isoObj is IsoCharacter && !tile.isWalkable) {
						//trace('addChildObjTest failed: unWalkable');
						return false;
					} 
					
					// chec for valid placement, only for buying and moving buildings and props
					if (isoObj is IsoBuilding || isoObj is IsoProp) {
						if (tile.content && tile.content != isoObj) {
							//trace('addChildObjTest failed: foreign content in padding or area ' + Math.random());
							if (inBlockingObjs) inBlockingObjs.push(tile.content);
							returnValue = false;
						}
					}else if (/*tile.paddingCount || */(tile.content && tile.content != isoObj)){
						//trace('addChildObjTest failed: tile.paddingCount at ' + [i,j].join(','));
						if (inBlockingObjs && tile.content) inBlockingObjs.push(tile.content);
						returnValue = false;
					}
				}
			}
			return returnValue;
		}
		
		public function getIsoTile(inX:int, inY:int):IsoTile
		{
			var tile:IsoTile;
			
			if (inX < _gridWidth && inY < _gridHeight)
			{
				try
				{
					tile = _grid[inX][inY];
				}
				catch (error:Error)
				{
					return null;
				}
			}
			return tile;
		}
		
		public function getIsoTileFree(inX:int, inY:int):Boolean
		{
			var isInATown:Boolean = false;
			if(GameObjectManager.areaType == GameObjectManager.AREA_TYPE_HOMETOWN) isInATown = true;
			else if(GameObjectManager.areaType == GameObjectManager.AREA_TYPE_NEIGHBOR) isInATown = true;
			else if(GameObjectManager.areaType == GameObjectManager.AREA_TYPE_RIVAL) isInATown = true;
			
			if (inX < _gridWidth && inY < _gridHeight)
			{
				try
				{
					var tile:IsoTile = _grid[inX][inY];
					
					if(isInATown)
					{
						if(tile.isWalkable && tile.isExpansionTile) return true;
					}
					else
					{
						if (tile.isWalkable) return true;
					}
				}
				catch (error:Error)
				{
					return false;
				}
			}
			return false;
		}
		
		public function isIsoTileOccupied(inX:int, inY:int):Boolean
		{
			if (inX < _gridWidth && inY < _gridHeight)
			{
				try
				{
					var tile:IsoTile = _grid[inX][inY];
					return tile.content != null;
				}
				catch (error:Error)
				{
					return false;
				}
			}
			return false;
		}
		
		public function pathFind(inNodeStart:AStarNode, inNodesEnd:Array /*, isoMap:IsoMap*/):Array
		{
			var aStar:AStar = new AStar(this);
			var resultNode:AStarNode = aStar.search(inNodeStart, inNodesEnd /*, isoMap*/);
			aStar.dispose();
			var resultNodeArray:Array = new Array();
			
			while (resultNode != null)
			{
				// getIsoTile(resultNode.isoX, resultNode.isoY).alpha = 0.5;
				resultNodeArray.push(resultNode);
				resultNode.neighbors = null;
				resultNode = resultNode.parent;
			}
			
			return resultNodeArray;
		}
		
		public function findClosestWalkableTile(current:AStarNode, destination:AStarNode):AStarNode
		{
			var closestPath:Array = pathFind(destination, [current]);
			var node:AStarNode = closestPath.pop();
			
			while (!getIsoTileFree(node.isoX, node.isoY) && closestPath.length > 0)
			{
				node = closestPath.pop();
			}
			
			return node;
		}
		
		public function get avatar():IsoAvatar 
		{
			return _avatar;
		}
		
		public function set avatar(value:IsoAvatar):void 
		{
			if (_avatar)
				_avatar.dispose();

			_avatar = value;
		}
		
		public function getRivalBuildings():Array
		{
			var rivalBuildings:Array = [];
			for each (var dispObj:DisplayObject in _objArray) {
				if (dispObj is IsoRivalBuilding) {
					rivalBuildings.push(dispObj);
				}
			}
			
			return rivalBuildings;
		}
		
		public function getPlayerBuildings():Array
		{
			var playerBuildings:Array = [];
			for each (var dispObj:DisplayObject in _objArray) {
				if (dispObj is IsoPlayerBuilding) {
					playerBuildings.push(dispObj);
				}
			}
			
			return playerBuildings;
		}
		
		public function getBarracks():IsoPlayerBuilding
		{
			for each (var item:IsoPlayerBuilding in getPlayerBuildings())
			{
				// has to be a unit output with subtype 1 (infantry)
				if(item.model.building.output_type == Building.OUTPUT_TYPE_UNIT && item.model.building.output_subtype == 1)
					return item;
			}	
			
			return null;
		}	
		
		public function getEnemies():Array
		{
			var arr:Array = [];
			for each (var dispObj:DisplayObject in _objArray) {
				if (dispObj is IsoMonster) {
					arr.push(dispObj);
				}
			}
			
			return arr;
		}
		
		public function getPlayerProps():Array
		{
			var playerProps:Array = [];
			for each (var dispObj:DisplayObject in _objArray) {
				if (dispObj is IsoPlayerProp) {
					playerProps.push(dispObj);
				}
			}
			
			return playerProps;
		}
		
		public function getIsoPlayerBuilding(model:PlayerBuilding):IsoPlayerBuilding
		{
			var isoBuildings:Array = getPlayerBuildings();
			
			for each (var iso:IsoPlayerBuilding in isoBuildings){
				if(iso.model == model) return iso;
			}	
			
			return null;
		}
		
		public function getIsoPlayerBuildingByModelID(id:Number):IsoPlayerBuilding
		{
			var isoBuildings:Array = getPlayerBuildings();
			
			for each (var iso:IsoPlayerBuilding in isoBuildings){
				if(iso.model.id == id) return iso;
			}	
			
			return null;
		}
		
		public function getIsoPlayerProp(model:PlayerProp):IsoPlayerProp
		{
			var isoProps:Array = getPlayerProps();
			
			for each (var iso:IsoPlayerProp in isoProps){
				if(iso.model == model) return iso;
			}	
			
			return null;
		}
		
		public function localPixelToIso(px:Number, py:Number):Point
		{
			var iso:Point = new Point(-1, -1);
			
			iso.x = (px/2 + py)/IsoBase.GRID_PIXEL_SIZE;
			iso.y = iso.x - px / IsoBase.GRID_PIXEL_SIZE;
			
			iso.x = Math.floor(iso.x);
			iso.y = Math.floor(iso.y);
			
			return iso;
		}
		
		public function get objArray():Array {
			return _objArray;
		}
		
		/**
		 * Pauses the mouse mode
		 * Only allows one lock per object to ensure objects dont pause multiple times and resume only once
		 * @param pauser The object that is pausing the mouse mode
		 * 
		 */
		public function pauseMouseMode(pauser:Object, resetMouseMode:Boolean = true):void
		{
			if (_mouseModePausers[pauser]) return;
			
			_mouseModePausers[pauser] = 1;
			
			_pauseCount++;
			
			if (_isoMouseMode)
			{
				if (resetMouseMode && !(_isoMouseMode is IsoMouseModeLive || _isoMouseMode is IsoMouseModeRival))
				{
					// TODO - aray - change onCancelClick to something like "cancelClick"
					KingdomAgeMain.instance.hud.mainMenu.multitool.onCancelClick();
				}
				else
				{
					_isoMouseMode.pause();
				}
			}
		}
		
		public function resumeMouseMode(pauser:Object):void
		{
			if (!_mouseModePausers[pauser]) return;
			
			delete _mouseModePausers[pauser];
			
			_pauseCount--;
			
			if (_isoMouseMode && _pauseCount <= 0)
			{
				_isoMouseMode.resume();
				_pauseCount = 0;
			}
		}
		
		public function set mouseMode(newMouseMode:IIsoMouseMode):void
		{
			if (_isoMouseMode) 
			{
				_isoMouseMode.resume();
				_isoMouseMode.dispose();
			}
			
			_isoMouseMode = newMouseMode;
			
			if (_isoMouseMode) 
			{
				if (HudMenu.multiToolButton) 
					HudMenu.multiToolButton.cancelMode = !(_isoMouseMode is IsoMouseModeLive);
				
				if (_isoMouseMode is IsoMouseModeLive) 
					ControllerViewContainers.gi.tooltipContainer.mouseChildren = true;
				else
					ControllerViewContainers.gi.tooltipContainer.mouseChildren = false;
					
				_isoMouseMode.init(this);
				
				if (_pauseCount > 0) 
					_isoMouseMode.pause();
			}
		}
		
		public function get mouseMode():IIsoMouseMode
		{
			return _isoMouseMode;
		}
		
		public function get isMouseModePaused():Boolean
		{
			return _pauseCount > 0;
		}
		
		public function get isoMouseModeZoomAllowed():Boolean
		{
			return _pauseCount == 0 || (_pauseCount == 1 && _mouseModePausers[ControllerHud.gi.hud]);
		}
		
		public function get isMouseLive():Boolean
		{
			return _isoMouseMode is IsoMouseModeLive;
		}	
		
		public function cancelMouseClick():void
		{
			if (_isoMouseMode is IsoMouseModeLive)
				IsoMouseModeLive(_isoMouseMode).mouseCancel();
		}
		
		public function get isAbleToExpand():Boolean
		{
			return _isoMouseMode is IsoMouseModeLive;
		}
		
		public function get isMinimumBackgroundRendered():Boolean
		{
			return _renderer.hasDrawnBackground;
		}
		
		public function releaseAvatar():void {
			if (_isoMouseMode is IsoMouseModeLive) {
				IsoMouseModeLive(_isoMouseMode).releaseAvatar();
			}
		}
		
		public function debugShowHitAreas():void {
			var max:int = _objects.numChildren;
			var obj:*;
			var sObj:IsoStationary;
			var cObj:IsoCharacter;
			var assetDisplay:Sprite;
			for (var i:int = 0; i < max; i++) {
				obj = _objects.getChildAt(i);
				if (obj is IsoStationary) {
					sObj = IsoStationary(obj);
					assetDisplay = sObj.getAssetDisplay();
					var hitArea:DisplayObject = Sprite(assetDisplay.getChildAt(0)).getChildByName('isoHitArea');
					if (hitArea) {
						hitArea.alpha = 1;
						hitArea.filters = [
							new ColorMatrixFilter(
								new Array( 
									1, 0, 0, 0, 0,
									0, 1, 0, 0, 0,
									0, 0, 1, 0, 0,
									0, 0, 0, 1, 128						
								)
							)
						];
					}
				}else if (obj is IsoCharacter) {
					cObj = IsoCharacter(obj);
					cObj.filters = [
						new ColorMatrixFilter(
							new Array( 
								1, 0, 0, 0, 0,
								0, 1, 0, 0, 0,
								0, 0, 1, 0, 0,
								0, 0, 0, 1, 128						
							)
						)
					];
				}
			}
		}
	}
}
