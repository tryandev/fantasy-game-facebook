package common.iso.view.containers
{
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	
	import common.iso.view.display.IsoBase;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class IsoFog extends Sprite
	{
		private const FOG_OPACITY:Number = 0.50;
		private var _background:BitmapLarge;
		
		public function IsoFog(inBG:BitmapLarge)
		{
			_background = inBG;
			mouseChildren = false;
		}
		
		public function dispose():void
		{
			_background = null;
		}
		
		public function bakeExpand(inX:int, inY:int):void
		{
			var newFog:Sprite = new FogTile();
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			newFog.x = IsoBase.GRID_PIXEL_SIZE * expSize * (inX - inY - 1);
			newFog.y = IsoBase.GRID_PIXEL_SIZE * expSize * (inX + inY) / 2;
			var bmd:BitmapData = new BitmapData(newFog.width, newFog.height, true, 0);
			var rect:Rectangle = new Rectangle(0, 0, bmd.width, bmd.height);
			var point:Point = new Point(0,0);
			bmd.draw(newFog,null,null,null, rect);
			_background.draw(
				bmd, 
				new Matrix(1, 0, 0, 1, newFog.x -_background.x, newFog.y - _background.y), 
				new ColorTransform(
					1.0,	1.0,	1.0,	this.FOG_OPACITY,
					0,		0,		0,		0
				), 
				BlendMode.OVERLAY
			);	
			bmd.dispose();
			_background.applyFilter(
				new ColorMatrixFilter(
					new Array(
						0.99, 	0.0, 	0.0, 	0.0, 	0,
						0.0, 	0.99, 	0.0, 	0.0, 	0,
						0.0, 	0.0, 	0.99, 	0.0, 	0,
						0.0, 	0.0, 	0.0, 	1.0, 	0
					)
				)
			);
		}
		
		public function drawFogVector():void
		{
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			var expansionMap:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
			
			var _graphics:Graphics = this.graphics;
			_graphics.clear();
			_graphics.beginFill(0x000000, FOG_OPACITY * .666);
			_graphics.drawRect(_background.x, _background.y, _background.width, _background.height);
			for (var iy:int = 0; iy < expansionMap.length; iy++)
			{
				for (var ix:int = 0; ix < expansionMap[iy].length; ix++)
				{
					if (expansionMap[iy][ix] == 3)
					{
						var drawX:Number = IsoBase.GRID_PIXEL_SIZE * expSize * (ix - iy - 1);
						var drawY:Number = IsoBase.GRID_PIXEL_SIZE * expSize * (ix + iy) / 2;;
						
						_graphics.moveTo(drawX + IsoBase.GRID_PIXEL_SIZE * expSize, 		drawY + 0);
						_graphics.lineTo(drawX + IsoBase.GRID_PIXEL_SIZE * expSize * 2, 	drawY + IsoBase.GRID_PIXEL_SIZE * expSize / 2);
						_graphics.lineTo(drawX + IsoBase.GRID_PIXEL_SIZE * expSize, 		drawY + IsoBase.GRID_PIXEL_SIZE * expSize);
						_graphics.lineTo(drawX + 0, 										drawY + IsoBase.GRID_PIXEL_SIZE * expSize / 2);
						_graphics.lineTo(drawX + IsoBase.GRID_PIXEL_SIZE * expSize, 		drawY + 0);
					}
				}
			}
			_graphics.endFill();
		}
		
		public function drawFogBake():void
		{
			this.parent && this.parent.removeChild(this);
			this.graphics.clear();
			var expSize:int = GameObjectLookup.sharedGameProperties.expansion_size;
			var expansionMap:Array = ExpansionController.instance.currentPlayerMap.expansion_map;
			var matrix:Matrix = new Matrix();
			
			_background.applyFilter(
				new ColorMatrixFilter(
					new Array(
						0.50, 	0.0, 	0.0, 	0.0, 	0,
						0.0, 	0.50, 	0.0, 	0.0, 	0,
						0.0, 	0.0, 	0.50, 	0.0, 	0,
						0.0, 	0.0, 	0.0, 	1.0, 	0
					)
				)
			);
			
			for (var iy:int = 0; iy < expansionMap.length; iy++)
			{
				for (var ix:int = 0; ix < expansionMap[iy].length; ix++)
				{
					if (expansionMap[iy][ix] == 3)
					{
						var newFog:Sprite = new FogTile();
						newFog.x = IsoBase.GRID_PIXEL_SIZE * expSize * (ix - iy - 1);
						newFog.y = IsoBase.GRID_PIXEL_SIZE * expSize * (ix + iy) / 2;
						
						var bmd:BitmapData = new BitmapData(newFog.width, newFog.height, true, 0);
						var rect:Rectangle = new Rectangle(0, 0, bmd.width, bmd.height);
						var point:Point = new Point(0,0);
						bmd.draw(newFog,null,null,null, rect);
						_background.draw(
							bmd, 
							new Matrix(1, 0, 0, 1, newFog.x -_background.x, newFog.y - _background.y), 
							new ColorTransform(
								1.0,	1.0,	1.0,	this.FOG_OPACITY,
								0,		0,		0,		0
							), 
							BlendMode.OVERLAY
						);	
						bmd.dispose();
					}
				}
			}
			
			var rMult:Number = 1 / (0.5 * ( 1 + FOG_OPACITY));
			
			_background.applyFilter(
				new ColorMatrixFilter(
					new Array(
						rMult, 	0.0, 	0.0, 	0.0, 	0,
						0.0, 	rMult, 	0.0, 	0.0, 	0,
						0.0, 	0.0, 	rMult, 	0.0, 	0,
						0.0, 	0.0, 	0.0, 	1.0, 	0
					)
				)
			);
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
		
		g.beginFill(0xFFFFFF, 1);
		g.moveTo(IsoBase.GRID_PIXEL_SIZE * expSize, 0);
		g.lineTo(2*IsoBase.GRID_PIXEL_SIZE * expSize, IsoBase.GRID_PIXEL_SIZE * expSize / 2);
		g.lineTo(IsoBase.GRID_PIXEL_SIZE * expSize, IsoBase.GRID_PIXEL_SIZE * expSize);
		g.lineTo(0, IsoBase.GRID_PIXEL_SIZE * expSize / 2);
		g.lineTo(IsoBase.GRID_PIXEL_SIZE * expSize, 0);
	}
}