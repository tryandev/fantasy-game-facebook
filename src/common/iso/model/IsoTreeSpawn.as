package common.iso.model
{
	public class IsoTreeSpawn
	{
		public var image:String;
		
		public var ymin:Number;
		public var ymax:Number;
		
		public var yminSelectionWeight:Number;
		public var ymaxSelectionWeight:Number;
		
		public function IsoTreeSpawn()
		{
		}
		
		public function isOverlapping(other:IsoTreeSpawn):Boolean
		{
			return (ymax > other.ymin || ymin < other.ymax);
		}
		
		public function containsY(yValue:Number):Boolean
		{
			return (ymax >= yValue && ymin < yValue);
		}
		
		public function getWeightAtY(yValue:Number):Number
		{
			if (!containsY(yValue)) return 0;
			
			var percent:Number = (yValue - ymin) / (ymax - ymin);
			
			return percent * (ymaxSelectionWeight - yminSelectionWeight) + yminSelectionWeight;
		}
	}
}