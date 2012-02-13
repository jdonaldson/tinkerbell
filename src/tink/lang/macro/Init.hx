package tink.lang.macro;

import haxe.macro.Expr;
import tink.macro.build.Constructor;
import tink.macro.build.Member;
/**
 * ...
 * @author back2dos
 */
using tink.macro.tools.ExprTools;

class Init {
	static public function process(ctx) {
		new Init(ctx.getCtor()).init(ctx.members);
	}
	var constructor:Constructor;
	function new(constructor) {
		this.constructor = constructor;
	}
	function init(members:Array<Member>) {
		for (member in members) {
			if (!member.isStatic)
				switch (member.kind) {
					case FVar(t, e):						
						if (e != null) {
							member.kind = FVar(t);
							initMember(member, e);
						}
					case FProp(get, set, t, e):
						if (e != null) {
							member.kind = FProp(get, set, t);
							initMember(member, e);
						}						
					default:
				}
		}
	}
	function initMember(member:Member, e:Expr) {
		var init = null,
			def = null;
		if (!e.isWildcard())
			switch (e.expr) {
				case EParenthesis(e): def = e;
				default: init = e;
			}
		this.constructor.init(member.name, e.pos, init, def);		
	}
}