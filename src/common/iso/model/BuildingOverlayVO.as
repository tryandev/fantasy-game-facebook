package common.iso.model
{
	import com.raka.utils.DateUtil;

	public class BuildingOverlayVO
	{
		public var name:String = "";
		public var detail:String = "";
		public var cta:String = "";
		public var level:int = 0;
		public var totalLevels:int = 0;
		public var currentProgress:int;
		public var totalProgress:int;
		public var paused:Boolean = false;
		
		public var startTime:Number;
		public var endTime:Number;
		
		public function get total():Number
		{
			return endTime - startTime;
		}	
		
		// add an extra second (almost) to what to display so that 
		// we show 00:01 instead of 00:00 when there's less than 
		// a second left
		public function get paddedRemaining():Number
		{
			return remaining + 999;
		}	
		
		public function get remaining():Number
		{
			if(DateUtil.now() < startTime) return total;

			return timeLeft < 0 ? 0 : timeLeft;
		}
		
		public function get current():Number
		{
			var time:Number = DateUtil.now() - startTime;
			time = time > total ? total : time;
			time = time < 0 ? 0 : time;	
			
			return time;
		}	
		
		public function get completed():Boolean
		{
			return remaining == 0;
		}		
		
		private function get timeLeft():Number
		{
			return endTime - DateUtil.now();
		}	
	}
}