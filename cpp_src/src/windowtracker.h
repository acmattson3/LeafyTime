#ifndef WINDOWTRACKER_H
#define WINDOWTRACKER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

class WindowTracker : public Node {
    GDCLASS(WindowTracker, Node)

private:
    // Add any private member variables here if needed.

protected:
    static void _bind_methods();

public:
    WindowTracker();
    ~WindowTracker();

    Array get_open_windows();
    Array get_open_applications();
};

}

#endif // WINDOWTRACKER_H
