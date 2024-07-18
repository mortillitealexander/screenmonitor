#include <ScreenCapture.au3>
#include <Timers.au3>
#include <GDIPlus.au3>
#include <WinAPI.au3>

Global $prevScreenshot = @ScriptDir & "\prevScreenshot.bmp"
Global $currScreenshot = @ScriptDir & "\currScreenshot.bmp"
Global $screenshotInterval = 1000 ; 1 minute in milliseconds
Global $failCounter = 0
Global $maxFails = 1
Global $ignoreBottomPixels = 100

; Delete previous and current screenshots if they exist
If FileExists($prevScreenshot) Then FileDelete($prevScreenshot)
If FileExists($currScreenshot) Then FileDelete($currScreenshot)

Func CaptureScreenshot($filename)
    ;~ Local $hWnd = WinGetHandle("[CLASS:Notepad]")
    Local $hWnd = WinGetHandle("[REGEXPTITLE:(?i).*MultiCharts64.*]")
    If $hWnd = 0 Then
        ConsoleWrite("Multicharts is not running." & @CRLF)
        Return False
    EndIf
    WinActivate($hWnd) ; Activate the window
    _ScreenCapture_CaptureWnd($filename, $hWnd)
    Return True
EndFunc

Func CompareScreenshots()
    _GDIPlus_Startup()
    Local $hImage1 = _GDIPlus_ImageLoadFromFile($prevScreenshot)
    Local $hImage2 = _GDIPlus_ImageLoadFromFile($currScreenshot)
    
    Local $width1 = _GDIPlus_ImageGetWidth($hImage1)
    Local $height1 = _GDIPlus_ImageGetHeight($hImage1)
    Local $width2 = _GDIPlus_ImageGetWidth($hImage2)
    Local $height2 = _GDIPlus_ImageGetHeight($hImage2)
    
    ; Adjust the height to ignore the bottom 100 pixels
    Local $adjustedHeight1 = $height1 - $ignoreBottomPixels
    Local $adjustedHeight2 = $height2 - $ignoreBottomPixels
    
    If $width1 <> $width2 Or $adjustedHeight1 <> $adjustedHeight2 Then
        _GDIPlus_ImageDispose($hImage1)
        _GDIPlus_ImageDispose($hImage2)
        _GDIPlus_Shutdown()
        Return False
    EndIf
    
    For $x = 0 To $width1 - 1
        For $y = 0 To $adjustedHeight1 - 1
            Local $color1 = _GDIPlus_BitmapGetPixel($hImage1, $x, $y)
            Local $color2 = _GDIPlus_BitmapGetPixel($hImage2, $x, $y)
            If $color1 <> $color2 Then
                _GDIPlus_ImageDispose($hImage1)
                _GDIPlus_ImageDispose($hImage2)
                _GDIPlus_Shutdown()
                Return False
            EndIf
        Next
    Next
    
    _GDIPlus_ImageDispose($hImage1)
    _GDIPlus_ImageDispose($hImage2)
    _GDIPlus_Shutdown()
    
    Return True
EndFunc

Func RestartProgram()
    RunWait('taskkill /f /im MultiCharts64.exe')
    RunWait('taskkill /f /im TradingServer.exe')
    RunWait('taskkill /f /im tsServer.exe')
    RunWait('taskkill /f /im StudyServer.exe')
    RunWait('taskkill /f /im MessageCenter.exe')
    RunWait('taskkill /f /im MessageCenternet.exe')
    RunWait('taskkill /f /im ATCenterServer.exe')
    RunWait('taskkill /f /im BitfinexServerHost.exe')
    Sleep(10000)
    Run('"C:\Program Files\TS Support\MultiCharts64\MultiCharts64.exe"')
    $failCounter = 0 ; Reset the fail counter after restarting
EndFunc

While True
    ; Capture the Notepad window
    If CaptureScreenshot($currScreenshot) Then
        ; If the previous screenshot exists, compare it with the current one
        If FileExists($prevScreenshot) Then
            If CompareScreenshots() Then
                $failCounter += 1
                If $failCounter >= $maxFails Then
                    RestartProgram()
                EndIf
            Else
                $failCounter = 0 ; Reset the fail counter if screenshots are different
            EndIf
        EndIf

        ; Move the current screenshot to previous screenshot
        FileMove($currScreenshot, $prevScreenshot, 1)
    EndIf


    ;~ debug
    ;~ SplashTextOn("Title", $failCounter, 200, 50)

    ; Wait for the specified interval
    Sleep($screenshotInterval)

    ;~ SplashOff()
    ;~ Sleep(100)
WEnd
