package common.iso.view.containers
{
	import com.raka.iso.utils.IDisposable;
	
	import flash.display.Sprite;
	
	public class IsoOverlay extends Sprite implements IDisposable
	{
		public function IsoOverlay()
		{
			super();
		}
		
		public function updatePositions():void
		{
			for (var i:int = 0; i < this.numChildren; i++)
			{
				var item:IsoOverlayItem = IsoOverlayItem(this.getChildAt(i));
				if(item.visible)
					item.updatePosition();
			}
		}
		
		public function dispose():void
		{
			while(numChildren > 0)
			{
				var item:IsoOverlayItem = getChildAt(0) as IsoOverlayItem;
				item.dispose(); // item dispose method removes from parent
			}
		}
	}
}