package common.iso.model
{
	import com.raka.utils.DateUtil;

	public class EnemyOverlayVO
	{
		public var name:String = "Monster Name";
		public var health:int = 0;
		public var maxHealth:int = 0;
		public var energyCost:int = 0;
		public var attacks:int = 0;
		public var type:String = "Monster Type";
		public var queueCount:int;
		
		public var startTime:Number;
		public var endTime:Number;
		
		public function get total():Number
		{
			return endTime - startTime;
		}	
		
		public function get remaining():Number
		{
			var time:Number = endTime - DateUtil.now();
			return time < 0 ? 0 : time;
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
		
			
	}
}
