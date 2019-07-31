package common.iso.model
{
	public class FrameAction
	{
		static public var TYPE_SFX:String = "sfx";
		static public var TYPE_HIT:String = "hit";
		static public var TYPE_SHAKE:String = "shake";
		static public var TYPE_LAUNCH:String = "launch";
		
		
		public var frame:int;
		public var asset:String;
		public var type:String;
		
		public var hasExecuted:Boolean = false;
		
		private var _originalLabel:String;
		
		public function FrameAction(frame:int, fullLabel:String)
		{
			_originalLabel = fullLabel;
			
			this.frame = frame;
			
			
			var fullActionArray:Array = _originalLabel.split("_");
			
			type = fullActionArray[0];
			
			if(fullActionArray.length > 1)
			{
				fullActionArray.splice(0,1);
				asset = fullActionArray.join("_");
			}
			
		}
		
		public function toString():String
		{
			return "[ FrameAction ]  "+ type +" frame:"+frame+" asset:"+asset+"   original label: "+_originalLabel;
		}	
	}
}