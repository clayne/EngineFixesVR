/**
 * The Slider displays a numerical value in range, with a thumb to represent the value, as well as modify it via dragging.

	<b>Inspectable Properties</b>
	The inspectable properties of the Slider component:<ul>
	<li><i>visible</i>: Hides the component if set to false.</li>
	<li><i>disabled</i>: Disables the component if set to true.</li>
	<li><i>value</i>: The numeric value displayed by the Slider.</li>
	<li><i>minimum</i>: The minimum value of the Slider’s range.</li>
	<li><i>maximum</i>: The maximum value of the Slider’s range.</li>
	<li><i>snapping</i>: If set to true, then the thumb will snap to values that are multiples of snapInterval.</li>
	<li><i>snapInterval</i>: The snapping interval which determines which multiples of values the thumb snaps to. It has no effect if snapping is set to false.</li>
	<li><i>liveDragging</i>: If set to true, then the Slider will generate a change event when dragging the thumb. If false, then the Slider will only generate a change event after the dragging is over.</li>
	<li><i>offsetLeft</i>: Left offset for the thumb. A positive value will push the thumb inward.</li>
	<li><i>offsetRight</i>: Right offset for the thumb. A positive value will push the thumb inward.</li>
	<li><i>enableInitCallback</i>: If set to true, _global.CLIK_loadCallback() will be fired when a component is loaded and _global.CLIK_unloadCallback will be called when the component is unloaded. These methods receive the instance name, target path, and a reference the component as parameters.  _global.CLIK_loadCallback and _global.CLIK_unloadCallback should be overriden from the game engine using GFx FunctionObjects.</li>
	<li><i>soundMap</i>: Mapping between events and sound process. When an event is fired, the associated sound process will be fired via _global.gfxProcessSound, which should be overriden from the game engine using GFx FunctionObjects.</li></ul>

	<b>States</b>
	Like the ScrollIndicator and the ScrollBar, the Slider does not have explicit states. It uses the states of its child elements, the thumb and track Button components.

	<b>Events</b>
	All event callbacks receive a single Object parameter that contains relevant information about the event. The following properties are common to all events. <ul>
	<li><i>type</i>: The event type.</li>
	<li><i>target</i>: The target that generated the event.</li></ul>

	The events generated by the Slider component are listed below. The properties listed next to the event are provided in addition to the common properties.<ul>
	<li><i>show</i>: The component’s visible property has been set to true at runtime.</li>
	<li><i>hide</i>: The component’s visible property has been set to false at runtime.</li>
	<li><i>focusIn</i>: The component has received focus.</li>
	<li><i>focusOut</i>: The component has lost focus.</li>
	<li><i>change</i>: The Slider value has changed.</li></ul>

 */


import gfx.controls.Button;
import gfx.core.UIComponent;
import gfx.ui.InputDetails;
import gfx.ui.NavigationCode;
import gfx.utils.Constraints;


[InspectableList("disabled", "visible", "liveDragging", "minimum", "maximum", "value", "snapping", "snapInterval", "offsetLeft", "offsetRight", "enableInitCallback", "soundMap")]
class gfx.controls.Slider extends UIComponent
{
	/* PUBLIC VARIABLES */

	/** Determines if the Slider dispatches "change" events while dragging the thumb, or only after dragging is complete. */
	[Inspectable(defaultValue="true")]
	public var liveDragging: Boolean = false;
	/** The mouse state of the button.  Mouse states can be "default", "disabled". */
	public var state: String = "default";
	/** Mapping between events and sound process */
	[Inspectable(type="Object", defaultValue="theme:default,focusIn:focusIn,focusOut:focusOut,change:change")]
	public var soundMap: Object = { theme:"default", focusIn:"focusIn", focusOut:"focusOut", change:"change" };


	/* PRIVATE VARIABLES */

	private var _minimum: Number = 0;
	private var _maximum: Number = 10;
	private var _value: Number = 0;
	private var _snapInterval: Number = 1;
	private var _snapping: Boolean = false;
	private var dragOffset: Object;
	private var constraints: Constraints;
	private var trackDragMouseIndex: Number;
	private var trackPressed: Boolean = false;
	private var thumbPressed: Boolean = false;

