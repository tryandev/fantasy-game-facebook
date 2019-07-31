package common.iso.control.ai
{
	public class AStarNode
	{
		//private var _f:Number;
		//private var _g:Number;
		//private var _h:Number;
		//private var _neighbors:Array;
		//private var _isoX:int;
		//private var _isoY:int;
		//private var _parent:AStarNode;
		
		public var neighbors:Array;
		public var f:Number;
		public var g:Number;
		public var h:Number;
		public var isoX:int;
		public var isoY:int;
		public var parent:AStarNode;

		public function AStarNode(inX:int = 0, inY:int = 0)
		{
			//_isoX = inX;
			//_isoY = inY;
			isoX = inX;
			isoY = inY;
		}

		public function dispose():void
		{
			neighbors = null;
			parent = null;
		}

		public function toString():String
		{
			return "[" + isoX + " " + isoY + "]" + " " + Math.round((g + h) * 100) / 100 + "\t";
		}

		/*public function set isoX(value:int):void
		{
			_isoX = value;
			// trace("set isoX to " + _isoX);
		}

		public function get isoX():int
		{
			return _isoX;
		}

		public function set isoY(value:int):void
		{
			_isoY = value;
			// trace("set isoY to " + _isoY);
		}

		public function get isoY():int
		{
			return _isoY;
		}*/

		/*public function set neighbors(arr:Array):void
		{
			_neighbors = arr;
		}

		public function get neighbors():Array
		{
			return _neighbors;
		}*/

		/*public function set f(inF:Number):void {
		_f = inF;
		}*/
		/*public function get f():Number
		{
			return _g + _h;
		}

		public function set g(value:Number):void
		{
			_g = value;
		}

		public function get g():Number
		{
			return _g;
		}

		public function set h(value:Number):void
		{
			_h = value;
		}

		public function get h():Number
		{
			return _h;
		}*/

		/*public function set parent(inParent:AStarNode):void
		{
			_parent = inParent;
		}

		public function get parent():AStarNode
		{
			return _parent;
		}*/
	}
}
