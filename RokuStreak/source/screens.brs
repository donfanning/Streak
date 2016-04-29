'#######################################################################################
'#  Application screens. All application screens are dynamically generated allowing
'#  for highly reusable code. 
'#
'#  @author: Hayden McParlane
'#  @creation-date: 3.10.2016
'#######################################################################################

'#######################################################################################
'#  roDialogScreen
'#######################################################################################
Function DialogScreen(id as String, title as String, text as String, buttons as Object) as void
    screen = CreateObject("roAssociativeArray")
    
    ' TODO: HIGH Better way to do? Achieve more code reuse?
    ' TODO: HIGH Should "factory" be used to handle screen type?
    screen.id = id
    screen.screenType = "roMessageDialog"
    screen.title = title
    screen.text = text
    screen.buttons = ShallowCopy(buttons)
    LogDebugObj("Value of Dialog Screen -> ", screen)
    BufferScreen(id, screen)
End Function

Function RenderDialogScreen(title as String, text as String, buttons as Object) As Void
    port = CreateObject("roMessagePort")
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(port)
    screen.SetTitle(title)
    screen.SetText(text)    
    ' TODO: HIGH Is this pass by reference? Verify.
    AddButtons(screen, buttons)
    LogDebugObj("Printing screen back in render dialog -> ", screen)
    'screen.AddButton(1, "Username")
    'screen.AddButton(2, "Password")
    'screen.AddButtonSeparator()
    'screen.AddButton(3, "Login")
    screen.EnableBackButton(true)
    screen.Show()
    While True
        msg = wait(0, screen.GetMessagePort())        
        If type(msg) = "roMessageDialogEvent"
            if msg.isButtonPressed()
                btnID = msg.GetIndex()
                LogDebug("Handling button select")   
                HandleButtonSelectByID(btnID, buttons)
            else if msg.isScreenClosed()
                exit while
            end if
        end if
    end while
End Function


'#######################################################################################
'#  roKeyboardScreen
'#######################################################################################
Function KeyboardScreen(id as String, title as String, text as String, displayText as String, buttons as Object, secure as Boolean) as void
    screen = CreateObject("roAssociativeArray")
    
    ' TODO: HIGH Better way to do? Achieve more code reuse?
    ' TODO: HIGH Should "factory" be used to handle screen type?
    screen.id = id
    screen.screenType = "roKeyboardScreen"
    screen.title = title        
    screen.text = ""
    screen.displayText = displayText
    screen.buttons = ShallowCopy(buttons)
    screen.secure = secure
    LogDebugObj("Value of Keyboard Screen -> ", screen)
    BufferScreen(id, screen)
End Function

' TODO: Dynamic population of buttons requires assoc. array with following format:
' buttons = { { "id":1, "text": "example", "command":"nameOfFunction" }, ... }
Function RenderKeyboardScreen(title as String, text as String, displayText as String, buttons as Object, secure as Boolean) as Object
    screen = CreateObject("roKeyboardScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle(title)
    screen.SetText(text)
    screen.SetDisplayText(displayText)
    screen.SetMaxLength(50)
    AddButtons(screen, buttons)
    if secure
        screen.setSecureText(True)
    end if
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())        
        if type(msg) = "roKeyboardScreenEvent"
            if msg.isScreenClosed()
                return -1
            else if msg.isButtonPressed() then
                return HandleButtonSelectByScreen(screen, msg, buttons)
            endif
        endif
    endwhile
End Function


'#######################################################################################
'#  roGridScreen
'#######################################################################################
' Perform search for tv schedule listings based on input filters
Function RenderTVSchedule(dummyArg as Object) as integer ' TODO: Remove dummy arg when RenderTVSchedule is done using dynamic screen population.
    port = CreateObject("roMessagePort")                 ' right now it's present to 
    grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)    
    ' TODO: Below is O(num_keys_visible). Optimization can come from populating rows that aren't visible right before they become
    ' visible instead of populating all of the rows at once.       
    'titles = GetEpisodeTitles(EpisodeFilterTime())    
    'episodes = GetEpisodes(EpisodeFilterGenre())
    episodes = GetEpisodes()
    for each e in episodes
        print e
    end for
    titles = CreateObject("roArray", 1, True)
    for i = 0 to 10'episodes.Count() - 1
        titles.Push("[Row Title " + i.toStr() + " ]")
    end for
    'titles = episodes.keys() 'TODO: Titles should be stored and retrieved. Its much Faster
    grid.SetupLists(titles.Count())
    grid.SetListNames(titles)      
   
