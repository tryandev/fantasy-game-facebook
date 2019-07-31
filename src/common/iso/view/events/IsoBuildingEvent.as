package common.iso.view.events
{
	import flash.events.Event;
	
	public class IsoBuildingEvent extends Event
	{
		
		// a model has been replaced on an isobuilding and new calculations have been made
		// in the activeplayer playerdatamap
		public static var UPDATE_BUILDING_DATA:String = "IsoBuildingEvent.UPDATE_BUILDING_DATA";
		
		public function IsoBuildingEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}