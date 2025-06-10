/*
 * C FFI bindings for Lean-Python Hypothesis bridge
 */

#include <Python.h>
#include <lean/lean.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global Python interpreter state
static int python_initialized = 0;
static PyObject* bridge_module = NULL;
static PyObject* bridge_instance = NULL;

// Initialize Python interpreter and load bridge module
static int init_python_bridge() {
    if (python_initialized) return 1;
    
    Py_Initialize();
    if (!Py_IsInitialized()) {
        fprintf(stderr, "Failed to initialize Python\n");
        return 0;
    }
    
    // Add current directory to Python path
    PyRun_SimpleString("import sys; sys.path.insert(0, '.')");
    
    // Import our bridge module
    bridge_module = PyImport_ImportModule("leanhypothesis.bridge");
    if (!bridge_module) {
        PyErr_Print();
        fprintf(stderr, "Failed to import leanhypothesis.bridge\n");
        return 0;
    }
    
    // Create bridge instance
    PyObject* bridge_class = PyObject_GetAttrString(bridge_module, "LeanBridge");
    if (!bridge_class) {
        fprintf(stderr, "Failed to get LeanBridge class\n");
        return 0;
    }
    
    bridge_instance = PyObject_CallObject(bridge_class, NULL);
    Py_DECREF(bridge_class);
    
    if (!bridge_instance) {
        PyErr_Print();
        fprintf(stderr, "Failed to create LeanBridge instance\n");
        return 0;
    }
    
    python_initialized = 1;
    return 1;
}

// Generate test data via Python Hypothesis
lean_obj_res lean_hypothesis_generate_data(lean_obj_arg strategy_name, uint32_t num_examples, lean_obj_arg /* world */) {
    if (!init_python_bridge()) {
        return lean_io_result_mk_error(lean_mk_string("Failed to initialize Python bridge"));
    }
    
    const char* strategy_c = lean_string_cstr(strategy_name);
    
    PyObject* method = PyObject_GetAttrString(bridge_instance, "generate_test_data");
    if (!method) {
        return lean_io_result_mk_error(lean_mk_string("Failed to get generate_test_data method"));
    }
    
    PyObject* args = PyTuple_New(2);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(strategy_c));
    PyTuple_SetItem(args, 1, PyLong_FromUnsignedLong(num_examples));
    
    PyObject* result = PyObject_CallObject(method, args);
    Py_DECREF(method);
    Py_DECREF(args);
    
    if (!result) {
        PyErr_Print();
        return lean_io_result_mk_error(lean_mk_string("Python call failed"));
    }
    
    const char* result_str = PyUnicode_AsUTF8(result);
    lean_object* lean_result = lean_mk_string(result_str);
    Py_DECREF(result);
    
    return lean_io_result_mk_ok(lean_result);
}

// Run property test via Python
lean_obj_res lean_hypothesis_run_test(lean_obj_arg strategy_name, lean_obj_arg property_fn, uint32_t num_tests, lean_obj_arg /* world */) {
    if (!init_python_bridge()) {
        return lean_io_result_mk_error(lean_mk_string("Failed to initialize Python bridge"));
    }
    
    const char* strategy_c = lean_string_cstr(strategy_name);
    const char* property_c = lean_string_cstr(property_fn);
    
    PyObject* method = PyObject_GetAttrString(bridge_instance, "run_property_test");
    if (!method) {
        return lean_io_result_mk_error(lean_mk_string("Failed to get run_property_test method"));
    }
    
    PyObject* args = PyTuple_New(3);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(strategy_c));
    PyTuple_SetItem(args, 1, PyUnicode_FromString(property_c));
    PyTuple_SetItem(args, 2, PyLong_FromUnsignedLong(num_tests));
    
    PyObject* result = PyObject_CallObject(method, args);
    Py_DECREF(method);
    Py_DECREF(args);
    
    if (!result) {
        PyErr_Print();
        return lean_io_result_mk_error(lean_mk_string("Python call failed"));
    }
    
    const char* result_str = PyUnicode_AsUTF8(result);
    lean_object* lean_result = lean_mk_string(result_str);
    Py_DECREF(result);
    
    return lean_io_result_mk_ok(lean_result);
}

// Register custom strategy
lean_obj_res lean_hypothesis_register_strategy(lean_obj_arg name, lean_obj_arg spec, lean_obj_arg /* world */) {
    if (!init_python_bridge()) {
        return lean_io_result_mk_error(lean_mk_string("Failed to initialize Python bridge"));
    }
    
    const char* name_c = lean_string_cstr(name);
    const char* spec_c = lean_string_cstr(spec);
    
    PyObject* method = PyObject_GetAttrString(bridge_instance, "register_custom_strategy");
    if (!method) {
        return lean_io_result_mk_error(lean_mk_string("Failed to get register_custom_strategy method"));
    }
    
    PyObject* args = PyTuple_New(2);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(name_c));
    PyTuple_SetItem(args, 1, PyUnicode_FromString(spec_c));
    
    PyObject* result = PyObject_CallObject(method, args);
    Py_DECREF(method);
    Py_DECREF(args);
    
    if (!result) {
        PyErr_Print();
        return lean_io_result_mk_error(lean_mk_string("Python call failed"));
    }
    
    const char* result_str = PyUnicode_AsUTF8(result);
    lean_object* lean_result = lean_mk_string(result_str);
    Py_DECREF(result);
    
    return lean_io_result_mk_ok(lean_result);
}

// Cleanup Python interpreter (called at program termination)
void cleanup_python_bridge() {
    if (python_initialized) {
        if (bridge_instance) {
            Py_DECREF(bridge_instance);
            bridge_instance = NULL;
        }
        if (bridge_module) {
            Py_DECREF(bridge_module);
            bridge_module = NULL;
        }
        Py_Finalize();
        python_initialized = 0;
    }
}
