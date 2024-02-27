Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
  m.top.functionName = "runThread"
end sub

sub runThread()
  if not m.top.IMASDKInitialized
    initializeIMASDK()
  end if
  if not m.top.streamManagerReady
    loadStream()
  end if
  if m.top.streamManagerReady
    runLoop()
  end if
end sub

sub runLoop()
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
    if currentTime > 3 and not m.top.adPlaying
      m.top.video.enableTrickPlay = true
    end if
  end while
end sub

sub initializeIMASDK()
  if m.sdk = invalid
    sdk = New_IMASDK()
    sdk.initSdk()
    m.sdk = sdk
  end if
  m.top.IMASDKInitialized = true
end sub

sub setupVideoPlayer()
  sdk = m.sdk
  m.player = sdk.createPlayer()
  m.player.top = m.top
  m.player.streamInitialized = function(urlData)
    ' This line prevents users from scanning during buffering or during the first second of the
    ' ad before we have a callback from roku.
    ' If there are no prerolls disabling trickplay isn't needed.
    m.top.video.enableTrickPlay = false
    m.top.urlData = urlData
  end function
  m.player.adBreakStarted = function(adBreakInfo as object)
    print "------ Ad Break Started ------"
    m.top.adPlaying = True
    m.top.video.enableTrickPlay = false
  end function
  m.player.adBreakEnded = function(adBreakInfo as object)
    print "------ Ad Break Ended ------"
    m.top.adPlaying = False
    m.top.video.enableTrickPlay = true
  end function
  m.player.seek = function(timeSeconds as double)
    print "------ SDK requested seek to ------" ; timeSeconds
    m.top.video.seekMode = "accurate"
    m.top.video.seek = timeSeconds
  end function
end sub

sub loadStream()
  sdk = m.sdk
  setupVideoPlayer()
  request = sdk.CreateStreamRequest()

  ' setting customAssetKey and networkCode tells the SDK that this is a podserving stream
  request.customAssetKey = m.top.streamData.customAssetKey
  request.networkCode = m.top.streamData.networkCode

  request.apiKey = m.top.streamData.apiKey
  request.player = m.player
  request.adUiNode = m.top.video

  requestResult = sdk.requestStream(request)
  if requestResult <> invalid
    print "Error requesting stream ";requestResult
  else
    m.streamManager = invalid
    while m.streamManager = invalid
      sleep(50)
      m.streamManager = sdk.getStreamManager()
    end while
    if m.streamManager = invalid or m.streamManager["type"] <> invalid or m.streamManager["type"] = "error"
      errors = CreateObject("roArray", 1, True)
      print "error ";m.streamManager["info"]
      errors.push(m.streamManager["info"])
      m.top.errors = errors
    else
      m.top.streamManagerReady = True
      addCallbacks()
      m.streamManager.start()
    end if
  end if
end sub


sub addCallbacks()
  m.streamManager.addEventListener(m.sdk.AdEvent.ERROR, errorCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.START, startCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.FIRST_QUARTILE, firstQuartileCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.MIDPOINT, midpointCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.THIRD_QUARTILE, thirdQuartileCallback)
  m.streamManager.addEventListener(m.sdk.AdEvent.COMPLETE, completeCallback)
end sub

sub startCallback(ad as object)
  print "Callback from SDK -- Start called - "
end sub

sub firstQuartileCallback(ad as object)
  print "Callback from SDK -- First quartile called - "
end sub

sub midpointCallback(ad as object)
  print "Callback from SDK -- Midpoint called - "
end sub

sub thirdQuartileCallback(ad as object)
  print "Callback from SDK -- Third quartile called - "
end sub

sub completeCallback(ad as object)
  print "Callback from SDK -- Complete called - "
end sub

sub errorCallback(error as object)
  print "Callback from SDK -- Error called - "; error
  ' errors are critical and should terminate the stream.
  m.errorState = True
end sub
