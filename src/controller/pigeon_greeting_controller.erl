-module(pigeon_greeting_controller, [Req]).

-export([hello/2, upload/2, list/2, template/2]).
%-compile(export_all).

% @doc set macro to the scratch directory
-define(PROCCESDIR, "./scratch/"). 


% ==============================Pubic Interfaces ====================================
% @doc This is the index file for the pages, it just calls its view
% @todo remove this function   
hello('GET', [])->
    {ok, [{greeting,"This is a test from jason"}]}.


% @doc Upload will handle the post request for processing uploaded file. 
% @return 
upload('POST', [])->
	[{_, _FileName, TempLocation, _Size, _Name, _}|_] = Req:post_files(),

	Ext =  filename:extension(_FileName),
	F = filename:basename(_FileName, Ext),
	Importer = case Ext of
		".xls" -> "Gnumeric_Excel:excel";
		".xlsx" -> "Gnumeric_Excel:xlsx";
		".sxc" -> "Gnumeric_OpenCalc:openoffice";
		".ods" -> "Gnumeric_OpenCalc:openoffice";
		_Other -> throw({error, 710, "Not a known file type"})
	end,
	filelib:ensure_dir(?PROCCESDIR++F++"/"),
    File = "ssconvert --import-type="++Importer++" --export-type=Gnumeric_stf:stf_csv -S " ++ TempLocation ++" ./scratch/"++F++"/%n-%s.csv", 
	os:cmd(File),
	file:delete(TempLocation),
	
	{ok,Sheets} = createListfiles(F),
	
	Sheets2 = sheetJson(Sheets, _FileName, ""),
	{output,  Sheets2}.

% @doc List will take the lists and process then before storing them in the database 
list('POST', [])->
	try
		{ struct, [{"book", { struct, Books }}]} = mochijson:decode(Req:post_param_group("ParseData")),
		Headers = processAndStoreList(Books),
		{ok, [{fieldNames,Headers}]}
	catch
		throw:X ->io:format("{error, throw, ~p}", [X]);
		exit:X-> io:format("{error, exit, ~p}", [X])
	end.

template('POST', [])->
	Table = Req:post_param_group("table"),
	Html = Req:post_param_group("formData"),
	[{clientList, _,_,_, Db}] = boss_db:find(clientList, [], [{limit,1}]),
	Datablock = binary_to_term(Db),
	Page = templatePage(Datablock, Html),
	{output, Page}.
	
%====================================================================================

templatePage([H|T], Page)->
	
	{F, Value} = H,
	Field = "{{#"++F++"#}}",
	Page1 = re:replace(Page, Field, Value, [global, {return, list}]),
	templatePage(T, Page1);
templatePage([], Page)->Page.



% @doc Get Books and sheets information so we can process the files from upload into the database.  
processAndStoreList([H|T])->
	{BookName, {struct,Sheets}} = H,
	[{SheetName, {struct,[{"Name", Name},{"FirstRow",FirstRow},{"EmailCol",EmailCol}, {"Headers", {struct, Headers}}]}}] = Sheets,
	Processed = case FirstRow of 
		true-> 
			 processAndStoreList(BookName, T, Headers );% skip first row if FirstRow is true
		_ -> 
			 processSheet(BookName, SheetName, Name, EmailCol, Headers), % else process as normal
			 processAndStoreList(BookName, T, Headers )
	end,
	Processed.
processAndStoreList(BookName, [H|T], _)->
	{SheetName, {struct,[{"Name", Name},{"FirstRow",FirstRow},{"EmailCol",EmailCol}, {"Headers", {struct, Headers}}]}} = H,
	processSheet(BookName, SheetName, Name, EmailCol, Headers), % else process as normal
	processAndStoreList(BookName, T, Headers );
processAndStoreList(_, [], Headers)->
	Str = getArrayHeader(Headers, []),
	Str.


processSheet(BookName, SheetName, Name, EmailCol, Headers)->

	FileName = ?PROCCESDIR++BookName++"/"++SheetName,	
	%case filelib:is_file(FileName) of
	% 	{error, ReaDir} ->  throw({error, directory, ReaDir})
	%end,
	
	File = case file:open(FileName, [read, raw]) of 
	{ok, Fd}->
		readLine(Fd, 1, Name, EmailCol, Headers);
	{error, ResFile}->
		throw({error, file, ResFile})
	 end.
	


readLine(F, Count, Name, EmailCol, Headers)->
	
    case file:read_line(F) of
		{ok, Line} ->
		    Cells = string:tokens(string:strip(Line), ","),
			DataBlock = term_to_binary(getDataBlock(Cells, Headers, [])),
			{Num, []} = string:to_integer(EmailCol),
			ClientList = clientList:new(id, Name,lists:nth(Num+1, Cells),DataBlock),
			boss_db:transaction ( fun()-> ClientList:save() end),
			readLine(F, Count+1, Name, EmailCol, Headers);
		{error, Reason} ->
		   throw({error, file, Reason});
		eof ->
		    io:format("could be end of file")
    end.

    
getDataBlock(Cells, [H|T], Acc)->
	{R, Name} =  H,
	{Num, []} = string:to_integer(R),
	Value = string:strip(lists:nth(Num+1, Cells)),
	Acc1 = Acc++[{string:strip(Name), Value}],
	getDataBlock(Cells, T, Acc1);
