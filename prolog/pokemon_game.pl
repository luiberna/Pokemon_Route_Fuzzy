:-ensure_loaded("pokemon_list.pl").
:-ensure_loaded("pokemon_info_attacks.pl").
:-ensure_loaded("pokemon_route.pl").

player_starts(0,0).

next_rooms(X,Y,Rooms) :-
    route(Route),
    next_positions(X, Y, Positions),
    build_rooms(Route, Positions, Rooms).

next_positions(X, Y, Positions) :-
    XUp is X - 1,
    XDown is X + 1,
    YLeft is Y - 1,
    YRight is Y + 1,
    valid_positions([[XUp, Y], [XDown, Y], [X, YLeft], [X, YRight]], Positions).

valid_positions([], []).
valid_positions([[X, Y] | Rest], [[X, Y] | Valid]) :-
    validate(X, Y),
    valid_positions(Rest, Valid).
valid_positions([[X, Y] | Rest], Valid) :-
    \+ validate(X, Y),
    valid_positions(Rest, Valid).

validate(X, Y) :-
    X >= 0,
    X < 5,
    Y >= 0,
    Y < 5.

build_rooms(_, [], []).
build_rooms(Route, [[X, Y] | Rest], [[Id, Name, Level, X, Y, Types] | Rooms]) :-
    get_position(Route, X, Y, (Id, Level)),
    Id \= 0,
    pokemon(Id, Name, Types),
    build_rooms(Route, Rest, Rooms).
build_rooms(Route, [[X, Y] | Rest], Rooms) :-
    get_position(Route, X, Y, (_Id, _)),
    build_rooms(Route, Rest, Rooms).

get_position([Row | _], 0, Y, Value) :-
    get_element(Row, Y, Value).
get_position([_ | Rest], X, Y, Value) :-
    X > 0,
    X1 is X - 1,
    get_position(Rest, X1, Y, Value).

get_element([Value | _], 0, Value).
get_element([_ | Rest], Y, Value) :-
    Y > 0,
    Y1 is Y - 1,
    get_element(Rest, Y1, Value).
