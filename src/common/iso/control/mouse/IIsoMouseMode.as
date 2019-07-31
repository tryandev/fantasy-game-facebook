package common.iso.control.mouse
{
	import com.raka.iso.utils.IDisposable;
	import common.iso.view.containers.IsoMap;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;

	public interface IIsoMouseMode extends IDisposable
	{
		function init(map:IsoMap):void;
		function pause():void;
		function resume():void;
	}
}