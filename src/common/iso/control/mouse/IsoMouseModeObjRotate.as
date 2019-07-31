package common.iso.control.mouse
{
	//import .*;
	
	import com.raka.crimetown.business.command.MoveBuildingCommand;
	import com.raka.crimetown.business.command.MovePropCommand;
	import com.raka.crimetown.business.command.RotateBuildingCommand;
	import com.raka.crimetown.business.command.RotatePropCommand;
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.crimetown.util.sound.CTSoundsForHometown;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.proxy.ICommand;
	
	import common.iso.view.display.IsoPlayerBuilding;
	import common.iso.view.display.IsoPlayerProp;
	
	import flash.events.Event;
	
	
	public class IsoMouseModeObjRotate extends IsoMouseModeObjMove implements IIsoMouseMode
	{
		private var _commandRotate:ICommand;
		
		public function IsoMouseModeObjRotate()
		{
			
		}
		
		public override function dispose():void {
			super.dispose();
			_commandRotate = null;
		}
		
		protected override function addIcon():void {
			icon = new DlgBtnRotate();
		}
		
		protected override function mouseClick(e:Event = null):void 
		{
			if (_hoverObj)
			{
				_hoverObj.nextDirection();
				
				if (_hoverObj is IsoPlayerBuilding)
				{
					// TODO - alk - how to handle failure?
					_commandRotate = new RotateBuildingCommand(IsoPlayerBuilding(_hoverObj).model);
					_commandRotate.execute();
					RakaSoundManager.getInstance().playSoundFX(CTSoundFx.ROTATE_BUILDING);
				}
				else if (_hoverObj is IsoPlayerProp)
				{
					_commandRotate = new RotatePropCommand(IsoPlayerProp(_hoverObj).model);
					_commandRotate.execute();
					RakaSoundManager.getInstance().playSoundFX(CTSoundFx.ROTATE_BUILDING);
					//new MovePropCommand(IsoPlayerProp(_hoverObj).model).execute();
				}
			}
		}
		
	}
}
