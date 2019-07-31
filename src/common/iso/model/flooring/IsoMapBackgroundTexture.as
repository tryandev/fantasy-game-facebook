package common.iso.model.flooring
{
	import com.raka.loader.RakaLoadService;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	public class IsoMapBackgroundTexture
	{
		private var _id:String;
		private var _index:int;
		private var _density:int;
		
		private var _collection:MovieClip;
		
		public function IsoMapBackgroundTexture(id:String, index:int, density:int)
		{
			_id = id;
			_index = index;
			_density = density;
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function get index():int
		{
			return _index;
		}
		
		public function get density():int
		{
			return _density;
		}
		
		public function get hasImage():Boolean
		{
			return RakaLoadService.getInstance().hasClassDefinition(_id);
		}
		
		public function get collectionClass():Class
		{
			return RakaLoadService.getInstance().getClassDefinition(_id);
		}
		
		public function get collection():MovieClip
		{
			if (_collection == null) _collection = new collectionClass();
			
			return _collection;
		}
		
		public function getRandomOverlayImage(rnd:Number = NaN):DisplayObject
		{
			var frame:int = getRandomFrameIndex(rnd);
			
			return getFrame(frame);
		}
		
		public function getFrame(frame:int):DisplayObject
		{
			collection.gotoAndStop(frame);
			
			return collection;
		}
		
		public function getRandomFrameIndex(rnd:Number = NaN):int
		{
			return Math.ceil((isNaN(rnd) ? Math.random() : rnd) * collection.totalFrames)
		}
	}
}