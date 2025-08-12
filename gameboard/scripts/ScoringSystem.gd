extends RefCounted
class_name ScoringSystem

# Advanced scoring system for Linkage game
# Analyzes connection patterns and awards bonus points

enum ScoreType {
	BASE_TILE,      # 1 point per tile (existing)
	CORNER_BONUS,   # Bonus for corners in path
	LENGTH_BONUS,   # Bonus for long connections
	LOOP_BONUS,     # Bonus for closed loops
	PATTERN_BONUS,  # Bonus for specific patterns
	CHAIN_BONUS     # Multiplier for chain reactions
}

# Scoring configuration
const SCORE_VALUES = {
	ScoreType.BASE_TILE: 1,
	ScoreType.CORNER_BONUS: 2,      # +2 per corner
	ScoreType.LENGTH_BONUS: 1,      # +1 per tile beyond minimum (3)
	ScoreType.LOOP_BONUS: 5,        # +5 for closed loops
	ScoreType.PATTERN_BONUS: 10,    # +10 for special patterns
	ScoreType.CHAIN_BONUS: 2        # x2 multiplier per chain level
}

# Analyze connections and calculate advanced score
static func calculate_advanced_score(connections: Array, board: Array, chain_level: int = 0) -> Dictionary:
	var score_breakdown = {
		"total_score": 0,
		"base_tiles": 0,
		"corners": 0,
		"loops": 0,
		"length_bonus": 0,
		"pattern_bonus": 0,
		"chain_multiplier": 1,
		"details": []
	}
	
	if connections.is_empty() or board.is_empty():
		return score_breakdown
	
	# Find all connected groups
	var connected_groups = find_connected_groups(connections)
	
	# Analyze each group for scoring
	for group in connected_groups:
		var group_analysis = analyze_connection_group(group, board, chain_level)
		
		# Add to total breakdown
		score_breakdown.base_tiles += group_analysis.base_tiles
		score_breakdown.corners += group_analysis.corners
		score_breakdown.loops += group_analysis.loops
		score_breakdown.length_bonus += group_analysis.length_bonus
		score_breakdown.pattern_bonus += group_analysis.pattern_bonus
		score_breakdown.details.append(group_analysis.details)
	
	# Apply chain multiplier
	if chain_level > 0:
		score_breakdown.chain_multiplier = SCORE_VALUES[ScoreType.CHAIN_BONUS] ** chain_level
	
	# Calculate total score
	var base_score = score_breakdown.base_tiles * SCORE_VALUES[ScoreType.BASE_TILE]
	var bonus_score = (
		score_breakdown.corners * SCORE_VALUES[ScoreType.CORNER_BONUS] +
		score_breakdown.loops * SCORE_VALUES[ScoreType.LOOP_BONUS] +
		score_breakdown.length_bonus * SCORE_VALUES[ScoreType.LENGTH_BONUS] +
		score_breakdown.pattern_bonus
	)
	
	score_breakdown.total_score = (base_score + bonus_score) * score_breakdown.chain_multiplier
	
	return score_breakdown

# Find all separate connected groups in the connection map
static func find_connected_groups(connections: Array) -> Array:
	var groups = []
	var visited = {}
	var height = connections.size()
	var width = connections[0].size() if height > 0 else 0
	
	for y in height:
		for x in width:
			if connections[y][x] and not visited.has(Vector2i(x, y)):
				var group = []
				flood_fill_group(connections, x, y, visited, group)
				if group.size() > 0:
					groups.append(group)
	
	return groups

# Flood fill to find all tiles in a connected group
static func flood_fill_group(connections: Array, start_x: int, start_y: int, visited: Dictionary, group: Array):
	var stack = [Vector2i(start_x, start_y)]
	var height = connections.size()
	var width = connections[0].size() if height > 0 else 0
	
	while not stack.is_empty():
		var pos = stack.pop_back()
		var x = pos.x
		var y = pos.y
		
		# Check bounds and if already visited
		if x < 0 or x >= width or y < 0 or y >= height:
			continue
		if visited.has(pos) or not connections[y][x]:
			continue
		
		# Mark as visited and add to group
		visited[pos] = true
		group.append(pos)
		
		# Add adjacent connected tiles to stack
		for offset in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			stack.append(pos + offset)

# Analyze a specific connection group for advanced scoring
static func analyze_connection_group(group: Array, board: Array, chain_level: int) -> Dictionary:
	var analysis = {
		"base_tiles": group.size(),
		"corners": 0,
		"loops": 0,
		"length_bonus": 0,
		"pattern_bonus": 0,
		"details": {
			"group_size": group.size(),
			"is_loop": false,
			"corner_count": 0,
			"pattern_type": "none"
		}
	}
	
	# Length bonus (tiles beyond minimum chain of 3)
	if group.size() > 3:
		analysis.length_bonus = group.size() - 3
	
	# Count corners by analyzing pipe types in the group
	analysis.corners = count_corners_in_group(group, board)
	analysis.details.corner_count = analysis.corners
	
	# Check if it's a loop (closed path)
	if is_closed_loop(group, board):
		analysis.loops = 1
		analysis.details.is_loop = true
	
	# Check for special patterns
	var pattern_type = detect_special_pattern(group, board)
	if pattern_type != "none":
		analysis.pattern_bonus = SCORE_VALUES[ScoreType.PATTERN_BONUS]
		analysis.details.pattern_type = pattern_type
	
	return analysis

