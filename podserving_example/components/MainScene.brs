sub init()
  m.video = m.top.findNode("myVideo")
  m.video.notificationinterval = 1

  m.testPodservingStream = {
    title: "Pod Serving stream"
    customAssetKey: "google-sample"
    networkCode: "51636543"
    manifestUrl: "https://encodersim.sandbox.google.com/masterPlaylist/9c654d63-5373-4673-8c8d-6d92b66b9d46/master.m3u8?gen-seg-redirect=true&network=51636543&event=google-sample&pids=devrel4628000,devrel896000,devrel3528000,devrel1428000,devrel2628000,devrel1928000&seg-host=dai.google.com&stream_id=[[STREAMID]]"
    apiKey: ""
  }

  loadImaSdk()
end sub

sub loadImaSdk()
  m.IMASDKTask = createObject("roSGNode", "IMASDKTask")
  m.IMASDKTask.observeField("sdkLoaded", "onSdkLoaded")
  m.IMASDKTask.observeField("errors", "onSdkLoadedError")

  selectedStream = m.testPodservingStream
  m.videoTitle = selectedStream.title
  m.IMASDKTask.streamData = selectedStream

  m.IMASDKTask.observeField("urlData", "loadAdPodStream")
  m.IMASDKTask.video = m.video
  ' Setting control to run starts the task thread.
  m.IMASDKTask.control = "RUN"
end sub

sub loadAdPodStream(message as object)
  print "Url Load Requested ";message
  data = message.getData()
  streamId = data.streamId
  manifest = m.IMASDKTask.streamData.manifestUrl.Replace("[[STREAMID]]", streamId)
  playStream(manifest, data.format)
end sub

sub playStream(url as string, format as string)
  vidContent = createObject("RoSGNode", "ContentNode")
  vidContent.url = url
  vidContent.title = m.videoTitle
  vidContent.streamformat = format
  m.video.content = vidContent
  m.video.setFocus(true)
  m.video.visible = true
  m.video.control = "play"
  m.video.EnableCookies()
end sub

sub onSdkLoaded(message as object)
  print "----- onSdkLoaded --- control ";message
end sub

sub onSdkLoadedError(message as object)
  print "----- errors in the sdk loading process --- ";message
end sub