getDataBlock(_, [], Acc)->Acc.

getArrayHeader([H|T], Acc)->
	{_, Name} =  H,
	Acc1 = [Name | Acc ],
	getArrayHeader(T, Acc1);
getArrayHeader([], Acc)->lists:reverse(Acc).


sheetJson([H|T], File, [])->
	{Path, Sheet, Name, Size, SheetCount, RowCount, Sample} = H,
	Str = "\""++SheetCount++"\":
				{\"Path\": \""++Path++"\",
				\"File\": \""++File++"\",
				\"Sheet\": \""++Sheet++"\",
				\"Name\": \""++Name++"\",
				\"Rows\": \""++integer_to_list(RowCount)++"\",
				\"Size\": \""++integer_to_list(Size)++"\",
				\"Sample\": \""++Sample++"\"}",
	sheetJson(T, File, Str);

sheetJson([H|T], File, Str)->
	{Path, Sheet, Name, Size, SheetCount, RowCount, Sample} = H,
	Acc = Str++",\""++SheetCount++"\": 
				{\"Path\": \""++Path++"\",
				\"File\": \""++File++"\",
				\"Sheet\": \""++Sheet++"\",
				\"Name\": \""++Name++"\",
				\"Rows\": \""++integer_to_list(RowCount)++"\",
				\"Size\": \""++integer_to_list(Size)++"\",
				\"Sample\": \"" ++ Sample ++ "\"}",
	sheetJson(T, File, Acc);

sheetJson([], _,Str)->"{\"Sheets\":{"++Str++"}}".



createListfiles(Directory) ->
	Dir = ?PROCCESDIR ++ Directory,

    case file:list_dir(Dir) of
	{ok, Files} ->
	    createListfiles(Directory, Files, []);
	{error, Reason}  ->
	    {error, {Directory, Reason}}
    end.
createListfiles(Directory, [F|Tail], Ack) ->
	
	Dir = ?PROCCESDIR ++ Directory,
	
	Size = filelib:file_size(?PROCCESDIR ++ Directory++ "/" ++ F),
	Ext =  filename:extension(F),
	N = filename:basename(F, Ext),
	
	[SheetCount, Name] = string:tokens(N, "-"),

	

	Ack1 = case Size of
		Size when Size > 3 -> 
			{ok, Sample, CountRows}= getSample(Dir ++ "/" ++ F),
			Path = Directory ++ "+|+" ++ F,
			T = [{Path, F, Name, Size, SheetCount,CountRows,Sample}],	
			Ack++T;
		_ -> Ack
	end,
	createListfiles(Directory, Tail, Ack1);
createListfiles(_, [], Ack) ->
	A = Ack,
    {ok, A}.
                     

getSample(FileName)->
    
	Sample = case file:open(FileName, [read, raw]) of 
	{ok, Fd}->
	    readLine(Fd, 1, "")
	 end,
	
	CountRow = case file:open(FileName, [read, raw]) of 
	{ok, Fd2}->
	    countLine(Fd2, 1)
	 end,
	
	{ok, Sample, CountRow}.

countLine(F, Acc)->

   case file:read_line(F) of
		{ok, Line} ->
		    Acc1 = Acc+1,
	   		countLine(F, Acc1);
	    eof ->
		    Acc
    end;

countLine(eof, Acc)-> Acc.

readLine(F, Acc, Rows) when Acc == 1 -> 
	case file:read_line(F) of
		{ok, Line} ->
			Th = inputfield(Line),
		    Str = readCell(Line),
		    readLine(F, Acc+1, Th++"<tbody>"++Str);
		{error, Reason} ->
		    io:format("error :~p~n" ,[Reason]);
	    eof ->
		    io:format("Read Line : could be end of file1")
    end;
readLine(F, Acc, Rows) when Acc < 6 ->
   case file:read_line(F) of
		{ok, Line} ->
		    Str = readCell(Line),
		    readLine(F, Acc+1, Rows++Str);
		{error, Reason} ->
		    io:format("error :~p~n" ,[Reason]);
	    eof ->
		    io:format("Read Line : could be end of file1")
    end;
readLine(F, Acc, Rows) when Acc == 6 -> Rows++"</tbody>".


readCell(Line)->jsonCleanString("<tr><td>"++string:join(string:tokens(Line, ","), "<\/td><td>")++"<\/td></tr>").
	



inputfield(Line)->inputfield(length(string:tokens(Line, ",")), 1, "").
inputfield(F, Acc, String) when Acc > F -> jsonCleanString("<tr>"++String++"</tr>");
inputfield(F, Acc, String) when Acc =< F ->
	String2 = String++"<th><input name=\"Field"++integer_to_list(Acc)++"\" type=\"text\" value=\"Field"++integer_to_list(Acc)++"\"></th>",
	Acc2 = Acc+1,
	inputfield(F, Acc2, String2).

jsonCleanString(Str) ->
	R1 = re:replace(Str, "(\")", "\\\\\"", [global,{return,list}]), %% need to escape all in the html string '"' 
	R2 = re:replace(R1, "(\n)", "", [global,{return,list}]), %% and remove new lines
	R3 = re:replace(R2, "(\r)", "", [global,{return,list}]), %% and remove carages return, Just to get HTML code throw Json 
	R3.