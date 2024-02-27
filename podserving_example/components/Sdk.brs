Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
  m.top.functionName = "runThread"
End Sub

sub runThread()
  if not m.top.sdkLoaded
    loadSdk()
  End If
  if not m.top.streamManagerReady
    loadStream()
  End If
  If m.top.streamManagerReady
    runLoop()
  End If
End Sub

Sub runLoop()
  ' Forward all timed metadata events.
  m.top.video.timedMetaDataSelectionKeys = ["*"]

  ' Cycle through all the fields and just listen to them all.
  m.port = CreateObject("roMessagePort")
  fields = m.top.video.getFields()
  for each field in fields
    m.top.video.observeField(field, m.port)
  end for

  while True
    msg = wait(1000, m.port)
    if m.top.video = invalid
      print "exiting"
      exit while
    end if

    m.streamManager.onMessage(msg)
    currentTime = m.top.video.position
    ' Only enable trickplay after a few seconds, in case we start with an ad,
    ' to prevent users from skipping through that ad.
    If currentTime > 3 And not m.top.adPlaying
       m.top.video.enableTrickPlay = true
    End If
  end while
End Sub

sub loadSdk()
  If m.sdk = invalid
    m.sdk = New_IMASDK()
  End If
  m.top.sdkLoaded = true
End Sub

sub setupVideoPlayer()
  sdk = m.sdk
  m.player = sdk.createPlayer()
  m.player.top = m.top
  m.player.streamInitialized = Function(urlData)
    ' This line prevents users from scanning during buffering or during the first second of the
    ' ad before we have a callback from roku.
    ' If there are no prerolls disabling trickplay isn't needed.
    m.top.video.enableTrickPlay = false
    m.top.urlData = urlData
  End Function
  m.player.adBreakStarted = Function(adBreakInfo as Object)
    print "---- Ad Break Started ---- "
    m.top.adPlaying = True
    m.top.video.enableTrickPlay = false
  End Function
  m.player.adBreakEnded = Function(adBreakInfo as Object)
    print "---- Ad Break Ended ---- "
    m.top.adPlaying = False
    m.top.video.enableTrickPlay = true
  End Function
  m.player.seek = Function(timeSeconds as Double)
    print "---- SDK requested seek to ----" ; timeSeconds
    m.top.video.seekMode = "accurate"
    m.top.video.seek = timeSeconds
  End Function
End Sub

Sub loadStream()
  sdk = m.sdk
  sdk.initSdk()
  setupVideoPlayer()
  request = sdk.CreateStreamRequest()

  ' setting customAssetKey and networkCode tells the SDK that this is a podserving stream
  request.customAssetKey = m.top.streamData.customAssetKey
  request.networkCode = m.top.streamData.networkCode

  request.apiKey = m.top.streamData.apiKey
  request.player = m.player
  request.adUiNode = m.top.video

  requestResult = sdk.requestStream(request)
  If requestResult <> Invalid
    print "Error requesting stream ";requestResult
  Else
    m.streamManager = Invalid
    While m.streamManager = Invalid
      sleep(50)
      m.streamManager = sdk.getStreamManager()
    End While
    If m.streamManager = Invalid or m.streamManager["type"] <> Invalid or m.streamManager["type"] = "error"
      errors = CreateObject("roArray", 1, True)
      print "error ";m.streamManager["info"]
      errors.push(m.streamManager["info"])
      m.top.errors = errors
    Else
      m.top.streamManagerReady = True
      addCallbacks()
      m.streamManager.start()
    End If
  End If
End Sub


Function addCallbacks() as Void
  m.streamManager.addEventListener(m.sdk.AdEvent.ERROR, errorCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.START, startCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.FIRST_QUARTILE, firstQuartileCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.MIDPOINT, midpointCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.THIRD_QUARTILE, thirdQuartileCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.COMPLETE, completeCallback)
End Function

Function startCallback(ad as Object) as Void
  print "Callback from SDK -- Start called - "
End Function

Function firstQuartileCallback(ad as Object) as Void
  print "Callback from SDK -- First quartile called - "
End Function

Function midpointCallback(ad as Object) as Void
  print "Callback from SDK -- Midpoint called - "
End Function

Function thirdQuartileCallback(ad as Object) as Void
  print "Callback from SDK -- Third quartile called - "
End Function

Function completeCallback(ad as Object) as Void
  print "Callback from SDK -- Complete called - "
End Function

Function errorCallback(error as Object) as Void
  print "Callback from SDK -- Error called - "; error
  ' errors are critical and should terminate the stream.
  m.errorState = True
End Function