	[Inspectable(defaultValue=0, verbose=1)]
	private var offsetLeft: Number = 0;
	[Inspectable(defaultValue=0, verbose=1)]
	private var offsetRight: Number = 0;


	/* STAGE ELEMENTS */

	/** A reference to the thumb symbol in the Slider, used to display the slider {@code value}, and change the {@code value} via dragging. */
	public var thumb: Button;
	/** A reference to the track symbol in the Slider used to display the slider range, but also to jump to a specific value via clicking. */
	public var track: Button;


	/* INITIALIZATION */

	/**
	 * The constructor is called when a Slider or a sub-class of Slider is instantiated on stage or by using {@code attachMovie()} in ActionScript. This component can <b>not</b> be instantiated using {@code new} syntax. When creating new components that extend Slider, ensure that a {@code super()} call is made first in the constructor.
	 */
	public function Slider()
	{
		super();
		tabChildren = false;
		focusEnabled = tabEnabled = !_disabled;
	}


	/* PUBLIC FUNCTIONS */

	/**
	 * The maximum number the {@code value} can be set to.
	 */
	[Inspectable(defaultValue="10")]
	public function get maximum(): Number
	{
		return _maximum;
	}


	public function set maximum(value: Number): Void
	{
		_maximum = value;
		invalidate();
	}


	/**
	 * The minimum number the {@code value} can be set to.
	 */
	[Inspectable(defaultValue="0")]
	public function get minimum(): Number
	{
		return _minimum;
	}


	public function set minimum(value: Number): Void
	{
		_minimum = value;
		invalidate();
	}


	/**
	 * The value of the slider between the {@code minimum} and {@code maximum}.
	 * @see #maximum
	 * @see #minimum
	 */
	[Inspectable(defaultValue="0")]
	public function get value(): Number
	{
		return _value;
	}


	public function set value(value: Number): Void
	{
		_value = lockValue(value);
		invalidate();
	}


	/**
	 * Disable this component. Focus (along with keyboard events) and mouse events will be suppressed if disabled.
	 */
	[Inspectable(defaultValue="false", verbose="1")]
	public function get disabled(): Boolean
	{
		return _disabled;
	}


	public function set disabled(value: Boolean): Void
	{
		if (_disabled == value) {
			return;
		}

		super.disabled = value;
		focusEnabled = tabEnabled = !_disabled;
		if (!initialized) {
			return;
		}

		thumb.disabled = track.disabled = _disabled;
		invalidate();
	}


	/**
	 * The {@code value} of the {@code Slider}, to make it polymorphic with a {@link ScrollIndicator}.
	 */
	public function get position(): Number
	{
		return _value;
	}


	public function set position(value: Number): Void
	{
		this.value = value;
	}


	/**
	 * Whether or not the {@code value} "snaps" to a rounded value. When {@code snapping} is {@code true}, the value can only be set to multiples of the {@code snapInterval}.
	 * @see #snapInterval
	 */
	[Inspectable(defaultValue="false")]
	public function get snapping(): Boolean
	{
		return _snapping;
	}


	public function set snapping(value: Boolean): Void
	{
		_snapping = value;
		invalidate();
	}


	/**
	 * The interval to snap to when {@code snapping} is {@code true}.
	 * @see #snapping
	 */
	[Inspectable(defaultValue="1")]
	public function get snapInterval(): Number
	{
		return _snapInterval;
	}


	public function set snapInterval(value: Number): Void
	{
		_snapInterval = value;
		invalidate();
	}


