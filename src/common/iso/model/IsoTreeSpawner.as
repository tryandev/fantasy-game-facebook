package common.iso.model
{
	import flash.utils.Dictionary;

	public class IsoTreeSpawner
	{
		protected var _spawns:Array;
		protected var _urls:Array;
		
		public var density:Number;
		
		public function IsoTreeSpawner()
		{
			density = 1;
		}
		
		public function get shouldSpawnTrees():Boolean
		{
			return _spawns != null && _spawns.length > 0;
		}
		
		public function getTreeForY(yValue:Number, rnd:Number = NaN):IsoTree
		{
			if (_spawns == null) return null;
			
			var totalWeight:Number = 0;
			var weight:Number;
			var possibleSpawns:Array = [];
			
			for each (var spawn:IsoTreeSpawn in _spawns)
			{
				weight = spawn.getWeightAtY(yValue);
				if (weight > 0)
				{
					totalWeight += weight;
					possibleSpawns.push({weight:weight, image:spawn.image});
				}
			}
			
			possibleSpawns.sortOn("weight", Array.NUMERIC);
			
			var randomSelection:Number = (isNaN(rnd) ? Math.random() : rnd) * totalWeight;
			
			weight = 0;
			for each (var object:Object in possibleSpawns)
			{
				weight += object.weight;
				
				if (weight > randomSelection)
				{
					return new IsoTree(object.image);
				}
			}
			
			return null;
		}
		
		internal function set spawns(spawns:Array):void
		{
			_spawns = spawns;
		}
		
		public function get urls():Array
		{
			if (!_urls)
			{
				_urls = [];
				var images:Dictionary = new Dictionary();
				
				for each (var spawn:IsoTreeSpawn in _spawns)
				{
					if (!images[spawn.image])
					{
						images[spawn.image] = 1;
						_urls.push(IsoModel.gi.getPosterUrl(spawn.image));
					}
				}
			}
			
			return _urls;
		}
	}
}