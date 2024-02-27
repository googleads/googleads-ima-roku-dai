function init()
    m.video = m.top.findNode("myVideo")
    m.video.notificationinterval = 1

    m.testPodservingStream = {
      title: "Pod Serving stream"
      customAssetKey: "google-sample"
      networkCode: "51636543"
      manifestUrl: "https://encodersim.sandbox.google.com/masterPlaylist/9c654d63-5373-4673-8c8d-6d92b66b9d46/master.m3u8?gen-seg-redirect=true&network=51636543&event=google-sample&pids=devrel4628000,devrel896000,devrel3528000,devrel1428000,devrel2628000,devrel1928000&seg-host=dai.google.com&stream_id=[[STREAMID]]"
      apiKey: "",
      type: "podserving"
    }

    loadImaSdk()
  end function

function loadImaSdk() as void
  m.sdkTask = createObject("roSGNode", "imasdk")
  m.sdkTask.observeField("sdkLoaded", "onSdkLoaded")
  m.sdkTask.observeField("errors", "onSdkLoadedError")

  selectedStream = m.testPodservingStream
  m.videoTitle = selectedStream.title
  m.sdkTask.streamData = selectedStream

  m.sdkTask.observeField("urlData", "loadAdPodStream")
  m.sdkTask.video = m.video
  ' Setting control to run starts the task thread.
  m.sdkTask.control = "RUN"
end function

Sub loadAdPodStream(message as Object)
  print "Url Load Requested ";message
  data = message.getData()
  streamId = data.streamId
  manifest = m.sdkTask.streamData.manifestUrl.Replace("[[STREAMID]]", streamId)
  playStream(manifest, data.format)
End Sub

Sub playStream(url as String, format as String)
  vidContent = createObject("RoSGNode", "ContentNode")
  vidContent.url = url
  vidContent.title = m.videoTitle
  vidContent.streamformat = format
  m.video.content = vidContent
  m.video.setFocus(true)
  m.video.visible = true
  m.video.control = "play"
  m.video.EnableCookies()
End Sub

Sub onSdkLoaded(message as Object)
  print "----- onSdkLoaded --- control ";message
End Sub

Sub onSdkLoadedError(message as Object)
  print "----- errors in the sdk loading process --- ";message
End Sub
