Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
  m.top.functionName = "runThread"
end sub

sub runThread()
  if not m.top.IMASDKInitialized
    initializeIMASDK()
  end if

  ' Set up the callbacks for IMA SDK to trigger at ad stream initialization,
  ' ad break start and end events.
  setupPlayerCallbacks()

  loadAdPodStream()
  if m.streamManager <> invalid
    runLoop()
  end if
end sub

sub runLoop()
  ' Forward all timed metadata events.
  m.top.videoNode.timedMetaDataSelectionKeys = ["*"]

  ' Cycle through all the fields and just listen to them all.
  m.port = CreateObject("roMessagePort")
  m.top.videoNode.observeField("timedMetaData", m.port)

  while True
    msg = wait(1000, m.port)
    if m.top.videoNode = invalid
      print "exiting"
      exit while
    end if

    if msg <> invalid and msg.getData() <> invalid
      print "msg " ; msg.getData()
    end if

    m.streamManager.onMessage(msg)
    currentTime = m.top.videoNode.position
    ' Only enable trickplay after a few seconds, in case we start with an ad,
    ' to prevent users from skipping through that ad.
    if currentTime > 3 and not m.top.adPlaying
      m.top.videoNode.enableTrickPlay = true
    end if
  end while
end sub

sub initializeIMASDK()
  if m.ima = invalid
    ima = New_IMASDK()
    ima.initSdk()
    m.ima = ima
  end if
  m.top.IMASDKInitialized = true
end sub

sub setupPlayerCallbacks()
  m.player = m.ima.createPlayer()

  ' Set the player's top to be the IMASDKTask component's top.
  ' This allows the player's callbacks access to the component's the component's XML fields.
  m.player.top = m.top

  m.player.streamInitialized = function(urlData)
    ' Disable the user trickplay buttons on the remote to prevent users from
    ' scanning during the first second of the preroll ads and before
    ' the `adBreakStarted` callback is triggered.
    ' If there are no preroll ads, disabling trickplay isn't needed.
    m.top.videoNode.enableTrickPlay = false
    m.top.urlData = urlData
  end function

  m.player.adBreakStarted = function(adBreakInfo)
    print "------ Ad break started ------"
    m.top.adPlaying = true

    ' Disable the user trickplay buttons on the remote to prevent users from
    ' scanning during the first second of the midroll ads.
    m.top.videoNode.enableTrickPlay = false
  end function

  m.player.adBreakEnded = function(adBreakInfo)
    print "------ Ad break ended ------"
    m.top.adPlaying = false

    ' Enable the user trickplay buttons on the remote for scanning content
    ' stream after an ad break ends.
    m.top.videoNode.enableTrickPlay = true
  end function

end sub

sub loadAdPodStream()
  request = m.ima.CreatePodLiveStreamRequest(m.top.streamParameters.assetKey, m.top.streamParameters.networkCode, m.top.streamParameters.apiKey)

  ' Set the player object so that the request can trigger the player's
  ' callbacks at stream initialization or playback events.
  request.player = m.player

  ' Set the video node for the IMA SDK to create ad UI as its child nodes.
  request.adUiNode = m.top.video

  requestResult = m.ima.requestStream(request)
  if requestResult <> invalid
    print "Error requesting stream ";requestResult
    return
  end if

  m.streamManager = invalid
  while m.streamManager = invalid
    sleep(50)
    m.streamManager = m.ima.getStreamManager()
  end while

  if m.streamManager = invalid
    errors = CreateObject("roArray", 1, True)
    invalidStreamManagerError = "Invalid stream manager"
    print invalidStreamManagerError
    errors.push(invalidStreamManagerError)
    m.top.errors = errors
    return
  end if

  if m.streamManager["type"] <> invalid and m.streamManager["type"] = "error"
    errors = CreateObject("roArray", 1, True)
    print "Stream request returns an error. " ; m.streamManager["info"]
    errors.push(m.streamManager["info"])
    m.top.errors = errors
    return
  end if

  setupStreamManager()
  m.streamManager.start()
end sub

sub setupStreamManager()
  m.streamManager.addEventListener(m.ima.AdEvent.ERROR, onAdError)
  m.streamManager.addEventListener(m.ima.AdEvent.START, onAdStarted)
  m.streamManager.addEventListener(m.ima.AdEvent.FIRST_QUARTILE, onAdFirstQuartile)
  m.streamManager.addEventListener(m.ima.AdEvent.MIDPOINT, onAdMidPoint)
  m.streamManager.addEventListener(m.ima.AdEvent.THIRD_QUARTILE, onAdThirdQuartile)
  m.streamManager.addEventListener(m.ima.AdEvent.COMPLETE, onAdComplete)
end sub

sub onAdStarted(ad as object)
  print "Ad started"
end sub

sub onAdFirstQuartile(ad as object)
  print "Ad first quartile reached"
end sub

sub onAdMidPoint(ad as object)
  print "Ad mid point reached"
end sub

sub onAdThirdQuartile(ad as object)
  print "Ad third quartile reported"
end sub

sub onAdComplete(ad as object)
  print "Ad completed"
end sub

sub onAdError(error as object)
  print "Ad error " ; error
  ' errors are critical and should terminate the stream.
  m.errorState = True
end sub
