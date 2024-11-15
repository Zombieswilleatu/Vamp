function cleanup_search() {
    if (variable_instance_exists(id, "my_path") && path_exists(my_path)) {
        path_delete(my_path);
    }
}