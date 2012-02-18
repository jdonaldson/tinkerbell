package tink.tween;

/**
 * ...
 * @author back2dos
 */

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.macro.tools.AST;
	import haxe.macro.Type;
	import tink.macro.tools.TypeTools;
	import tink.tween.plugins.macros.PluginMap;
	
	using tink.macro.tools.MacroTools;
	using tink.core.types.Outcome;
	using StringTools;
#end
class Tweener {
	#if macro
		static var ITERABLE = 'Iterable'.asTypePath([TPType('Dynamic'.asTypePath())]);
		static function makeHandler(body:Expr, targetType:Type) {
			return 
				body.func(
					['tween'.toArg('tink.tween.Tween'.asTypePath([TPType(targetType.toComplex())]))]
					, false
				).toExpr(body.pos);
		}
	#end
	@:macro static public function tween(exprs:Array<Expr>) {
		if (exprs.length == 0) 
			Context.currentPos().error('at least one argument required');
		var target = exprs.shift();
		var targetType = target.typeof().data();
		#if debug 
			switch (targetType) {
				case TDynamic(_): 
						Context.warning('Type appears to be Dynamic. Accessors will not be called while accessing properties. This warning is only issued with -debug', target.pos);
				default:
			}
		#end
		var id = targetType.register().toExpr(target.pos),
			tmp = String.tempName();
		
		var ret = [tmp.define(AST.build(new tink.tween.Tween.TweenParams<haxe.macro.MacroType < (tink.macro.tools.TypeTools.getType($id)) >>()))];//just to be sure
		
		for (e in exprs) {
			var op = OpAssign.get(e).data();
			var name = op.e1.getIdent().data();
			ret.push(
				if (name.charAt(0) == '$') {
					var e = 
						if (name.substr(0,3) == '$on') 
							switch (op.e2.typeof()) {
								case Success(t):
									switch (t.reduce()) {
										case TFun(_, _): op.e2;
										default: makeHandler(op.e2, targetType);
									}
								default:
									makeHandler(op.e2, targetType);
							}
						else op.e2;
					tmp.resolve(op.pos).field(name.substr(1), op.e1.pos).assign(e, op.pos);
				}
				else {
					var atom = 
						switch (target.field(name).typeof()) {
							//TODO: with the current implementation, the target value is determined when the tween starts, not at definition time. This can lead to undesired behaviour.
							case Success(_):
								AST.build(
									function (tmpTarget) {
										if (false) tmpTarget.eval__name = .0;//we need this to make the type inferrer understand, that the field provides write access, but the optimizer will throw this out for us
										var tmpStart:Float = tmpTarget.eval__name;
										var tmpDelta = $(op.e2) - tmpStart;
										return
											function (amplitude:Float) {
												tmpTarget.eval__name = tmpStart + tmpDelta * amplitude;
											}
									},			
									op.pos
								);
							case Failure(f):
								var tp = PluginMap.getPluginFor(target, name);
								if (tp == null) 
									f.throwSelf();
								else {
									var tmp = String.tempName();
									var inst = ENew(tp, [tmp.resolve(), op.e2]).at(op.e1.pos).field('update', op.pos);
									inst.func([tmp.toArg()]).toExpr(op.pos);
								}
						}
					AST.build(eval__tmp.addAtom("eval__name", $atom), op.pos);
						
				}
			);
		}
		ret.push(AST.build(eval__tmp.start($target)));
		return ret.toBlock();			
	}
}