package tink.lang.macros;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
import tink.macro.build.Constructor;
import tink.macro.build.Member;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

class PropBuilder {
	static public inline var FULL = ':prop';
	static public inline var READ = ':read';
	
	static public function process(ctx) {
		new PropBuilder(ctx.has, ctx.add).processMembers(ctx.members);
	}
	static public function make(m:Member, t:ComplexType, getter:Expr, setter:Null<Expr>, hasField:String->Bool, addField:Member->Member, ?e:Expr) {
		var get = 'get_' + m.name,
			set = if (setter == null) 'null' else 'set_' + m.name;
			
		if (!hasField(get))	
			addField(Member.getter(m.name, getter, t)).isStatic = m.isStatic; 	
		if (setter != null && !hasField(set))
			addField(Member.setter(m.name, setter, t)).isStatic = m.isStatic;
		
		m.kind = FProp(get, set, t, e);
		m.publish();
		return m;
	}
	var hasField:String->Bool;
	var addField:Member->Member;
	function new(hasField, addField) {
		this.hasField = hasField;
		this.addField = addField;
	}
	function processMembers(members:Array<Member>) {
		for (member in members)
			switch (member.kind) {
				case FVar(t, e):					
					var name = member.name;
					
					switch (member.extractMeta(READ)) {
						case Success(tag):
							member.disallowMeta(FULL, READ);	
							var get = 
								switch (tag.params.length) {
									case 0, 1: 
										[tag.params[0], '_'.resolve(tag.pos)];
									default: 
										tag.pos.error('too many arguments');
								}
							member.addMeta(FULL, tag.pos, get);
						default:
					}
					switch (member.extractMeta(FULL)) {
						case Success(tag):
							var getter = null,
								setter = null,
								field = ['this', name].drill(tag.pos);
							switch (tag.params.length) {
								case 0:
									getter = field;
									setter = field.assign('param'.resolve());
								case 1: 
									getter = field;
									setter = field.assign(tag.params[0], tag.params[0].pos);
								case 2: 
									getter = tag.params[0];
									if (getter == null)
										getter = field;
										
									setter = tag.params[1];
									if (setter.isWildcard()) setter = null;
								default:
									tag.pos.error('too many arguments');
							}
							make(member, t, getter, setter, hasField, addField, e);
						default:	
					}												
				default: //maybe do something here?
			}		
	}
}