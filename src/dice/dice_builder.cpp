#include "dice_builder.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void DiceBuilder::_bind_methods() {
	ClassDB::bind_method(D_METHOD("expression", "expression"), &Dice::expression);
	ClassDB::bind_method(D_METHOD("target", "target"), &Dice::target);
	ClassDB::bind_method(D_METHOD("build"), &Dice::build);
}

DiceBuilder::DiceBuilder() : dice{} {
}

DiceBuilder::~DiceBuilder() {
}

DiceBuilder::expression(const std::string value) {
	this->dice.expression = value;
	return this;
}

DiceBuilder::target(Node *p_value) {
	this->dice.target = p_value;
	return this;
}

DiceBuilder::caller(Node *p_value) {
	this->dice.caller = p_value;
	return this;
}

Dice DiceBuilder::build() {
	return this->dice;	
}
