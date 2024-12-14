#include "roll_engine.hpp"
#include "dice_algebra.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

RollEngine::RollEngine() {};
RollEngine::~RollEngine() {};

void RollEngine::_bind_methods() {
	ClassDB::bind_static_method("RollEngine", D_METHOD("roll", "expr"), &RollEngine::roll);
}

int RollEngine::roll(String expr) {
	DiceAlgebra dice_algebra(expr.utf8().get_data());
	dice_algebra.eval();
	return dice_algebra.get_result();
}

