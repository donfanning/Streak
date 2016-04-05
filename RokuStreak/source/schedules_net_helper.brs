'
'   This document contains an API for use with the Schedules Direct
'   open source television data service.
'   @author: Hayden McParlane
'   @creation-date: 2.18.2016

' TODO: This helper function set will be used to construct a package object
' that ties the network urltransfer id to the station id, program id, whatever.
' This will be used to optimize the network access while keeping track of 
' the operation that's being performed (i.e, get programs associated with
' station id X, etc...).

' TODO: This ~O(n^2) operation needs to be performed but it must be done more
' efficiently. The approach below is prohibitively expensive
'for each station in stations
'    AddUpdateChannel(station["stationID"], CreateObject("roAssociativeArray"))
'    ' TODO: Create current station filter and populate info
'    for each program in station["programs"]
'        o = program
'        AppendToProgram(program["programID"], o)
'    end for 
'end for
Function RequestProgramIDs(stationID as String, headers as Object, body as Object) as Object
    ' TODO: Store station id?   
    ' Store station IDs for use with stations request
    AppendStation(stationID)
    requestID = AsyncPostRequest(SchedulesDirectJSONSchedulesUrl(), headers, body)
    StoreSchedulesDirectProgramIDRequest(requestID)     
End Function

Function RequestProgramInfo(programID as String, headers as Object, body as Object) as Object
    ' TODO: Store program id?
    ' Check to ensure that request is necessary
    if AlreadyProcessed(programID)
        ' Do nothing
    else         
        requestID = AsyncPostRequest(SchedulesDirectJSONProgramInfoUrl(), headers, body)
        StoreSchedulesDirectProgramInfoRequest(requestID)
        SetProcessed(programID)
    end if    
End Function

Function StoreSchedulesDirectProgramIDRequest(requestID as Integer) as void
    requests = ProgramIDRequests()    
    requests.Push(requestID)
End Function

Function StoreSchedulesDirectProgramInfoRequest(requestID as Integer) as void
    requests = ProgramInfoRequests()    
    requests.Push(requestID)
End Function

Function SetProgramIDRequests(requests as Object) as void
    req = ProgramIDRequests()
    req.Append(requests)
End Function

Function ProgramIDRequests() as Object
    return CreateIfDoesntExistAndReturn(SchedulesDirectRequests(), "pid", "roArray")
End Function

Function SetProgramInfoRequests(requests as Object) as void
    req = ProgramInfoRequests()
    req.Append(requests)
End Function

Function ProgramInfoRequests() as Object
    ' TODO: Change reversal logic. Otherwise, every even number of times this is called, reversal
    ' will occur twice undoing the previous reversal.
    return CreateIfDoesntExistAndReturn(SchedulesDirectRequests(), "pinfo", "roArray")
End Function

' Hash table that identifies programIDs that have already been
' processed.
Function SetProcessed(programID as String) as void
    table = ProgramIDProcessedTable()
    table[programID] = True
End Function

Function AlreadyProcessed(programID as String) as Boolean
    found = False
    table = ProgramIDProcessedTable()
    if table.DoesExist(programID) ' If program has already been processed
        found = True
    end if
    return found
End Function

Function ProgramIDProcessedTable() as Object
    return CreateIfDoesntExistAndReturn(SchedulesDirectRequests(), "pct", "roAssociativeArray")
End Function
 
Function SchedulesDirectRequests() as Object
    return CreateIfDoesntExistAndReturn(GetSchedulesDirectNetwork(), "sdrequests", "roAssociativeArray")
End Function

' TODO: Move back into schedules_direct.brs
Function PopulateSchedulesDirectData(stations as Object) as void    
    headers = CreateObject("roAssociativeArray")    
    body = CreateObject("roArray", 1, False)

    ' Process data as it's received. Most recent request is lowest index.
    ' TODO: Further optimization may be achievable by allowing for system to progress
    ' even if the entire requests array isn't processed. I.e, distribute processing
    ' throughout the application but get enough done for users not to notice.
    headers.AddReplace("User-Agent",SchedulesDirectUserAgentHeader())
    headers.AddReplace("token",GetSchedulesDirectToken())
    headers.AddReplace("Accept-Encoding","deflate,gzip")    
    
                                            ' Buffer needed to reverse order of request IDs because
    for each station in stations          ' stack pop operation is done from tail of list. This means
        body.Push(station)
        RequestProgramIDs(station["stationID"], headers, body)          ' that deletions from the head require ~(O(num_requests) PER
        body.Clear()
                                            ' request removal. That's ~(O(num_requests ^ 2))
    end for           
    
    ' TODO: Token may not have been populated here, or may need to be refreshed.
    ' How to implement?    
    ' TODO: Alter logic so reversal occurs within request "object" not when used
    ' in the code. Separation of concerns and optimization.
    ' Reverse request order so pop is constant time operation (otherwise deletion is used
    ' requiring shifting of elements after deleted element).    
    requests = ProgramIDRequests()
    Reverse(requests)    
    while requests.Count() <> 0
        requestID = requests.Pop()
        port = GetAsyncRequestPort(requestID) 'TODO: Change to GetAsyncRequestTransfer if successful
        msg = wait(100, port.GetMessagePort())
        if type(msg) = "roUrlEvent" then
            LogDebug("Server response received")
            LogDebugObj("Response Code is ", msg.GetResponseCode())            
            ' TODO: Efficiently implement check of different response status codes here and deal
            ' with concerning circumstances appropriately            
            if msg.GetResponseCode() = 200 then
                ' TODO: If only one station is processed per request, this can be left alone.
                ' If more are processed, it may be necessary for add another for-each loop
                ' with the for-each program loop below nested within it.
                response = BuildResponse(msg)
                
                ' Immediately initiate requests for program info
                for each program in response.json[0]["programs"]
                    ' Create program object for quick access later
                    pid = program["programID"]
                    if AlreadyProcessed(pid)
                        ' Do nothing
                    else                        
                        body[0] = pid
                        pInfoRequestID = RequestProgramInfo(pid, headers, body)
                        AppendToProgram(pid, program)
                        SetProcessed(pid)
                    end if    
                end for                    
            else
                LogDebugObj("Response Failure Reason is ", msg.GetFailureReason())
                ' TODO: What should happen with non 200 response codes? 
                stop
            end if
        else
            ' TODO: Make async request useful instead of blocking
            'LogDebug("Do Useful stuff while wait for data")
        end if       
    end while
    requests.Clear()
    requests = ProgramInfoRequests()
    Reverse(requests)    
    while requests.Count() <> 0
        requestID = requests.Pop()
        port = GetAsyncRequestPort(requestID)
        msg = wait(100, port.GetMessagePort())
        if type(msg) = "roUrlEvent" then
            LogDebug("Server response received")
            LogDebugObj("Response Code is ", msg.GetResponseCode())
            ' TODO: Efficiently implement check of different response status codes here and deal
            ' with concerning circumstances appropriately            
            if msg.GetResponseCode() = 200 then
                ' TODO: If only one station is processed per request, this can be left alone.
                ' If more are processed, it may be necessary for add another for-each loop
                ' with the for-each program loop below nested within it.
                response = BuildResponse(msg)
                
                ' Immediately initiate requests for program info
                ProcessSchedulesDirectJSONProgramInfo(response.json)   
            else
                ' TODO: What should happen with non 200 response codes? 
                stop
            end if
        else
            ' TODO: Make async request useful instead of blocking
            'LogDebug("Do Useful stuff while wait for data")
        end if       
    end while        
End Function
