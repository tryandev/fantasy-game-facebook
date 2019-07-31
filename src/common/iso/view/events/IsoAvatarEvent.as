package common.iso.view.events
{
	import flash.events.Event;
	
	public class IsoAvatarEvent extends Event
	{
		public static const ASSET_READY:String = "IsoAvatarEvent.ASSET_READY";
		public function IsoAvatarEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}