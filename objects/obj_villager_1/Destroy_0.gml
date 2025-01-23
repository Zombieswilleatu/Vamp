/// @desc Clean up event
// Remove priority from used list when instance is destroyed
if (variable_global_exists("used_priorities")) {
    var priority_index = ds_list_find_index(global.used_priorities, path_priority);
    if (priority_index != -1) {
        ds_list_delete(global.used_priorities, priority_index);
    }
}