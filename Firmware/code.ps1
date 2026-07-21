try {
    [Console]::CursorVisible = $false
} catch {
}

try {
    [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager,Windows.Media.Control,ContentType=WindowsRuntime] | Out-Null
} catch {
    try {
        Add-Type -AssemblyName Windows.Media.Control
    } catch {
        $script:MediaControlSupported = $false
    }
}

if (-not $script:MediaControlSupported) {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    $script:AsTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and
        $_.IsGenericMethodDefinition -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.IsGenericType -and
        $_.GetParameters()[0].ParameterType.GetGenericTypeDefinition().Name -eq 'IAsyncOperation`1'
    }) | Select-Object -First 1

    if (-not $script:AsTaskGeneric) {
        $script:AsTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and
            $_.IsGenericMethodDefinition -and
            $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.IsGenericType
        }) | Select-Object -First 1
    }

    $script:MediaControlSupported = ($null -ne $script:AsTaskGeneric)
}

function Await($WinRtTask, $ResultType) {
    if ($null -eq $WinRtTask) {
        return $null
    }

    $asTask = $script:AsTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

function Get-SerialPortName {
    if ($env:SPOTIFY_SERIAL_PORT) {
        return $env:SPOTIFY_SERIAL_PORT
    }

    $portCandidates = @()

    try {
        $portCandidates = @(Get-CimInstance Win32_SerialPort | Where-Object { $_.DeviceID -match '^COM\d+' })
    } catch {
        $portCandidates = @()
    }

    if ($portCandidates.Count -eq 0) {
        return $null
    }

    foreach ($port in $portCandidates) {
        $caption = $port.Caption
        if ($caption -match 'USB|Arduino|XIAO|RP2040|Serial') {
            return $port.DeviceID
        }
    }

    return $portCandidates[0].DeviceID
}

function Send-TrackToSerial {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Payload
    )

    $portName = Get-SerialPortName
    if (-not $portName) {
        return
    }

    try {
        $serialPort = [System.IO.Ports.SerialPort]::new($portName, 115200)
        $serialPort.Open()
        $serialPort.WriteLine($Payload)
        $serialPort.Close()
    } catch {
    }
}

function Get-SpotifyTrackInfo {
    $process = Get-Process -Name spotify -ErrorAction SilentlyContinue | Sort-Object StartTime | Select-Object -First 1

    if (-not $process) {
        return $null
    }

    $windowTitle = $process.MainWindowTitle
    if ([string]::IsNullOrWhiteSpace($windowTitle)) {
        return $null
    }

    $title = $windowTitle.Trim()
    if ($title -eq 'Spotify' -or $title -eq 'Spotify Premium' -or $title -eq 'Spotify Free') {
        return $null
    }

    return $title
}

function Get-ActiveSessionData {
    if (-not $script:MediaControlSupported) {
        return $null
    }

    try {
        $managerTask = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()
        $manager = Await $managerTask ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])

        if (-not $manager) {
            return $null
        }

        foreach ($session in @($manager.GetSessions())) {
            try {
                $playbackInfo = $session.GetPlaybackInfo()
                if (-not $playbackInfo) {
                    continue
                }

                if ($playbackInfo.PlaybackStatus -ne [Windows.Media.Control.GlobalSystemMediaTransportControlsPlaybackStatus]::Playing) {
                    continue
                }

                $mediaPropertiesTask = $session.TryGetMediaPropertiesAsync()
                $mediaProperties = Await $mediaPropertiesTask ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
                $timeline = $session.GetTimelineProperties()

                if (-not $mediaProperties -or [string]::IsNullOrWhiteSpace($mediaProperties.Title)) {
                    continue
                }

                $sourceId = $session.SourceAppUserModelId
                if ($sourceId -and $sourceId -match 'spotify') {
                    $positionSeconds = $null
                    $durationSeconds = $null

                    if ($timeline) {
                        $positionSeconds = [Math]::Floor([double]$timeline.Position.TotalSeconds)
                        $durationSeconds = [Math]::Floor([double]$timeline.EndTime.TotalSeconds)
                    }

                    return [pscustomobject]@{
                        Title = $mediaProperties.Title
                        Artist = if ($mediaProperties.Artist) { $mediaProperties.Artist } else { 'Spotify' }
                        PositionSeconds = $positionSeconds
                        DurationSeconds = $durationSeconds
                    }
                }
            } catch {
            }
        }
    } catch {
    }

    return $null
}

function Get-SpotifyPlaybackData {
    $sessionData = Get-ActiveSessionData
    if ($sessionData) {
        return $sessionData
    }

    $windowTitle = Get-SpotifyTrackInfo
    if ($windowTitle) {
        return [pscustomobject]@{
            Title = $windowTitle
            Artist = 'Spotify'
            PositionSeconds = $null
            DurationSeconds = $null
        }
    }

    return $null
}

try {
    while ($true) {
        try {
            $track = Get-SpotifyPlaybackData

            if ($track) {
                $position = $track.PositionSeconds
                $duration = $track.DurationSeconds

                if ($duration -gt 0) {
                    $payload = [string]::Format('{0}|{1}|{2}|{3}', $track.Title, $track.Artist, $position, $duration)
                } else {
                    $payload = [string]::Format('{0}|{1}||', $track.Title, $track.Artist)
                }

                Send-TrackToSerial -Payload $payload
            }
        } catch {
        }

        Start-Sleep -Seconds 1
    }
} finally {
    try {
        [Console]::CursorVisible = $true
    } catch {
    }
}