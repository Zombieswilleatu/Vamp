//////////////////////////////////////////////////////////////////////////
// scr_npc_follow
// REQUIRES: scr_handle_npc_collision
//////////////////////////////////////////////////////////////////////////

#macro MOVE_SPEED 3
#macro PATH_COOLDOWN 50            // Frames between path recalculations
#macro TARGET_MOVE_THRESHOLD 192   // Target must move this far to recalc path
#macro VELOCITY_BLEND 0.2          // How quickly to lerp velocity each frame
#macro PRIORITY_REPULSION_SCALE 1.5 // How much stronger/weaker repulsion is based on priority
#macro PATH_PRIORITY_LEVELS 3

/// @desc Initialize NPC following behavior
/// @param {Id.Instance} inst Instance to initialize
function npc_follow_init(inst) {
    var temp_priority = (argument_count > 1) ? argument[1] : 0;
    show_debug_message("npc_follow_init starting with priority: " + string(temp_priority));
    
    with (inst) {
        show_debug_message("Inside with block, about to set path_priority to: " + string(temp_priority));
        
        // Core following variables
        follow_initialized      = true;
        follow_path            = [];
        follow_path_index      = 0;
        follow_update_timer    = 0;
        follow_last_valid_path = [];
        
        // Priority
        path_priority          = temp_priority;
        show_debug_message("After setting - Instance " + string(id) + " path_priority is now: " + string(path_priority));
        
        // Path finding state
        follow_needs_path     = true;
        follow_has_valid_path = false;
        
        // Typically, you'd preserve existing target coords, so we comment these out:
        /*
        follow_target_x       = 0;
        follow_target_y       = 0;
        path_target_x         = 0;
        path_target_y         = 0;
        last_valid_target_x   = 0;
        last_valid_target_y   = 0;
        */
        
        // Movement
        follow_move_speed        = MOVE_SPEED;
        follow_current_direction = 0;
        
        // For animation system
        follow_last_move_x = 0;
        follow_last_move_y = 0;
        
        // Performance tracking
        path_retry_timer        = 0;
        last_pathfind_time      = 0;
        pathfinding_cooldown    = PATH_COOLDOWN; // e.g., 50 or similar
        
        // Movement smoothing
        vx = 0;
        vy = 0;
        
        show_debug_message("NPC_FOLLOW: Initialized follow behavior for instance " + string(id));
    }
}


