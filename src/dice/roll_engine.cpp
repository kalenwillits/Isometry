#include "roll_engine.hpp"
#include "dice_algebra.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void RollEngine::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_expr", "expr"), &RollEngine::set_expr);
	ClassDB::bind_method(D_METHOD("get_eval_expr"), &RollEngine::get_expr);
	ClassDB::bind_method(D_METHOD("get_expr"), &RollEngine::get_expr);
	ClassDB::bind_method(D_METHOD("roll"), &RollEngine::roll);
	ClassDB::bind_method(D_METHOD("get_result"), &RollEngine::get_result);
	ClassDB::bind_static_method("RollEngine", D_METHOD("evaluate", "expr"), &RollEngine::evaluate);
}

RollEngine::RollEngine() : expr{}, dice_algebra{} {
}

RollEngine::RollEngine(String expr) : expr{expr} {
	dice_algebra = DiceAlgebra({*expr.utf8().get_data()});
}

RollEngine::~RollEngine() {
}

int RollEngine::set_expr(String expr) {
	this->expr = expr;
	this->dice_algebra = DiceAlgebra(expr.utf8().get_data());
	return dice_algebra.validate();
}

String RollEngine::get_expr() {
	return expr;
}


void RollEngine::roll() {
	this->dice_algebra = DiceAlgebra(expr.utf8().get_data());
	dice_algebra.eval();
}

int RollEngine::get_result() {
	return dice_algebra.get_result();
}

int RollEngine::evaluate(String expr) {
	RollEngine engine(expr);
	engine.roll();
	return engine.get_result();
}