	public function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		var keyPress: Boolean = (details.value == "keyDown" || details.value == "keyHold");
		// The value will increment by the snapInterval, but not snap to it if it wasn't already.
		switch (details.navEquivalent) {
			case NavigationCode.RIGHT:
				if (keyPress) {
					value += _snapInterval;
					dispatchEventAndSound( { type: "change" } );
				}
				break;
			case NavigationCode.LEFT:
				if (keyPress) {
					value -= _snapInterval;
					dispatchEventAndSound( { type: "change" } );
				}
				break;

			case NavigationCode.HOME:
				if (!keyPress) {
					value = minimum;
					dispatchEventAndSound( { type: "change" } );
				}
				break;
			case NavigationCode.END:
				if (!keyPress) {
					value = maximum;
					dispatchEventAndSound( { type: "change" } );
				}
				break;
			default:
				return false;
		}
		return true; // Only reaches here when the key type is handled.
	}


	/** @exclude */
	public function toString(): String
	{
		return "[Scaleform Slider " + _name + "]";
	}


	/* PRIVATE FUNCTIONS */

	private function configUI(): Void
	{
		thumb.addEventListener("press", this, "beginDrag");
		track.addEventListener("press", this, "trackPress");
		thumb.focusTarget = track.focusTarget = this;
		thumb.disabled = track.disabled = _disabled;

		thumb.lockDragStateChange = true;

		initSize(); // Slider uses scaling elements.
		constraints = new Constraints(this);
		constraints.addElement(track, Constraints.LEFT | Constraints.RIGHT);

		Mouse.addListener(this);
	}


	private function draw(): Void
	{
		// Change frame based on state
		gotoAndPlay(_disabled ? "disabled" : (_focused ? "focused" : "default"));

		if (!_disabled) {
			if (!thumbPressed) {
				thumb.displayFocus = (_focused != 0);
			}
			if (!trackPressed) {
				track.displayFocus = (_focused != 0);
			}
		}

		constraints.update(__width, __height);
		updateThumb();
	}


	private function changeFocus(): Void
	{
		invalidate();
	}


	private function updateThumb(): Void
	{
		if (_disabled) {
			return;
		}

		var trackWidth: Number = (__width - offsetLeft - offsetRight);
		thumb._x = ((_value - _minimum) / (_maximum - _minimum) * trackWidth) - thumb._width / 2 + offsetLeft;
	}


	private function beginDrag(event: Object): Void
	{
		thumbPressed = true;
		Selection.setFocus(thumb, event.controllerIdx);
		dragOffset = {x: _xmouse - thumb._x - thumb._width / 2};
		onMouseMove = doDrag;
		onMouseUp = endDrag;
	}


	private function doDrag(): Void
	{
		var thumbPosition: Number = _xmouse - dragOffset.x;
		var trackWidth: Number = (__width - offsetLeft - offsetRight);
		var newValue: Number = lockValue( (thumbPosition - offsetLeft) / trackWidth * (_maximum-_minimum) + _minimum);
		updateThumb();
		if (value == newValue) {
			return;
		}

		_value = newValue;
		if (liveDragging) {
			dispatchEventAndSound( { type: "change" } );
		}
	}


	private function endDrag(): Void
	{
		delete onMouseUp;
		delete onMouseMove;
		if (!liveDragging) {
			dispatchEventAndSound( { type: "change" } );
		}

		// If the thumb became draggable on a track press,
		// manually generate the thumb events.
		if (trackDragMouseIndex != undefined) {
			if (!thumb.hitTest(_root._xmouse, _root._ymouse)) {
				thumb.onReleaseOutside(trackDragMouseIndex);
			} else {
				thumb.onRelease(trackDragMouseIndex);
			}
		}
		delete trackDragMouseIndex;
		thumbPressed = false;
		trackPressed = false;
		invalidate();
	}


	private function trackPress(e: Object): Void
	{
		trackPressed = true;
		Selection.setFocus(track, e.controllerIdx);
		var trackWidth: Number = (__width - offsetLeft - offsetRight);
		var newValue: Number = lockValue((_xmouse - offsetLeft) / trackWidth * (_maximum-_minimum) + _minimum);
		if (value == newValue) {
			return;
		}

		value = newValue;
		if (liveDragging) {
			dispatchEventAndSound( { type: "change" } );
		}

		// Pressing on the track moves the grip to the cursor
		// and the thumb becomes draggable.
		trackDragMouseIndex = e.controllerIdx;
		thumb.onPress(trackDragMouseIndex);
		dragOffset = {x: 0};
	}


	// Ensure the value is in range and snap it to the snapInterval
	private function lockValue(value: Number): Number
	{
		value = Math.max(_minimum, Math.min(_maximum, value));
		if (!snapping) {
			return value;
		}
		return Math.round(value / snapInterval) * snapInterval;
	}


	private function scrollWheel(delta: Number): Void
	{
		if (_focused) {
			value -= delta * _snapInterval;
			dispatchEventAndSound( { type: "change" } );
		}
	}
}
