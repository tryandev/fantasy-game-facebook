package common.iso.model.flooring
{
	import common.iso.model.IsoModel;

	public class IsoFlooring
	{
		protected var _id:String;
		protected var _x:int;
		protected var _y:int;
		protected var _type:String;
		protected var _tileset:String;

		public function IsoFlooring()
		{
		}

		public function populate(id:String, x:int, y:int, type:String, tileset:String):void
		{
			_id = id;
			_x = x;
			_y = y;
			_type = type;
			_tileset = tileset;
		}

		public function get id():String
		{
			return _id;
		}

		public function get x():int
		{
			return _x;
		}

		public function get y():int
		{
			return _y;
		}

		public function get type():String
		{
			return _type;
		}

		public function get tileset():String
		{
			return _tileset;
		}

		public function toString():String
		{
			return "IsoFlooring: " + _id;
		}
	}
}