/// @desc Update NPC following behavior with improved entity handling and path caching
/// @param {Id.Instance} inst Instance to update
function npc_follow_update(inst) {
    with (inst) {
        if (!variable_instance_exists(id, "follow_initialized")) {
            show_debug_message("NPC_FOLLOW: Not initialized, calling npc_follow_init()");
            npc_follow_init(id);
            return;
        }
        
        var MAX_FOLLOW_DIST = 500000;
        var WAYPOINT_REACH_DISTANCE = 8;  // Reduced from 16
        var BLOCKED_PATH_MEMORY_TIME = 60;
        var VELOCITY_MIN_SPEED = 0.1;     // Minimum speed threshold
        
        temp_current_x = bbox_left + (bbox_right - bbox_left) * 0.5;
        temp_current_y = bbox_top + (bbox_bottom - bbox_top) * 0.5;
        temp_target_x = obj_player.bbox_left + (obj_player.bbox_right - obj_player.bbox_left) * 0.5;
        temp_target_y = obj_player.bbox_top + (obj_player.bbox_bottom - obj_player.bbox_top) * 0.5;
        
        var _dist_to_target = point_distance(temp_current_x, temp_current_y, 
                                             temp_target_x, temp_target_y);
        
        follow_last_move_x = 0;
        follow_last_move_y = 0;
        
        if (path_retry_timer > 0) {
            path_retry_timer--;
        }
        
        // Track time since last path block
        if (!variable_instance_exists(id, "blocked_path_timer")) blocked_path_timer = 0;
        if (blocked_path_timer > 0) blocked_path_timer--;
        
        if (_dist_to_target > MAX_FOLLOW_DIST) {
            vx = 0;
            vy = 0;
            return;
        }
        
        // Enhanced movement checking
        var target_moved = point_distance(path_target_x, path_target_y, 
                                          temp_target_x, temp_target_y) > TARGET_MOVE_THRESHOLD;
        
        // Check for entity blocking current path
        var entity_blocking = false;
        if (follow_has_valid_path && array_length(follow_path) > 0 && blocked_path_timer <= 0) {
            entity_blocking = should_repath_for_entities(id, follow_path);
        }
        
        var need_new_path = (!follow_has_valid_path || target_moved || entity_blocking) 
                            && (_dist_to_target <= MAX_FOLLOW_DIST)
                            && (path_retry_timer <= 0);
        
        if (need_new_path) {
            if (entity_blocking) {
                show_debug_message("NPC_FOLLOW: Path blocked by entity, checking distances");
                
                var blocking_entities = check_entity_collision(id, temp_target_x, temp_target_y);
                var my_dist_to_target = point_distance(x, y, temp_target_x, temp_target_y);
                var should_yield = false;
                
                for (var i = 0; i < array_length(blocking_entities); i++) {
                    var other_entity = blocking_entities[i];
                    var their_dist = point_distance(other_entity.x, other_entity.y, 
                                                    temp_target_x, temp_target_y);
                    
                    if (their_dist <= my_dist_to_target) {
                        should_yield = true;
                        break;
                    }
                }
                
                if (should_yield) {
                    show_debug_message("NPC_FOLLOW: Further from target, considering backup");
                    // Only backup if we're very close to the blocking entity
                    var too_close = false;
                    for (var i = 0; i < array_length(blocking_entities); i++) {
                        var dist_to_blocker = point_distance(x, y, blocking_entities[i].x, blocking_entities[i].y);
                        if (dist_to_blocker < WAYPOINT_REACH_DISTANCE * 3) {
                            too_close = true;
                            break;
                        }
                    }
                    
                    if (too_close) {
                        show_debug_message("NPC_FOLLOW: Too close, backing up");
                        backup_away_from_blockers(id, blocking_entities);
                        path_retry_timer = 30;
                        blocked_path_timer = BLOCKED_PATH_MEMORY_TIME;
                        return;
                    } else {
                        // Just wait for a new path if not too close
                        path_retry_timer = floor(pathfinding_cooldown * 0.5);
                    }
                } else {
                    show_debug_message("NPC_FOLLOW: Closer to target, waiting for path to clear");
                    path_retry_timer = floor(pathfinding_cooldown * 0.25);
                }
                
                blocked_path_timer = BLOCKED_PATH_MEMORY_TIME;
            } else {
                // While waiting for path, move directly toward target
                var dir_to_target = point_direction(x, y, temp_target_x, temp_target_y);
                vx = lengthdir_x(follow_move_speed, dir_to_target);
                vy = lengthdir_y(follow_move_speed, dir_to_target);
                
                follow_current_direction = dir_to_target;
                follow_last_move_x = vx;
                follow_last_move_y = vy;
                
                try_move_along_path(id);  // Still use collision system
                
                // Try to find a cached path first
                var cached_path = find_cached_path(temp_current_x, temp_current_y, 
                                                   temp_target_x, temp_target_y);
                
                if (cached_path != undefined) {
                    show_debug_message("NPC_FOLLOW: Using cached path");
                    follow_path = cached_path;
                    follow_path_index = 0;
                    follow_has_valid_path = true;
                    path_target_x = temp_target_x;
                    path_target_y = temp_target_y;
                    path_retry_timer = pathfinding_cooldown;
                    last_valid_target_x = temp_target_x;
                    last_valid_target_y = temp_target_y;
                } else {
                    show_debug_message("NPC_FOLLOW: Need new path" + 
                                       (target_moved ? " (target moved)" : ""));
                    
                    path_target_x = temp_target_x;
                    path_target_y = temp_target_y;
                    
                    request_pathfinding(id, temp_current_x, temp_current_y, 
                                        temp_target_x, temp_target_y);
                    
                    path_retry_timer = pathfinding_cooldown;
                }
            }
        }
        
        // Movement along the path
        if (follow_has_valid_path && array_length(follow_path) > 0) {
            if (follow_path_index >= array_length(follow_path) - 1) {
                // Only switch to fallback if we're actually close to the end
                var dist_to_end = point_distance(x, y, follow_path[array_length(follow_path)-1].x, 
                                                     follow_path[array_length(follow_path)-1].y);
                if (dist_to_end < WAYPOINT_REACH_DISTANCE * 2) {
                    show_debug_message("NPC_FOLLOW: Truly at end of path");
                    follow_has_valid_path = false;
                }
                
                // Add direct movement fallback while waiting for new path
                var dir_to_target = point_direction(x, y, temp_target_x, temp_target_y);
                
                // Blend between current velocity and desired direction
                var blend_weight = 0.2;  // Adjust for smoothness
                var current_dir = point_direction(0, 0, vx, vy);
                var blended_dir = angle_lerp(current_dir, dir_to_target, blend_weight);
                
                vx = lengthdir_x(follow_move_speed, blended_dir);
                vy = lengthdir_y(follow_move_speed, blended_dir);
                
                follow_current_direction = blended_dir;
                follow_last_move_x = vx;
                follow_last_move_y = vy;
                
                try_move_along_path(id);  // Still use the collision system
                
                // Request new path but don't clear movement
                request_pathfinding(id, temp_current_x, temp_current_y, temp_target_x, temp_target_y);
                return;
            }
            
           var _current_point = {
                x: bbox_left + (bbox_right - bbox_left) * 0.5,
                y: bbox_top + (bbox_bottom - bbox_top) * 0.5
            };
            
            var _waypoint = follow_path[follow_path_index];
            var _dist_to_waypoint = point_distance(_current_point.x, _current_point.y,
                                               _waypoint.x, _waypoint.y);
            
            // Check if we've passed this waypoint
            if (follow_path_index < array_length(follow_path) - 1) {
                var next_waypoint = follow_path[follow_path_index + 1];
                var current_to_target = point_direction(_current_point.x, _current_point.y, 
                                                      next_waypoint.x, next_waypoint.y);
                var waypoint_to_target = point_direction(_waypoint.x, _waypoint.y,
                                                       next_waypoint.x, next_waypoint.y);
                                                       
                // If we're closer to the next waypoint and roughly aligned with the path
                var angle_diff = abs(angle_difference(current_to_target, waypoint_to_target));
                if (angle_diff < 45 && 
                    point_distance(_current_point.x, _current_point.y, next_waypoint.x, next_waypoint.y) <
                    point_distance(_waypoint.x, _waypoint.y, next_waypoint.x, next_waypoint.y)) {
                    
                    show_debug_message("NPC_FOLLOW: Skipping passed waypoint");
                    follow_path_index++;
                    _waypoint = follow_path[follow_path_index];
                    _dist_to_waypoint = point_distance(_current_point.x, _current_point.y,
                                                   _waypoint.x, _waypoint.y);
                }
            }
            
            // Get the current movement direction
            var _move_dir = point_direction(_current_point.x, _current_point.y,
                                            _waypoint.x, _waypoint.y);
                                     
            // Check for entities blocking the immediate path to waypoint
            var blocked_by_entity = false;
            var blocking_entities = [];
            if (_dist_to_waypoint > WAYPOINT_REACH_DISTANCE) {
                blocking_entities = check_entity_collision(id, _waypoint.x, _waypoint.y);
                
                // Filter out our own collision from blocking entities
                var real_blocking_entities = [];
                for (var i = 0; i < array_length(blocking_entities); i++) {
                    if (blocking_entities[i].id != id) {
                        array_push(real_blocking_entities, blocking_entities[i]);
                    }
                }
                blocking_entities = real_blocking_entities;
                blocked_by_entity = array_length(blocking_entities) > 0;
            }
            
            if (blocked_by_entity) {
                var my_priority = variable_instance_exists(id, "path_priority") ? path_priority : 0;
                var should_yield = false;
                
                for (var i = 0; i < array_length(blocking_entities); i++) {
                    var other_entity = blocking_entities[i];
                    if (variable_instance_exists(other_entity, "path_priority")) {
                        if (other_entity.path_priority >= my_priority) {
                            should_yield = true;
                            break;
                        }
                    }
                }
                
                if (should_yield) {
                    backup_away_from_blockers(id, blocking_entities);
                } else {
                    follow_path_index++;
                    if (follow_path_index >= array_length(follow_path)) {
                        follow_has_valid_path = false;
                        return;
                    }
                    _waypoint = follow_path[follow_path_index];
                }
            } else if (_dist_to_waypoint <= WAYPOINT_REACH_DISTANCE) {
                follow_path_index++;
                if (follow_path_index >= array_length(follow_path)) {
                    show_debug_message("NPC_FOLLOW: No more waypoints left");
                    follow_has_valid_path = false;
                    return;
                }
                _waypoint = follow_path[follow_path_index];
            }
            
            var desired_vx = lengthdir_x(follow_move_speed, _move_dir);
            var desired_vy = lengthdir_y(follow_move_speed, _move_dir);
            
            // Enhanced velocity blending with minimum speed threshold
            var current_speed = point_distance(0, 0, vx, vy);
            if (current_speed < VELOCITY_MIN_SPEED) {
                // Gentle initial acceleration
                vx = lerp(vx, desired_vx * 0.5, VELOCITY_BLEND);
                vy = lerp(vy, desired_vy * 0.5, VELOCITY_BLEND);
            } else {
                // Normal movement
                vx = lerp(vx, desired_vx, VELOCITY_BLEND);
                vy = lerp(vy, desired_vy, VELOCITY_BLEND);
            }
            
            follow_current_direction = _move_dir;
            follow_last_move_x = vx;
            follow_last_move_y = vy;
            
            var success = try_move_along_path(id);
            
            if (success) {
                increment_path_cache_success(temp_current_x, temp_current_y, 
                                             temp_target_x, temp_target_y);
            } else if (blocked_by_entity) {
                blocked_path_timer = BLOCKED_PATH_MEMORY_TIME;
                path_retry_timer = floor(pathfinding_cooldown * 0.5);
            }
        }
    }
}

