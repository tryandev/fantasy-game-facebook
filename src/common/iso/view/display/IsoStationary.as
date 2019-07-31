package common.iso.view.display
{
	import com.raka.crimetown.model.AbstractStaticMapObject;
	import com.raka.crimetown.model.game.AbstractAreaMapObject;
	import com.raka.crimetown.model.game.IStationaryMapObject;
	import com.raka.utils.logging.Log;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 *	Abstract class for loading and position stationary iso objects
	 * 	onto the iso map.
	 *	
	 *	@author Tate Jennings
	 *
	 *	@langversion ActionScript 3.0
	 *	@playerversion Flash 10
	 *
	 */	
	
	
	public class IsoStationary extends IsoState
	{
		
		protected var _model:IStationaryMapObject;
		
		protected var _gridShift:Point;
		
		public function IsoStationary()
		{
			super();
		}
		
		/**
		 *	Load an asset that is not movable
		 */	
		protected function loadStationaryAsset(onFailure:Function = null):void
		{
			super.loadAsset(onAssetLoaded, onFailure);
		}	
		
		override public function dispose():void
		{
			super.dispose();
			_model = null;
			_gridShift = null;
		}
		
		public function positionModel():void 
		{
			_model.iso_x = this.isoX;
			_model.iso_y = this.isoY;
		}	
		
		/**
		 *	Make sure the position and size of the iso object are correct.
		 */	
		protected function positionIso():void
		{
			this.isoX = _model.iso_x;
			this.isoY = _model.iso_y;
			
			this.isoSize = Math.min(_model.iso_height, _model.iso_width);
		}	
		
		/**
		 *	The assets need to be ofset to work with the new iso world, 
		 * 	the grid also needs to be removed.
		 */	
		protected function positionAsset(asset:DisplayObject):void
		{
			var assetDOC:DisplayObjectContainer = DisplayObjectContainer(asset);
			var grid:DisplayObject = assetDOC.getChildByName('grid');	
			var art:DisplayObject = assetDOC.getChildByName('art');
			var hit:DisplayObject = assetDOC.getChildByName('isoHitArea');
			
			/*hit.alpha = 1;
			hit.filters = [
				new ColorMatrixFilter(
					new Array( 
						1, 0, 0, 0, 0,
						0, 1, 0, 0, 0,
						0, 0, 1, 0, 0,
						0, 0, 0, 1, 128						
					)
				)
			];/**/
			
			if (grid)  {
				_gridShift = new Point(grid.x, grid.y);
				assetDOC.removeChild(grid);
				/*if (art) {
					art.x -= grid.x;
					art.y -= grid.y;
				}
				if (hit) {
					hit.x -= grid.x;
					hit.y -= grid.y;
				}*/
				
				//if (!hit && !art) {
				var dispObj:DisplayObject;
				var dispIndex:int = 0;
				for (dispIndex; dispIndex < assetDOC.numChildren; dispIndex++) {
					dispObj = assetDOC.getChildAt(dispIndex);
					dispObj.x -= _gridShift.x;
					dispObj.y -= _gridShift.y;
				}
				//}
			}
		}	
		
		//  GETTER SETTER FUNCTIONS
		// -----------------------------------------------------------------//
		override public function get mapOverlayPostion():Point
		{
			if(_gridShift)
				return new Point(this.x, this.y - _gridShift.y);
			
			return new Point(this.x, this.y);
			
		}	
		
		//  HANDLER FUNCTIONS
		// -----------------------------------------------------------------//
	
		/**
		 *	Asset has completed loading.
		 */	
		protected function onAssetLoaded():void
		{
			var asset:DisplayObject = getAssetInstance();
			
			if(asset)
			{
				//Log.info(this, "Stationary asset loaded: "+ asset, _cacheKey);
				
				positionAsset(asset);
				clearAssets();
				addAsset(asset);
				showTransparency(false);
			}
		}	
		
		protected function placeHolderColor():int
		{
			return 0xCCCCCC;
		}
		
		protected function onAssetFailed():void 
		{
			clearAssets();
			
			var mc:MovieClip = new MovieClip();
			var g:Graphics = mc.graphics;
			
			g.clear();
			var halfSize:Number = GRID_PIXEL_SIZE * _isoSize;
			var extraSize:Number = _isoSize - 0.50;
			g.lineStyle(0, 0x000000, 0.2);
			g.beginFill(placeHolderColor(), 1);
			
			g.moveTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(halfSize, halfSize / 2);
			g.lineTo(0, halfSize);
			g.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			
			g.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(-halfSize, halfSize / 2);
			g.lineTo(0, halfSize);
			g.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			
			g.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(0, -halfSize + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			
			g.endFill();
			
			g.lineStyle();
			g.beginFill(0x000000, 0.3);
			g.moveTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(halfSize, halfSize / 2);
			g.lineTo(0, halfSize);
			g.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			g.endFill();
			
			g.beginFill(0x000000, 0.6);
			g.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			g.lineTo(-halfSize, halfSize / 2);
			g.lineTo(0, halfSize);
			g.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			g.endFill();
			
			addAsset(mc);
			showTransparency(false);
		}
		
		// @@@@@@@@ NEW direction change code
		
		public function get direction():String 
		{
			return _model.direction;
		}
		
		// RT - changing the direction will reload the asset
		public function set direction(value:String):void {
			//trace(this + 'attempt to set dir = ' + value);
			var newDirPos:int = "SESWNWNE".indexOf(value);
			
			if (value == _model.direction)
			{
				//trace(this + ' already use dir = ' + value);
			}
			else if (newDirPos % 2 == 0)
			{
				//trace(this + ' valid new dir = ' + value);
				_model.direction = value;
				loadAsset(onAssetLoaded, onAssetFailed);
			}
			else
			{
				//trace(this + ' invalid new dir = ' + value);
			}
		}
		
		public function nextDirection():void
		{
			var dirs:String = "SESWNWNE";
			direction = dirs.substr((dirs.indexOf(direction) + 2) % dirs.length, 2);
			trace((dirs.indexOf(direction) + 2) % dirs.length);
		}
		
		public function getAssetDisplay():Sprite
		{
			return _assetDisplay;
		}
	}
}