'    for i = 0 to 10'titles.Count() - 1 '=> Linear time ( O(num_keys_visible) )        
'       grid.SetContentList(i,episodes[i]) '=> keys will hash to list for row. Filtration will occur by storing different title types   
'    end for   
    grid.SetContentList(1,episodes)           
    grid.Show()            
    while true
         msg = wait(0, port)
         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return -1
             else if msg.isListItemFocused()

             else if msg.isListItemSelected()
                 
             end if
         end if
    end while
End Function  


'#######################################################################################
'#  roParagraphScreen
'#######################################################################################
' TODO: Make dynamic
Function ShowWelcomeScreen() As Void
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetTitle("Roku Streak")
    screen.AddHeaderText("[Header Text]")
    screen.AddParagraph("[Paragraph text 1 - Text in the paragraph screen is justified to the right and left edges]")
    screen.AddParagraph("[Paragraph text 2 - Multiple paragraphs may be added to the screen by simply making additional calls]")
    screen.AddButton(10, "Login to Schedules Direct")
    screen.AddButton(2, "Browse TV Listings")
    screen.SetDefaultMenuItem(1)
    screen.Show()
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                return
            else if msg.isButtonPressed() then                
                if msg.GetIndex() = 10
                    LogDebugObj("Button id 10 hit", msg.GetIndex())  
                    'buttons = CreateObject("roArray", 2, True)                    
                    'args1 = CreateObject("roAssociativeArray")
                    'args1.AddReplace("title","Enter Username")
                    'args1.AddReplace("displayText","[Sample Display Text]")                    
                    'testbutton = ConstructButton(1, "Finished", CommandStoreUsername()) 'TODO: Enter command args
                    'testbuttons = CreateObject("roArray", 1, True)                    
                    'testbuttons.Push(testbutton)          
                    'args1.AddReplace("buttons",testbuttons)
                    'button1 = ConstructButton(1, "Enter Username", CommandRenderKeyboardScreen()) 'TODO: Enter command args
                    'button2 = ConstructButton(2, "Password", "storePassword", {})
                    'button3 = ConstructButton(3, "Login", "login", {})                    
                    'buttons.Push(button1)
                    'buttons.Push(button2)
                    'buttons.Push(button3) 
                    'RenderDialogScreen("Login to Schedules Direct", "[Testing Text]", buttons)
                    return
                else if msg.GetIndex() = 2
                    ' TODO: Refactor so that render TV sched. uses above syntax if possible                   
                    'RenderTVSchedule()
                    return
                endif
            endif
        endif
    end while
End Function

Function ParagraphScreen(id as String,title as String, headerText as String, paragraphs as Object, buttons as Object) as void
    screen = CreateObject("roAssociativeArray")
    
    ' TODO: HIGH Better way to do? Achieve more code reuse?
    ' TODO: HIGH Should "factory" be used to handle screen type?
    screen.id = id
    screen.screenType = "roParagraphScreen"
    screen.title = title
    screen.headerText = headerText
    screen.buttons = ShallowCopy(buttons)
    screen.paragraphs = ShallowCopy(paragraphs)    
    LogDebugObj("Value of Paragraph Screen -> ", screen)
    BufferScreen(id, screen)
End Function

Function RenderParagraphScreen(title as String, headerText as String, buttons as Object, paragraphs as Object) As Void
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetTitle(title)
    screen.AddHeaderText(headerText)    
    AddParagraphs(screen, paragraphs)    
    AddButtons(screen, buttons)
    screen.SetDefaultMenuItem(1)
    screen.Show()
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roParagraphScreenEvent"        
            if msg.isScreenClosed()
                return
            else if msg.isButtonPressed() then                
                btnId = msg.GetIndex()
                HandleButtonSelectByID(btnID, buttons)
            endif
        endif
    end while
End Function

