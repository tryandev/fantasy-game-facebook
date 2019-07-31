package common.iso.model
{
	import com.raka.commands.interfaces.ICommand;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.iso.utils.IDisposable;
	import com.raka.loader.IRakaLoadImage;
	import com.raka.loader.RakaLoadImage;
	import com.raka.loader.RakaLoadPriorities;
	import com.raka.loader.events.RakaLoadErrorEvent;
	import com.raka.loader.events.RakaLoadEvent;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.cmd.IsoCommandLoadAsset;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	
	public class IsoTree implements IDisposable
	{
		private var _image:String;
		
		public var scale:Number;
		public var x:Number;
		public var y:Number;
		
		public function IsoTree(inImage:String)
		{
			_image = inImage;
			scale = 1;
		}
		
		public function dispose():void
		{
			
		}
		
		public function get url():String
		{
			return IsoModel.gi.getPosterUrl(_image);
		}
	}
}