function try_move_along_path(entity) {
   with (entity) {
       if (!variable_instance_exists(id, "stuck_counter")) stuck_counter = 0;
       
       var start_x = x;
       var start_y = y;
       
       // Determine which movement values to use based on which behavior is active
       var total_move_x, total_move_y, behavior_move_speed;
       if (variable_instance_exists(id, "follow_initialized") && follow_initialized) {
           total_move_x = follow_last_move_x;
           total_move_y = follow_last_move_y;
           
           if (variable_instance_exists(id, "follow_move_speed")) {
               behavior_move_speed = follow_move_speed;
           } else {
               // Fallback if follow_move_speed isn't defined
               // (Make sure you actually define 'move_speed' in Create OR pick a constant)
               behavior_move_speed = variable_instance_exists(id, "move_speed") ? move_speed : 2.5;
           }
       } else {
           total_move_x = search_last_move_x;
           total_move_y = search_last_move_y;
           behavior_move_speed = search_move_speed; 
       }
       
       // Calculate repulsion from nearby entities
       var repulsion_x = 0;
       var repulsion_y = 0;
       var REPULSION_RADIUS   = GRID_CELL_SIZE * 2;         // Distance at which repulsion starts
       var REPULSION_STRENGTH = behavior_move_speed * 4;    // How strong the push is
       
       with (obj_entity_root) {
           if (id != other.id) {
               var dx = (other.bbox_left + (other.bbox_right - other.bbox_left) * 0.5)
                        - (bbox_left + (bbox_right - bbox_left) * 0.5);
               var dy = (other.bbox_top + (other.bbox_bottom - other.bbox_top) * 0.5)
                        - (bbox_top + (bbox_bottom - bbox_top) * 0.5);
               var dist = point_distance(0, 0, dx, dy);
               
               if (dist < REPULSION_RADIUS && dist > 0) {
                   // Priority-based repulsion adjustment
                   var repulsion_mult = 1.0;
                   var my_priority = variable_instance_exists(other.id, "path_priority")
                                     ? other.id.path_priority
                                     : (variable_instance_exists(other.id, "search_priority")
                                        ? other.id.search_priority : 0);
                   var their_priority = variable_instance_exists(id, "path_priority")
                                       ? path_priority
                                       : (variable_instance_exists(id, "search_priority")
                                          ? search_priority : 0);
                   
                   if (my_priority > their_priority) {
                       repulsion_mult = PRIORITY_REPULSION_SCALE;
                   } else if (my_priority < their_priority) {
                       repulsion_mult = 1 / PRIORITY_REPULSION_SCALE;
                   }
                   
                   // Stronger repulsion if stuck
                   var my_stuck = variable_instance_exists(other.id, "stuck_counter") 
                                  ? other.id.stuck_counter 
                                  : 0;
                   var their_stuck = variable_instance_exists(id, "stuck_counter")
                                     ? stuck_counter
                                     : 0;
                   
                   if (my_stuck > 10 || their_stuck > 10) {
                       repulsion_mult *= 1.5;
                   }
                   
                   var force = (1 - (dist / REPULSION_RADIUS)) * REPULSION_STRENGTH * repulsion_mult;
                   var angle = point_direction(0, 0, dx, dy);
                   
                   repulsion_x += lengthdir_x(force, angle);
                   repulsion_y += lengthdir_y(force, angle);
               }
           }
       }
       
       // Add repulsion to movement vector
       total_move_x += repulsion_x;
       total_move_y += repulsion_y;
       
       // Use a different name for the local distance variable
       var dist_move = point_distance(0, 0, total_move_x, total_move_y);
       if (dist_move > behavior_move_speed) {
           var move_scale = behavior_move_speed / dist_move;
           total_move_x   *= move_scale;
           total_move_y   *= move_scale;
       }
       
       // 1) Try direct movement first
       if (!place_meeting(x + total_move_x, y + total_move_y, obj_collision)) {
           x += total_move_x;
           y += total_move_y;
       } else {
           // 2) If blocked, try sliding movement with deflection
           var steps = max(abs(total_move_x), abs(total_move_y));
           if (steps < 1) steps = 1;
           
           var step_x = total_move_x / steps;
           var step_y = total_move_y / steps;
           var moved_any = false;
           
           for (var i = 0; i < steps; i++) {
               if (!place_meeting(x + step_x, y + step_y, obj_collision)) {
                   x += step_x;
                   y += step_y;
                   moved_any = true;
               } else {
                   // Enhanced sliding logic
                   var slide_check_dist = 16;
                   var angles;
                   
                   // Adjust angles based on priority and stuck state
                   if (variable_instance_exists(id, "path_priority") && stuck_counter > 10) {
                       if (path_priority > 1) {
                           // Higher-priority entities prefer direct paths
                           angles = [0, 15, -15, 30, -30, 45, -45];
                       } else {
                           // Lower-priority entities try wider angles first
                           angles = [45, -45, 30, -30, 15, -15, 0];
                       }
                   } else {
                       // Default angle progression
                       angles = [0, 15, -15, 30, -30, 45, -45];
                   }
                   
                   var found_slide = false;
                   
                   for (var a = 0; a < array_length(angles); a++) {
                       var test_angle = point_direction(0, 0, step_x, step_y) + angles[a];
                       var test_x     = lengthdir_x(slide_check_dist, test_angle);
                       var test_y     = lengthdir_y(slide_check_dist, test_angle);
                       
                       // Normalize test vector to maintain original speed
                       var test_len = point_distance(0, 0, test_x, test_y);
                       test_x       = (test_x / test_len) * point_distance(0, 0, step_x, step_y);
                       test_y       = (test_y / test_len) * point_distance(0, 0, step_x, step_y);
                       
                       if (!place_meeting(x + test_x, y + test_y, obj_collision)) {
                           x += test_x;
                           y += test_y;
                           found_slide = true;
                           moved_any   = true;
                           break;
                       }
                   }
                   
                   if (!found_slide) {
                       // Try cardinal directions as fallback
                       var could_move_x = false;
                       var could_move_y = false;
                       
                       if (!place_meeting(x + step_x, y, obj_collision)) {
                           x += step_x;
                           could_move_x = true;
                       }
                       if (!place_meeting(x, y + step_y, obj_collision)) {
                           y += step_y;
                           could_move_y = true;
                       }
                       
                       if (could_move_x || could_move_y) {
                           moved_any = true;
                       } else {
                           break;
                       }
                   }
               }
           }
       }
       
       var dist_moved = point_distance(start_x, start_y, x, y);
       
       // Reset or increment stuck counter
       if (dist_moved < 0.1) {
           stuck_counter++;
           
           // If stuck for a while, backup from nearby entities
           if (stuck_counter > 5) {
               var nearby_entities = [];
               
               with (obj_entity_root) {
                   if (id != other.id) {
                       var check_dist = REPULSION_RADIUS * 1.2;
                       var dist = point_distance(other.x, other.y, x, y);
                       if (dist < check_dist) {
                           array_push(nearby_entities, id);
                       }
                   }
               }
               
               if (array_length(nearby_entities) > 0) {
                   backup_away_from_blockers(id, nearby_entities);
                   show_debug_message(
                       "Attempting backup due to stuck state with " +
                       string(array_length(nearby_entities)) + " nearby entities"
                   );
               }
           }
       } else {
           stuck_counter = 0;
       }
       
       if (stuck_counter >= 15) {
           stuck_counter = 0;
           return false;
       }
       
       // Update last movement variables based on which behavior is active
       if (variable_instance_exists(id, "follow_initialized") && follow_initialized) {
           follow_last_move_x = total_move_x;
           follow_last_move_y = total_move_y;
       } else {
           search_last_move_x = total_move_x;
           search_last_move_y = total_move_y;
       }
       
       return (dist_moved >= 0.1);
   }
}