'#######################################################################################
'#-------------------Facade screen (keeps app from closing) ---------------------------- 
'#  see https://sdkdocs.roku.com/display/sdkdoc/Working+with+Screens
'#######################################################################################
'TODO: Implement facade screen
Function RenderFacadeScreen() as void
    facade = CreateObject("roParagraphScreen")
    port = CreateObject("roMessagePort")
    facade.SetMessagePort(port)
    facade.AddParagraph("please wait...")
    facade.show()
End Function

'ParagraphScreen("welcome" ,"Roku Streak", "[this]", pButtons, paragraphs)
'DialogScreen("login", "Login to Schedules Direct", "[Testing text]", dButtons)
'KeyboardScreen("username", "Enter Username", "[displayText]", kButtonsUsername)
'KeyboardScreen("password", "Enter Password", "[displayText]", kButtonsPassword)

' TODO: Change name. Buffering implies removal at some point (temp storage). Screens won't 
' normally be buffered to later be removed.
Function BufferScreen(screenID as String, screen as Object) as void
    LogDebugObj("Buffering screen -> " + screenID, screen)
    ' TODO: HIGH Determine whether screen key verification should occur here    
    base = GetScreenPathBase()
    base[screenID] = screen
End Function

Function RetrieveScreen(screenID as String) as Object
    LogDebug("Retrieving screen -> " + screenID) 
    base = GetScreenPathBase()
    CreateIfDoesntExist(m, screenID, "roAssociativeArray")
    return base[screenID]
End Function


Function GetScreenPathBase() as Object
    CreateIfDoesntExist(m, "screens", "roAssociativeArray")
    return m.screens
End Function

Function SetScreenPathBase(o as Object) as void
    CreateIfDoesntExist(m, "screens", "roAssociativeArray")
    m.screens = o
End Function

Function ShowScreen(startID as String) as void
    ' TODO: Setup so that screen set first is initiated first. Right now, hard coded.
    RenderNextScreen(startID)
End Function
    
'#######################################################################################
'#  Helper functions
'#######################################################################################
Function AddParagraphs(screen as Object, paragraphs as Object) as void
    for each paragraph in paragraphs
        screen.AddParagraph(paragraph)
    end for
End Function

' buttons = { { "id":integer, "title": "example", "command":"nameOfFunction", "args":{ command_arguments } }, ... }
Function AddButtons(screen as Object, buttons as Object) as void
    LogDebugObj("Printing screen before button add -> ", screen)    
    for each button in buttons
        screen.AddButton(button[ButtonID()], button[ButtonTitle()])
    end for
    LogDebugObj("Printing screen after button add -> ", screen)
End Function

Function HandleButtonSelectByScreen(screen as Object, msg as Object, buttons as Object) as Object
    ' Pre-process unique events before button processing
    id = msg.GetIndex()
    if type(msg) = "roKeyboardScreenEvent"                
        data = GetButtonData(id)
        data[ButtonCommandArguments()]["entry"] = screen.GetText()
        SetButtonData(id, data)
    end if
    return HandleButtonSelectByID(id, buttons)
End Function

Function HandleButtonSelectByID(id as Integer, buttons as Object) as Object
    LogDebugObj("Printing button id ->", id)        
    data = GetButtonData(id)
    return ExecuteButtonCommand(data[ButtonCommand()], data[ButtonCommandArguments()])
End Function

' TODO: Abstract away button id so that all that matters is command and title
Function CreateButton(title as String, command as Object, args as Object) as Object
    ' TODO: Remove redundent command key?
    button = CreateObject("roAssociativeArray")
    button[ButtonID()] = GenerateButtonID()
    button[ButtonTitle()] = title    
    
    ' Associate command and arguments with button
    current = CreateObject("roAssociativeArray")   
    currentID = button[ButtonID()]
    LogDebugObj("Current ID is -> ", currentID)
    current[ButtonCommand()] = command
    current[ButtonCommandArguments()] = ShallowCopy(args)   
    SetButtonData( currentID, current )
    
    return button
End Function

' TODO: HIGH Refactor id generation such that unused IDs are re-entered into ID pool.
' This takes care of quite unlikely case of application with huge numbers of buttons,
' but will, nonetheless, guarentee application bugs won't be related to button ID
' assignment.
Function GenerateButtonID() as integer
    base = GetButtonBase()
    CreateIfDoesntExist(base, "id", "roInt")
    gid = GetGlobalButtonID()
    LogDebugObj("Button gid before inc-> ", gid)
    id = gid
    SetGlobalButtonID( gid + 1 )
    LogDebugObj("Button gid after inc -> ", GetGlobalButtonID())
    return id
