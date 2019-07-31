package common.iso.model
{
	import com.raka.commands.interfaces.ICommand;
	import com.raka.iso.utils.IDisposable;
	import com.raka.loader.IRakaLoadImage;
	import com.raka.loader.RakaLoadImage;
	import com.raka.loader.RakaLoadPriorities;
	import com.raka.loader.RakaLoadService;
	import com.raka.loader.events.RakaLoadEvent;
	
	import common.iso.control.cmd.IsoCommandLoadAsset;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import com.raka.utils.logging.Log;

	public class IsoPoster implements IDisposable
	{
		public var _image:String;
		public var index:int;
		public var scale:Number;
		public var x:Number;
		public var y:Number;
	
		public function IsoPoster()
		{
		}
		
		public function populate(inImage:String, index:int, x:Number, y:Number, inScale:Number):void
		{
			this._image = inImage;
			this.index = index;
			this.x = x;
			this.y = y;
			this.scale = inScale;
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