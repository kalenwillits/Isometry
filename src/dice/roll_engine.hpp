#ifndef GDCLASS_DICE_HPP
#define GDCLASS_DICE_HPP

#include <godot_cpp/classes/object.hpp>
#include "dice_algebra.hpp"

namespace godot {

class RollEngine : public Object {
    GDCLASS(RollEngine, Object)

protected:
    static void _bind_methods();

public:
	RollEngine();
    ~RollEngine();
	static int roll(String expr);
};
}

#endif
