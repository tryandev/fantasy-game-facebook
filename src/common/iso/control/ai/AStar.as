package common.iso.control.ai
{
	import com.raka.crimetown.model.game.Area;
	
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoTile;
	import common.test.debug.FPS;

	public class AStar
	{
		private var _map:IsoMap;
		private var _nodeStart:AStarNode;
		private var _nodesGoal:Array;
		private var _openArray:Array;
		private var _openObj:Object;
		private var _closedObj:Object;

		public function AStar(inMap:IsoMap)
		{
			_map = inMap;
		}

		public function dispose():void
		{
			_map = null;

			_nodeStart = null;
			_nodesGoal = null;

			_openArray = null;
			_closedObj = null;
		}

		private function nodeDistance(inNodeA:AStarNode, inNodeB:AStarNode):Number
		{
			var isoXDiff:Number = inNodeB.isoX - inNodeA.isoX;
			var isoYDiff:Number = inNodeB.isoY - inNodeA.isoY;
			return Math.sqrt(isoXDiff * isoXDiff + isoYDiff * isoYDiff);
		}
		
		private function nodeDistanceArray(inNode:AStarNode, inArray:Array):Number {
			var shortest:Number = Infinity;
			var tempDistance:Number = Infinity;
			for each(var node:AStarNode in inArray) {
				tempDistance = nodeDistance(inNode, node);
				if (tempDistance < shortest) {
					shortest = tempDistance;
				}
			}
			return shortest;
		}
		
		public function search(startNode:AStarNode, goalNodes:Array):AStarNode {
			//trace('astar start');
			//FPS.timerGet();
			_openArray = new Array();
			_openObj = new Object();
			_closedObj = new Object();
			
			_nodeStart = startNode;
			_nodesGoal = goalNodes;
			
			_nodeStart.parent = null;
			_nodeStart.g = 0;
			_nodeStart.h = nodeDistanceArray(_nodeStart, _nodesGoal);
			
			_openArray.push(_nodeStart);
			_openObj[_nodeStart.isoX + "_" + _nodeStart.isoY] = _nodeStart;
			
			while (_openArray.length > 0){
				_openArray.sortOn("f", Array.DESCENDING | Array.NUMERIC);
				
				var o:AStarNode = _openArray.pop();
				delete _openObj[o.isoX + "_" + o.isoY];
				
				if (nodeDistanceArray(o, _nodesGoal) == 0) {
					//FPS.timerGet();
					//trace('astar end');
					return o;
				}
				
				_closedObj[o.isoX + "_" + o.isoY] = o;
				o.neighbors = getNodeNeighbors(o);
				for each (var n:AStarNode in o.neighbors) {
					if (_closedObj[n.isoX + "_" + n.isoY] != null) {
						continue;
					}
					var newScoreG:Number = o.g + nodeDistance(o, n) + turnPenalty(n,o);
					var newScoreBetter:Boolean;
					if (_openObj[n.isoX + "_" + n.isoY] == null) {
						_openArray.push(n);
						_openObj[n.isoX + "_" + n.isoY] = n;
						newScoreBetter = true;
					} else if (newScoreG < n.g) {
						newScoreBetter = true;
					} else {
						newScoreBetter = false;
					}
					if (newScoreBetter) {
						n.parent = o;
						n.g = newScoreG;
						n.h = nodeDistanceArray(n, _nodesGoal);
						n.f = n.g + n.h;
					}
				}
			}
			return null;
		}
		
		private function turnPenalty(inNodeChild:AStarNode, inNodeParent:AStarNode):Number {
			var nodeGrandparent:AStarNode = inNodeParent.parent;
			if (nodeGrandparent == null) {
				return 0;
			}
			var dxParent:Number = inNodeParent.isoX - nodeGrandparent.isoX;
			var dyParent:Number = inNodeParent.isoY - nodeGrandparent.isoY;
			var dxChild:Number = inNodeChild.isoX - inNodeParent.isoX;
			var dyChild:Number = inNodeChild.isoY - inNodeParent.isoY;
			if ((dxParent == dxChild) && (dyParent == dyChild)) {
				return 0;
			}
			return 0.000001;
		}
		
		public function compareNodeScore(inNodeA:AStarNode, inNodeB:AStarNode):Boolean
		{
			return inNodeA.f < inNodeB.f;
		}

		private function inObjectArray(inNode:AStarNode, inObject:Object):Boolean
		{
			return (inObject[inNode.isoX + "_" + inNode.isoY] != null);
		}

		private function getNodeInArray(inX:int, inY:int, inArray:Array):AStarNode
		{
			for each (var arrayNode:AStarNode in inArray)
			{
				if (arrayNode.isoX == inX && arrayNode.isoY == inY)
				{
					return arrayNode;
				}
			}
			return null;
		}

		private function getNodeNeighbors(inAStarNode:AStarNode):Array
		{
			var _neighbors:Array = new Array();
			var _theoreticalNeighbors:Array = new Array();
			var inX:uint = inAStarNode.isoX;
			var inY:uint = inAStarNode.isoY;
			var subject:IsoTile = _map.getIsoTile(inX, inY);
			
			_theoreticalNeighbors.push(_map.getIsoTile(inX - 0, inY + 1));
			_theoreticalNeighbors.push(_map.getIsoTile(inX - 1, inY - 0));
			_theoreticalNeighbors.push(_map.getIsoTile(inX + 1, inY - 0));
			_theoreticalNeighbors.push(_map.getIsoTile(inX - 0, inY - 1));
			
			// this lets the algorithm path out of not free tiles
			if (_map.getIsoTileFree(inX, inY))
			{
				if (_map.getIsoTileFree(inX, inY + 1) && _map.getIsoTileFree(inX - 1, inY)) _theoreticalNeighbors.push(_map.getIsoTile(inX - 1, inY + 1));
				if (_map.getIsoTileFree(inX, inY + 1) && _map.getIsoTileFree(inX + 1, inY)) _theoreticalNeighbors.push(_map.getIsoTile(inX + 1, inY + 1));
				if (_map.getIsoTileFree(inX, inY - 1) && _map.getIsoTileFree(inX - 1, inY)) _theoreticalNeighbors.push(_map.getIsoTile(inX - 1, inY - 1));
				if (_map.getIsoTileFree(inX, inY - 1) && _map.getIsoTileFree(inX + 1, inY)) _theoreticalNeighbors.push(_map.getIsoTile(inX + 1, inY - 1));
			}
			else
			{
				_theoreticalNeighbors.push(_map.getIsoTile(inX - 1, inY + 1));
				_theoreticalNeighbors.push(_map.getIsoTile(inX + 1, inY + 1));
				_theoreticalNeighbors.push(_map.getIsoTile(inX - 1, inY - 1));
				_theoreticalNeighbors.push(_map.getIsoTile(inX + 1, inY - 1));
			}
			
			for each (var tempTile:IsoTile in _theoreticalNeighbors)
			{
				if (tempTile && (tempTile.isWalkable || !subject.isWalkable))
				{
					var newNode:AStarNode = _closedObj[tempTile.isoX + "_" + tempTile.isoY];
					if (newNode == null)
					{
						newNode = _openObj[tempTile.isoX + "_" + tempTile.isoY];
						if (newNode == null)
						{
							newNode = new AStarNode(tempTile.isoX, tempTile.isoY);
						}
					}
					_neighbors.push(newNode);
				}
			}
			return _neighbors;
		}
	}
}
