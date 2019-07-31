package common.iso.control.mouse
{
	import com.raka.crimetown.business.command.purchase.amf.SellPropCommand;
	import com.raka.crimetown.view.popup.PopupManager;
	import com.raka.crimetown.view.popup.PopupProperties;
	import com.raka.crimetown.view.popup.sellConfirmation.SellBuildingConfirmationPopup;
	
	import common.iso.view.display.IsoPlayerBuilding;
	import common.iso.view.display.IsoPlayerProp;
	
	import flash.events.Event;
	
	public class IsoMouseModeObjSell extends IsoMouseModeObjMove implements IIsoMouseMode
	{
		public function IsoMouseModeObjSell()
		{
			
		}
		
		protected override function addIcon():void {
			icon = new DlgBtnSell();
		}
		
		protected override function mouseClick(e:Event = null):void 
		{
			if (_hoverObj)
			{
				if (_hoverObj is IsoPlayerBuilding)
				{
					// TODO - alk - how to handle failure?
					PopupManager.instance.addPopup(new SellBuildingConfirmationPopup(IsoPlayerBuilding(_hoverObj)), PopupProperties.TRANSPARENT_MODAL);
				}
				else if (_hoverObj is IsoPlayerProp)
				{
					new SellPropCommand(IsoPlayerProp(_hoverObj)).execute();
					
					//There seemed to be a fair amount of effort put into the framework for this--not sure if the "don't confirm" decision is going to stand
					//PopupManager.instance.addPopup(new SellPropConfirmationPopup(IsoPlayerProp(_hoverObj)), false);
				}
			}
		}
		
	}
}