# Count corner pieces in a connection group
static func count_corners_in_group(group: Array, board: Array) -> int:
	var corner_count = 0
	var corner_faces = [4, 5, 7, 8]  # Corner pipe types
	
	for pos in group:
		var tile = board[pos.y][pos.x] if pos.y < board.size() and pos.x < board[pos.y].size() else null
		if tile:
			var face = tile.get_face() if tile.has_method("get_face") else (tile.face if "face" in tile else 0)
			if face in corner_faces:
				corner_count += 1
	
	return corner_count

# Check if a group forms a closed loop
static func is_closed_loop(group: Array, board: Array) -> bool:
	# A loop requires at least 4 tiles and every tile must have exactly 2 connections
	if group.size() < 4:
		return false
	
	# Build adjacency map for the group
	var adjacency = {}
	for pos in group:
		adjacency[pos] = []
	
	# Check connections between group members
	for pos in group:
		var tile = board[pos.y][pos.x] if pos.y < board.size() and pos.x < board[pos.y].size() else null
		if not tile:
			continue
			
		var face = tile.get_face() if tile.has_method("get_face") else (tile.face if "face" in tile else 0)
		var connections = get_pipe_connections(face, pos)
		
		for conn_pos in connections:
			if conn_pos in group:
				adjacency[pos].append(conn_pos)
	
	# Check if every tile has exactly 2 connections (loop property)
	for pos in group:
		if adjacency[pos].size() != 2:
			return false
	
	return true

# Get connection positions for a pipe at given position
static func get_pipe_connections(face: int, pos: Vector2i) -> Array:
	var connections = []
	var directions = []
	
	# Determine connection directions based on pipe type
	match face:
		0: directions = [Vector2i(0, 1)]  # Down only
		1: directions = [Vector2i(0, -1), Vector2i(0, 1)]  # Up, Down
		2: directions = [Vector2i(0, -1)]  # Up only
		3: directions = [Vector2i(1, 0)]  # Right only
		4: directions = [Vector2i(1, 0), Vector2i(0, 1)]  # Right, Down
		5: directions = [Vector2i(1, 0), Vector2i(0, -1)]  # Right, Up
		6: directions = [Vector2i(1, 0), Vector2i(-1, 0)]  # Right, Left
		7: directions = [Vector2i(-1, 0), Vector2i(0, 1)]  # Left, Down
		8: directions = [Vector2i(-1, 0), Vector2i(0, -1)]  # Left, Up
		9: directions = [Vector2i(-1, 0)]  # Left only
	
	for direction in directions:
		connections.append(pos + direction)
	
	return connections

# Detect special patterns in connection groups
static func detect_special_pattern(group: Array, board: Array) -> String:
	var size = group.size()
	
	# Perfect square loop
	if is_perfect_square_loop(group, board):
		return "perfect_square"
	
	# Long straight line (6+ tiles in a row)
	if is_long_straight_line(group, board):
		return "long_line"
	
	# Cross pattern (intersection of two lines)
	if is_cross_pattern(group, board):
		return "cross"
	
	return "none"

# Check for perfect square loop pattern
static func is_perfect_square_loop(group: Array, board: Array) -> bool:
	if group.size() != 8:  # 4x4 square has 8 border tiles
		return false
	
	# Find bounding box
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for pos in group:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	# Check if it forms a rectangle perimeter
	var width = max_x - min_x + 1
	var height = max_y - min_y + 1
	
	if width == 3 and height == 3:
		# Check that only perimeter tiles are included
		var perimeter_tiles = []
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				if x == min_x or x == max_x or y == min_y or y == max_y:
					perimeter_tiles.append(Vector2i(x, y))
		
		return perimeter_tiles.size() == group.size()
	
	return false

# Check for long straight line pattern
static func is_long_straight_line(group: Array, board: Array) -> bool:
	if group.size() < 6:
		return false
	
	# Check if all tiles are in a straight line (horizontal or vertical)
	var first_pos = group[0]
	var is_horizontal = true
	var is_vertical = true
	
	for pos in group:
		if pos.y != first_pos.y:
			is_horizontal = false
		if pos.x != first_pos.x:
			is_vertical = false
	
	return is_horizontal or is_vertical

# Check for cross pattern (intersection)
static func is_cross_pattern(group: Array, board: Array) -> bool:
	if group.size() < 5:  # Minimum cross is 5 tiles
		return false
	
	# Find potential center points
	var center_candidates = []
	for pos in group:
		var connections = 0
		for other_pos in group:
			if other_pos != pos:
				var dx = abs(other_pos.x - pos.x)
				var dy = abs(other_pos.y - pos.y)
				if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
					connections += 1
		
		if connections >= 3:  # Center should connect to 3+ tiles
			center_candidates.append(pos)
	
	return center_candidates.size() > 0