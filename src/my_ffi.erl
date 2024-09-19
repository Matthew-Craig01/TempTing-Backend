% Taken from https://stackoverflow.com/questions/41777852/erlang-return-time-in-utc-format

-module(my_ffi).
-export([format_iso8601/0]).

format_iso8601() ->
    {{Year, Month, Day}, {Hour, Min, Sec}} =
        calendar:universal_time(),
    iolist_to_binary(
      io_lib:format(
        "~.4.0w-~.2.0w-~.2.0wT~.2.0w:~.2.0w:~.2.0wZ",
        [Year, Month, Day, Hour, Min, Sec] )).
