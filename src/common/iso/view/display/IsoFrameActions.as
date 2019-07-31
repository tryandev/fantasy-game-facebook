package common.iso.view.display
{
	import common.iso.model.FrameAction;
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;

	public class IsoFrameActions
	{
		
		private var _labels:Array;
		
		private var _currentFrame:int;
		private var _currentType:String;
		
	
		public function IsoFrameActions(clip:MovieClip)
		{
			readClip(clip);	
		}

		public function readClip(clip:MovieClip):IsoFrameActions
		{
			var labels:Array = clip.currentLabels;
			
			_labels = [];
			for each (var item:FrameLabel in labels)
			{
				var actions:Array = item.name.split("|");
				for each (var action:String in actions)
				{
					_labels.push(new FrameAction(item.frame, action));
				}
			}	

			return this;
		}	
		
		public function reset():void
		{
			for each (var item:FrameAction in _labels)
			{
				item.hasExecuted = false;	
			}	
		}	

		/**
		 *	@return Array of FrameAction objects
		 */	
		public function getFrameActionsOfType(frame:int, type:String):Array
		{
			_currentFrame = frame;
			_currentType = type;

			return _labels.filter(filterActionsShouldRun);
		}	
		
		public function getAllFrameActionsOfType(type:String):Array
		{
			_currentType = type;
			
			return _labels.filter(filterActionsOfType);
		}	
		
		public function getAllSoundFrameActions():Array
		{
			return getAllFrameActionsOfType(FrameAction.TYPE_SFX);
		}	
		
		public function get labels():Array
		{
			return _labels;
		}
		
		public function set labels(value:Array):void
		{
			_labels = value;
		}
		
		private function filterActionsShouldRun(action:FrameAction, index:int, arr:Array):Boolean
		{
			if(!action.hasExecuted && action.frame <= _currentFrame && action.type == _currentType)
			{
				action.hasExecuted = true;
				return true;
			}
			
			return false;
		}
		
		private function filterActionsOfType(action:FrameAction, index:int, arr:Array):Boolean
		{
			return action.type == _currentType;
		}	
	}
}