End Function

' TODO: CreateIfDoesntExist only accepts string values. How to implement if array is used?
Function GetButtonData( id as integer) as Object
    base = GetButtonIDList()    
    return base[id]
End Function

Function SetButtonData( id as integer, o as Object) as void
    base = GetButtonIDList()    
    base[id] = o
End Function

Function GetGlobalButtonID() as integer
    base = GetButtonBase()
    CreateIfDoesntExist(base, "gid", "roInt")
    return base.gid
End Function

Function SetGlobalButtonID(id as integer) as Object
    base = GetButtonBase()    
    base.gid = id
End Function

Function GetButtonIDList() as Object
    base = GetButtonBase()
    CreateIfDoesntExist(base, "ids", "roArray")
    return base.ids
End Function

Function SetButtonIDList(o as object) as Object
    base = GetButtonBase()    
    base.ids = o
End Function

Function GetButtonBase() as Object
    CreateIfDoesntExist(m, "buttons", "roAssociativeArray")
    return m.buttons
End Function

Function SetButtonBase(o as Object) as Object
    return m.buttons
End Function

Function ButtonID() as String
    return "id"    
End Function

Function ButtonTitle() as String
    return "title"    
End Function

Function ButtonCommand() as String
    return "command"    
End Function

Function ButtonCommandArguments() as String
    return "args"
End Function

'#######################################################################################
'#  Screen-related commands
'#######################################################################################
' TODO: HIGH Should this command involve direct base.nextScreen.nextID
' or should that be abstracted away? Will other screens need to know
' the type of screen they are being called from or other similar info?
Function ShowNextScreen(nextScreenID as String)
    LogDebug("Executing command: ShowNextScreen")
    RenderNextScreen(nextScreenID)
End Function

Function RenderNextScreen(nextID as String) as void    
    ' TODO: HIGH Refactor/redesign such that screen differences are
    ' efficiently dealt with. Avoid if? What other designs?
    screen = RetrieveScreen(nextID)
    LogDebug("Rendering next screen -> " + nextID + ", type -> " + screen.screenType)
    LogDebugObj("", screen)       
    if screen.screenType = "roParagraphScreen"
        RenderParagraphScreen(screen.title, screen.headerText, screen.buttons, screen.paragraphs)
    else if screen.screenType = "roMessageDialog"
        RenderDialogScreen(screen.title, screen.text, screen.buttons)
    else if screen.screenType = "roKeyboardScreen"
        RenderKeyboardScreen(screen.title, screen.text, screen.displayText, screen.buttons, screen.secure)
    else
        LogError("Screen type either not valid or unimplemented -> " + screen.screenType)
        stop
    end if
End Function

Function ExecuteLogin(args)
    ' Hash the password as desired
    hash = GetSchedulesAPIHashType()
    base = GetScreenStoreBase()
    if not base.DoesExist(Username())
        LogError("Username not yet entered")
        stop
    end if
    if not base.DoesExist(Password())
        LogError("Password not yet entered")
        stop
    end if
    user = base[Username()]
    pass = Digest(base[Password()], hash)
    
    ' Store username and password in persistent storage    
    SetSchedulesAPIAuthData(user, pass)
End Function

' Command to store entry at storageLocation
' Input: args roAssociativeArray with keys entry and storageLocation defined
Function StoreKeyboardEntry(args as Object) as Object
    base = GetScreenStoreBase()
    entry = args.entry
    storageLocation = args.storageLocation
    CreateIfDoesntExist(base, storageLocation, "roString")
    base[storageLocation] = entry
    ' TODO: Dynamically allow multiple commands to be executed.
    ' This will mean after storage, one can return to correct screen.
    ' Also note, this will eventually cause memory fill. Screens are stacked.
    ShowScreen("welcome")
    'return storageLocation
End Function

Function GetScreenStoreBase() as Object
    base = GetScreenPathBase()
    CreateIfDoesntExist(base, "store", "roAssociativeArray")
    return base.store
End Function

Function ExecuteButtonCommand( command as Object, args as Object ) as Object
    result = command(args)
    return result
End Function