package common.iso.view.display
{
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.crimetown.view.iso.JobProgressEvent;
	import com.raka.crimetown.view.iso.JobableObjectEvent;
	import com.raka.iso.objects.IIsoMapObject;
	
	import common.ui.view.overlay.EnemyOverlay;
	
	import flash.display.DisplayObject;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	
	/**
	 * 
	 * @author Victoria Cail
	 * 
	 * IsoState sits between the IsoBase and IsoCharacter & IsoBuilding classes, 
	 * tracking the current state of the object. The state is used to determine 
	 * when the object should glow (highlight), become semi-transparent, or show
	 * a "tooltip."
	 * 
	 * Mouse states are updated by the IsoControllerMouse.
	 * 
	 */		
	
	public class IsoState extends IsoBase implements IMousableIso
	{
		// CONSTANTS
		protected const ALPHA:Number = 0.6; 
		
		// STATES
		public static const FULL_ALPHA:Number = 1;
		public static const HOME_HIGHLIGHT_FILTER:GlowFilter = new GlowFilter(0x00FF00, 1, 2, 2, 16, BitmapFilterQuality.LOW);
		public static const JOB_HIGHLIGHT_FILTER:GlowFilter = HOME_HIGHLIGHT_FILTER;
		public static const TRANSLUCENT_ALPHA:Number = AppConfig.game.getNumberValue(GameConfigEnum.MAP_OBJECT_OVERLAP_ALPHA);
		public static const TOOLTIP_VISIBLE:Boolean = false;
		
		// ATTRIBUTES
		protected var _isJobActive:Boolean = false;
		protected var _isJobQueued:Boolean = false;		
		protected var _isMouseOverMe:Boolean;	
		private var _mouseActive:Boolean = true;

		public function IsoState() {}
		
		//----------------------------
		// MOUSE EVENT HANDLERS
		// (called from IsoControllerMouse)
		//----------------------------
		
		public function mouseOver():void
		{
			_isMouseOverMe = true;
			
			updateState();
		}
		
		public function mouseOut():void
		{
			_isMouseOverMe = false;
			
			updateState();
		}
		
		public function mouseDown():void {}
		
		public function mouseUp():void {}
		
		//----------------------------
		// JOB STATUS CHANGE METHODS
		// (called from queueing system)
		//----------------------------
		
		public function cancelJob():void
		{
			// when a job is explicitly canceled, it's safe to clear the queued and active job fields
			_isJobQueued = false;
			_isJobActive = false;
			updateState();
		}
		
		public function disposeJob():void
		{
			// multiclick iso targets may still have queued or active jobs when one of their 
			// jobs is disposed, so don't change _isJobQueued or _isJobActive here
			updateState();
		}
		
		public function finishJob():void
		{
			_isJobActive = false;
			updateState();
		}
		
		public function queueJob():void
		{
			_isJobQueued = true;
			updateState();
		}
		
		public function unqueueJob():void
		{
			_isJobQueued = false;
			updateState();
		}
		
		public function startJob():void
		{
			_isJobQueued = false;
			_isJobActive = true;
			updateState();
		}

		//----------------------------
		// FX METHODS
		//----------------------------
		
		protected function showHighlight(show:Boolean):void
		{
			if (!_assetDisplay) return;
			if (show)
			{
				var filter:GlowFilter = IsoState.HOME_HIGHLIGHT_FILTER;
				
				_assetDisplay.filters = [filter];
			}
			else
				_assetDisplay.filters = [];
		}
		
		protected function showTransparency(show:Boolean):void
		{
			if (!_assetDisplay) return;
			if (show)
				_assetDisplay.alpha = ALPHA;
			else
				_assetDisplay.alpha = 1;
		}
		
		protected function showJobActive(show:Boolean):void {}
		
		protected function makeMoveable(isMoveable:Boolean):void {}

		//----------------------------
		// STATE TRACKING METHODS 
		//----------------------------
		
		protected function updateState():void
		{
			var isTransparent:Boolean = false;
			var isHighlighted:Boolean = false;
			var isAllowedToMove:Boolean = true;
			
			if(!isAlive)
			{
				isAllowedToMove = false;
			}
			else if (_isMouseOverMe)
			{
				isTransparent = false;
				isHighlighted = true;
				isAllowedToMove = false;
			}
			else if (_isJobActive)
			{
				isAllowedToMove = false;
			}
			else if (_isJobQueued)
			{
				isTransparent = true;
			}
			
			showHighlight(isHighlighted);
			showTransparency(isTransparent);
			showJobActive(_isJobActive);
			makeMoveable(isAllowedToMove);
		}
		
		//----------------------------
		// GETTERS / SETTERS 
		//----------------------------
		
		public function get isJobOrJobChainActive():Boolean
		{
			return _isJobActive;
		}
		
		public function get isMouseOverMe():Boolean
		{
			return _isMouseOverMe;
		}
		
		public function get isJobActive():Boolean
		{
			return _isJobActive;
		}
		
		public function get isAlive():Boolean
		{
			return true;
		}	
		
		public function get mouseActive():Boolean
		{
			return _mouseActive;
		}
		
		public function set mouseActive(value:Boolean):void {
			_mouseActive = value;
		}
	}
}