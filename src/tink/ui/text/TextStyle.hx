package tink.ui.text;
import tink.lang.Cls;

/**
 * ...
 * @author back2dos
 */

class TextStyle implements Cls {
	@:bindable var font = '_sans'; 
	@:bindable var color = 0x000000;
	@:bindable var bold = false;
	@:bindable var italic = false;
	@:bindable var size = 12.0;
	public function new() { }
}