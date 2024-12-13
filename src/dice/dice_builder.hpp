#ifndef GDCLASS_DICE_BUILDER_HPP
#define GDCLASS_DICE_BUILDER_HPP

#include <godot_cpp/classes/node.hpp>

namespace godot {

class DiceBuilder : public Node {
    GDCLASS(DiceBuilder, Node)

private:
	Dice obj;

protected:
    static void _bind_methods();

public:
    DiceBuilder();
    ~DiceBuilder();
	DiceBuilder expression(const std::string value);
	DiceBuilder target(Node *p_value);
	DiceBuilder caller(Node *p_value);
	Dice build();
};

}

#endif