function backup_away_from_blockers(entity, blockers) {
    with (entity) {
        if (array_length(blockers) <= 0) return;
        
        // Find the closest blocker
        var closest_dist = infinity;
        var closest_blocker = noone;
        var my_x = bbox_left + (bbox_right - bbox_left) * 0.5;
        var my_y = bbox_top + (bbox_bottom - bbox_top) * 0.5;
        
        for (var i = 0; i < array_length(blockers); i++) {
            var b = blockers[i];
            var bx = b.bbox_left + (b.bbox_right - b.bbox_left) * 0.5;
            var by = b.bbox_top + (b.bbox_bottom - b.bbox_top) * 0.5;
            var dist = point_distance(my_x, my_y, bx, by);
            
            if (dist < closest_dist) {
                closest_dist = dist;
                closest_blocker = b;
            }
        }
        
        // Only react to closest blocker
        var final_x = 0;
        var final_y = 0;
        var max_backup = 3; 
        var backup_len = min(max_backup, max(1, closest_dist * 0.25));
        
        var bx = closest_blocker.bbox_left + (closest_blocker.bbox_right - closest_blocker.bbox_left) * 0.5;
        var by = closest_blocker.bbox_top + (closest_blocker.bbox_bottom - closest_blocker.bbox_top) * 0.5;
        var angle_away = point_direction(bx, by, x, y);
        final_x = lengthdir_x(backup_len, angle_away);
        final_y = lengthdir_y(backup_len, angle_away);
        
        // Update facing direction based on movement
        if (abs(final_x) > abs(final_y)) {
            // Moving more horizontally
            desired_facing_direction = (final_x > 0) ? "right" : "left";
        } else {
            // Moving more vertically
            desired_facing_direction = (final_y > 0) ? "down" : "up";
        }
        // Force immediate direction change for backup
        facing_direction = desired_facing_direction;
        direction_change_timer = 0;
        
        // Single small move attempt
        var new_x = x + final_x;
        var new_y = y + final_y;
        
        // Only move if not colliding with walls
        if (!place_meeting(new_x, new_y, obj_collision)) {
            x = new_x;
            y = new_y;
            
            // Reduce velocity instead of zeroing it
            if (variable_instance_exists(id, "vx")) vx *= 0.5;
            if (variable_instance_exists(id, "vy")) vy *= 0.5;
            
            // Update animation variables to reflect actual movement
            follow_last_move_x = final_x;
            follow_last_move_y = final_y;
        }
    }
}
