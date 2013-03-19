package flash.events;
#if (flash || display)


extern class SampleDataEvent extends Event {
	var data : flash.utils.ByteArray;
	var position : Float;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, theposition : Float = 0, ?thedata : flash.utils.ByteArray) : Void;
	static var SAMPLE_DATA : String;
}


#else
typedef SampleDataEvent = nme.events.SampleDataEvent;
#end
