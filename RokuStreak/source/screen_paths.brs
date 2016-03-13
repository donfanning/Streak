'#######################################################################################
'#  Screen pathway definitions.
'#
'#  @author: Hayden McParlane
'#  @creation-date: 3.10.2016
'#######################################################################################
Function WelcomeScreen() as void
    aa = CreateObject("roAssociativeArray")
    pButtons = CreateObject("roArray", 1, True)
    oButtons = CreateObject("roArray", 1, True)
    kButtonsUser = CreateObject("roArray", 1, True)
    kButtonsPass = CreateObject("roArray", 1, True)
    paragraphs = CreateObject("roArray", 2, True)
    paragraphs.Push("[Paragraph text 1]")
    paragraphs.Push("[Paragraph text 2 - Multiple paragraphs may be added to the screen by simply making additional calls]")
    
        
    ' TODO HIGH Abstract away button IDs so that auto-generated by library
    pButtons.Push( ConstructButton("Button 1", ShowNextScreen(), "other") )
    ParagraphScreen("welcome" ,"Roku Streak", "[this]", pButtons, paragraphs)    
    'dButtons.Push( ConstructButton(1, "Enter Username", CommandNextScreen("username")) )
    'dButtons.Push( ConstructButton(2, "Enter Password", CommandNextScreen("password")) )
    oButtons.Push( ConstructButton("Button 2", ShowNextScreen(), "welcome") )                
    ParagraphScreen("other" ,"Other", "[this]", oButtons, paragraphs)
    'DialogScreen("login", "Login to Schedules Direct", "[Testing text]", dButtons)
    'KeyboardScreen("username", "Enter Username", "[displayText]", kButtonsUsername)
    'KeyboardScreen("password", "Enter Password", "[displayText]", kButtonsPassword)
    
    RenderScreen("welcome")
    'ShowWelcomeScreen()        
End Function