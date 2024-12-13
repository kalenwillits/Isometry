#ifndef GDCLASS_DICE_HPP
#define GDCLASS_DICE_HPP

#include <godot_cpp/classes/object.hpp>
#include "dice_algebra.hpp"

namespace godot {

class Dice : public Object {
    GDCLASS(Dice, Object)

private:
	String expresion;
	Node *p_target;
	Node *p_caller;

protected:
    static void _bind_methods();

public:
	Dice();
    ~Dice();
	static DiceBuilder builder();
	int evaluate();
};

}

#endif
