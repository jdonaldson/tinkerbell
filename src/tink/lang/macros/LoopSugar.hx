package tink.lang.macros;

/**
 * ...
 * @author back2dos
 */
import haxe.macro.Expr;
import tink.macro.build.MemberTransformer;
import tink.macro.tools.AST;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
class LoopSugar {
	static public function process(ctx:ClassBuildContext) {
		for (member in ctx.members)
			switch (member.getFunction()) {
				case Success(f):
					f.expr = f.expr.transform(transformLoop);
				default:
			}
	}
	static function makeMatcher(e:Expr) {
		return switch (e.getIdent()) {
			case Success(name):
				if (name.charAt(0) == '_')
					('$' + name.substr(1)).resolve(e.pos);
				else e;
			default: e;
		}
	}
	static var INTERVAL_LOOP_W_STEP = (macro for (eval__i += _step in _start..._end) _body).transform(makeMatcher);
	static var INTERVAL_LOOP_W_NEG_STEP = (macro for (eval__i -= _step in _start..._end) _body).transform(makeMatcher);
	static function stepLoop(loopVar:String, start:Expr, end:Expr, step:Expr, body:Expr) {
		var update = loopVar.define(
			OpAssignOp(OpAdd).make(loopVar.resolve(), macro __tink__step, step.pos)
		);
		var loopVarExpr = loopVar.resolve(start.pos);
		var first = body.transform(function (e:Expr) {
			return 
				switch (e.expr) {
					case EBreak: macro {
						__tink__count = 0;
						continue;
					}
					default: e;
				}
		});
		first = macro if (__tink__count >= 0) do $first while (false);
		return [	
			'__tink__step'.define(step),
			loopVar.define(start),
			'__tink__count'.define(macro Math.ceil(($end - $loopVarExpr) / __tink__step) - 1),
			first,
			macro for (__tink__counter in 0...__tink__count) {
				$update;
				$body;
			}
		].toBlock();
	}
	static function adjust(e:Expr, pos:Position) {
		return macro {
			var v = $e;
			v += __tink__step;
			v;
		}
	}
	static function transformLoop(e:Expr) {
		switch (AST.match(e, INTERVAL_LOOP_W_STEP)) {
			case Success(r):
				return stepLoop(r.strings.i, r.exprs.start, r.exprs.end, r.exprs.step, r.exprs.body);
			default: 
		}
		switch (AST.match(e, INTERVAL_LOOP_W_NEG_STEP)) {
			case Success(r):
				return stepLoop(
					r.strings.i, 
					adjust(r.exprs.start, r.exprs.step.pos), 
					adjust(r.exprs.end, r.exprs.step.pos), 
					EUnop(OpNeg, false, r.exprs.step).at(r.exprs.step.pos), 
					r.exprs.body
				);
			default: 
		}
		return e;
	}
}