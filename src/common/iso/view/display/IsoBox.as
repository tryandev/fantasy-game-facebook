package common.iso.view.display
{
	public class IsoBox extends IsoBase implements IIsoBase
	{
		public function IsoBox(size:int = 1)
		{
			super();
			_isoSize = size;
			redraw();
		}

		protected override function redraw():void
		{
			graphics.clear();
			var halfSize:Number = GRID_PIXEL_SIZE * _isoSize;
			var extraSize:Number = _isoSize - 0.25;
			graphics.lineStyle(0, 0x000000, 0.2);
			graphics.beginFill(0xCCCCCC, 1);

			graphics.moveTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(halfSize, halfSize / 2);
			graphics.lineTo(0, halfSize);
			graphics.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);

			graphics.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(-halfSize, halfSize / 2);
			graphics.lineTo(0, halfSize);
			graphics.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);

			graphics.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(0, -halfSize + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);

			graphics.endFill();

			graphics.lineStyle();
			graphics.beginFill(0x000000, 0.6);
			graphics.moveTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(halfSize, halfSize / 2);
			graphics.lineTo(0, halfSize);
			graphics.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			graphics.endFill();

			graphics.beginFill(0x000000, 0.3);
			graphics.lineTo(-halfSize, -halfSize / 2 + extraSize * GRID_PIXEL_SIZE);
			graphics.lineTo(-halfSize, halfSize / 2);
			graphics.lineTo(0, halfSize);
			graphics.lineTo(0, 0 + extraSize * GRID_PIXEL_SIZE);
			graphics.endFill();

			super.redraw();
		}
	}
}
