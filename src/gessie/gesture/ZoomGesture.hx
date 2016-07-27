package gessie.gesture;
import gessie.core.GestureState;
import gessie.core.Touch;
import gessie.geom.Point;

/**
 * ...
 * @author vincent blanchet
 */
class ZoomGesture<T:{}> extends Gesture<T>
{
	public var slop:Float = Gesture.DEFAULT_SLOP;
	public var lockAspectRatio:Bool = true;
	
	var _touch1:Touch<T>;
	var _touch2:Touch<T>;
	var _transformVector:Point;
	var _initialDistance:Float;
	
	public function new(target:T) 
	{
		super(target);
		
		
	}
	
	public var scaleX:Float;
	public var scaleY:Float;
	
	override function onTouchBegin(touch:Touch<T>):Void
	{
		if (touchesCount > 2)
		{
			failOrIgnoreTouch(touch);
			return;
		}
		
		if (touchesCount == 1)
		{
			_touch1 = touch;
		}
		else// == 2
		{
			_touch2 = touch;
			
			_transformVector = _touch2.location.subtract(_touch1.location);
			_initialDistance = _transformVector.length;
		}
	}
	
	override function onTouchMove(touch:Touch<T>):Void
	{
		if (touchesCount < 2)
			return;
		
		var currTransformVector:Point = _touch2.location.subtract(_touch1.location);
		
		if (state == GestureState.GSPossible)
		{
			var d:Float = currTransformVector.length - _initialDistance;
			var absD:Float = d >= 0 ? d : -d;
			if (absD < slop)
			{
				// Not recognized yet
				return;
			}
			
			if (slop > 0)
			{
				// adjust _transformVector to avoid initial "jump"
				var slopVector:Point = currTransformVector.clone();
				slopVector.normalize(_initialDistance + (d >= 0 ? slop : -slop));
				_transformVector = slopVector;
			}
		}
		
		
		if (lockAspectRatio)
		{
			scaleX *= currTransformVector.length / _transformVector.length;
			scaleY = scaleX;
		}
		else
		{
			scaleX *= currTransformVector.x / _transformVector.x;
			scaleY *= currTransformVector.y / _transformVector.y;
		}
		
		_transformVector.x = currTransformVector.x;
		_transformVector.y = currTransformVector.y;
		
		updateLocation();
		
		if (state == GestureState.GSPossible)
		{
			setState(GestureState.GSBegan);
		}
		else
		{
			setState(GestureState.GSChanged);
		}
	}
	
	override function onTouchEnd(touch:Touch<T>):Void
	{
		if (touchesCount == 0)
		{
			if (state == GestureState.GSBegan || state == GestureState.GSChanged)
			{
				setState(GestureState.GSEnded);
			}
			else if (state == GestureState.GSPossible)
			{
				setState(GestureState.GSFailed);
			}
		}
		else//== 1
		{
			if (touch == _touch1)
			{
				_touch1 = _touch2;
			}
			_touch2 = null;
			
			if (state == GestureState.GSBegan || state == GestureState.GSChanged)
			{
				updateLocation();
				setState(GestureState.GSChanged);
			}
		}
	}
	
	override function resetNotificationProperties():Void
	{
		super.resetNotificationProperties();
		
		scaleX = scaleY = 1;
	}
}