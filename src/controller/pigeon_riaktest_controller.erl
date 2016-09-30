-module(pigeon_riaktest_controller, [Req]).

%-export([hello/2, upload/2]).
-compile(export_all).
-include_lib("stdlib/include/qlc.hrl"). 
-record(emailList, {id,name,state,email}).



hello('GET', [])->
		Emails = boss_db:find(emailList, []),
		{ok, [{emails, Emails}]}.

build('GET', [])->
		read("/home/jason/pigeon/scratch/Book3/1-State.csv"),
		{atomic, E} = select_all(emailList),
		mnesia:delete_table(emailList),
		{ok, [{emails, E}]}.

read(FileName)->
	%{ok, Pid} = riakc_pb_socket:start_link("127.0.0.1", 8087), 
    init(),
	File = case file:open(FileName, [read, raw]) of 
	{ok, Fd}->
		readLine(Fd, 1);
		%%{redirect, "/riaktest/hello"};
	{error, Reason}->
	    {error, Reason}
	 end.
	

readLine(F, Count)->

    case file:read_line(F) of
	{ok, Line} ->
	    readCell(Line, Count),
	    readLine(F, Count+1);
	{error, Reason} ->
	   {error, Reason};
	eof ->
	    io:format("could be end of file")
    end.
    

readCell(Line, Count)->
	Lines = string:tokens(Line, ","),
	insert(Count, lists:nth(1, Lines), lists:nth(2, Lines), lists:nth(3, Lines)).
	
	%Record = [{name, lists:nth(1, Lines)}, {state, lists:nth(1, Lines)} , {email,lists:nth(1, Lines)}],
	%Obj = riakc_obj:new(<<"emailList">>, <<Count>>, Record),
	%EmailList = riakc_pb_socket:put(Pid, Obj).
	%case riakc_pb_socket:put(Pid, Obj) of 
	%	{ok, EMails} -> added;
	%	{error, Reason} -> io:format("~p ~n ", Reason)
	%end.

	%
	%io:format(Lines),
	%Name = lists:nth(1, Lines),
	%State = lists:nth(2, Lines),
	%Email = lists:nth(3, Lines),
    %EmailList = emailList:new(id, Email, Name, State),

	%case EmailList:save() of 
		%{ok, EMails} -> added;
		%{error, Reason} -> io:format("~p ~n ", Reason)
	%end.
  
init()->
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(emailList,
                        [{attributes, record_info(fields, emailList)}, {record_name, emailList}]).

insert(Id, State, Name , Email) -> 
	%#emailList{id = Id,name = Name, state= State, email=Email},
 	%emailList.
	Fun =  fun() -> mnesia:write(#emailList{id = Id,name = Name, state= State, email=Email}) end,
	mnesia:activity(transaction, Fun).


getByIndex(Index)->
		F = fun() ->
               mnesia:read(emailList, Index, read)
        end,
    	mnesia:transaction(F).

select_all(Table) -> 
    mnesia:transaction( 
    fun() ->
        qlc:eval( qlc:q(
            [ X || X <- mnesia:table(Table) ] 
        )) 
    end ).


	