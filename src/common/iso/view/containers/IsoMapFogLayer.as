package common.iso.view.containers
{
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	
	import common.iso.view.display.IsoBase;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;

	public class IsoMapFogLayer extends Sprite
	{
		private var fogPool:Array;
		private var fog:Array;
		private var fogMask:Sprite;
		
		public function IsoMapFogLayer()
		{
			mouseChildren = false;
			
			fogPool = [];
			fog = [];
			
			fogMask = new Sprite();
			fogMask.graphics.lineStyle(0);
			fogMask.graphics.beginFill(0x000000, 0.1);
			fogMask.graphics.drawRect(0, 0, IsoMap.VIEWPORT_WIDTH, IsoMap.VIEWPORT_HEIGHT);
			fogMask.graphics.endFill();
			addChild(fogMask);
			
			blendMode = BlendMode.LAYER;
			transform.colorTransform = new ColorTransform(1, 1, 1, -0.5, 0, 0, 0, 127);
			
			updateFog();
		}
		
		public function updateFog():void
		{
			clearFogTiles();
			
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			var expansionMap:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
			var matrix:Matrix = new Matrix();
			
			for (var iy:int = 0; iy < expansionMap.length; iy++)
			{
				for (var ix:int = 0; ix < expansionMap[iy].length; ix++)
				{
					if (expansionMap[iy][ix] == 3)
					{
						var newFog:Sprite = getFogTile();
						newFog.x = IsoBase.GRID_PIXEL_SIZE * expSize * (ix - iy);
						newFog.y = IsoBase.GRID_PIXEL_SIZE * expSize * (ix + iy) / 2;
						addChild(newFog);
					}
				}
			}
		}
		
		public function updatePosition(viewX:Number, viewY:Number, viewWidth:Number, viewHeight:Number):void
		{
			fogMask.x = viewX;
			fogMask.y = viewY;
			
			// TODO - snm - remove all fog things outside of the mask
			// TODO - snm - add those that need to be added
		}
		
		private function clearFogTiles():void
		{
			while (fog.length > 0)
			{
				var fogTile:FogTile = fog.pop();
				fogPool.push(fogTile);
				removeChild(fogTile);
			}
		}
		
		private function removeFogTile(tile:Sprite):void
		{
			fog.splice(fog.indexOf(tile), 1);
			fogPool.push(tile);
			removeChild(tile);
		}
		
		private function getFogTile():Sprite
		{
			if (fogPool.length > 0) return fogPool.pop();
			else return new FogTile(); 
		}
	}
}

/*
** FogTile
*/

import com.raka.crimetown.model.game.lookup.GameObjectLookup;

import common.iso.view.display.IsoBase;

import flash.display.Graphics;
import flash.display.Sprite;

internal class FogTile extends Sprite
{
	public function FogTile():void
	{
		var g:Graphics = graphics;
		var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
		
		g.lineStyle(0);
		g.beginFill(0x000000, 1);
		g.moveTo(0, 0);
		g.lineTo(IsoBase.GRID_PIXEL_SIZE * expSize, IsoBase.GRID_PIXEL_SIZE * expSize / 2);
		g.lineTo(0, IsoBase.GRID_PIXEL_SIZE * expSize);
		g.lineTo(-IsoBase.GRID_PIXEL_SIZE * expSize, IsoBase.GRID_PIXEL_SIZE * expSize / 2);
		g.lineTo(0, 0);
	}
}