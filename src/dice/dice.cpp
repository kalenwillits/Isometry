#include "dice.hpp"
#include "dice_algebra.hpp"
#include "dice_builder.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Dice::_bind_methods() {
	ClassDB::bind_static_method("Dice", D_METHOD("builder"), &Dice::evaluate);
	ClassDB::bind_method(D_METHOD("evaluate"), &Dice::evaluate);
}

Dice::Dice() : expression{}, p_target{}, p_caller{} {
}

Dice::~Dice() {
}

static DiceBuilder Dice::builder() {
	return DiceBuilder{};
}

int Dice::evaluate() {
	DiceAlgebra dice_algebra = DiceAlgebra(this->expression);
	dice_algebra.eval();
	return dice_algebra.get_result();
}
