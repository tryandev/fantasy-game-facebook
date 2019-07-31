package common.iso.view.display
{
	import flash.display.IBitmapDrawable;

	public interface IIsoBase extends IBitmapDrawable
	{
		function get isoX():Number;
		function set isoX(value:Number):void;

		function get isoY():Number;
		function set isoY(value:Number):void;

		function get isoWidth():Number;
		function set isoWidth(value:Number):void;

		function get isoLength():Number;
		function set isoLength(value:Number):void;

		function get isoSize():Number;
		function set isoSize(value:Number):void;

		function get sortY():Number;

		function dispose():void;
	}
}