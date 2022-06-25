require 'sinatra'

$stdout.sync = true

configure do
  set :port, 8080
  set :bind, '0.0.0.0'
end

get '/' do
  'Let the battle begin!'
end

post '/' do
  begin
    response = JSON.parse(request.body.read)

    arena_state = response["arena"]["state"]
    my_self = response["_links"]["self"]["href"]

    my_position = arena_state[my_self]
    arena_dims = response["arena"]["dims"]

    other_players = arena_state.except(my_self)

    possible_moves = []

    # top edge
    possible_moves = ["R", "L"] if my_position["y"] == 0 && my_position["direction"] == "N" 

    # bottom edge
    possible_moves = ["R", "L"] if my_position["y"] == arena_dims[1] && my_position["direction"] == "S" 


    # right-end edge
    possible_moves = if my_position["x"] == arena_dims[0]
      if my_position["direction"] == "E" && my_position["y"] == 0 # top right corner facing East
        ["R"]
      elsif my_position["direction"] == "N" && my_position["y"] == 0 # top right corner facing North
        ["L"]
      elsif my_position["y"] == arena_dims[1] && my_position["direction"] == "S" # bottom right corner facing South
        ["R"]
      elsif my_position["y"] == arena_dims[1] && my_position["direction"] == "E" # bottom right corner facing East
        ["L"]
      end
    end

    # left-end edge
    possible_moves = if my_position["x"] == 0
      if my_position["direction"] == "W" && my_position["y"] == 0 # top left corner facing West
        ["L"]
      elsif my_position["direction"] == "N" && my_position["y"] == 0 # top left corner facing North
        ["R"]
      elsif my_position["y"] == arena_dims[1] && my_position["direction"] == "S" # bottom left corner facing South
        ["L"]
      elsif my_position["y"] == arena_dims[1] && my_position["direction"] == "W" # bottom left corner facing West
        ["R"]
      end
    end

    # throw
    reachable_area = if my_position["direction"] == "N"
      [my_position["x"], my_position["y"] - 3] # aim North
    elsif my_position["direction"] == "S"
      [my_position["x"], my_position["y"] + 3] # aim South
    elsif my_position["direction"] == "E"
      [my_position["x"] + 3, my_position["y"]] # aim East
    elsif my_position["direction"] == "W"
      [my_position["x"] - 3, my_position["y"]] # aim West
    end

    possible_moves = ["T"] if other_players.values.any? do |player|
      Range.new([my_position["x"], reachable_area[0]].min, [my_position["x"], reachable_area[0]].max).include?(player["x"]) &&
        Range.new([my_position["y"], reachable_area[1]].min, [my_position["y"], reachable_area[1]].max).include?(player["y"])
    end

    
    response = possible_moves.any? ?  possible_moves.sample : "F" # otherwise just move
    response
  rescue => e
    ["F", "L", "R", "T"].sample
  end
end
