sub init()
  m.video = m.top.findNode("myVideo")
  m.video.notificationinterval = 1

  m.testPodservingStream = {
    title: "Test live stream for DAI Pod Serving"
    assetKey: "test-live-stream"
    networkCode: "21775744923"
    manifest: "https://.../master.m3u8?stream_id=[[STREAMID]]"
    apiKey: ""
  }

  runIMASDKTask()
end sub

sub runIMASDKTask()
  m.IMASDKTask = createObject("roSGNode", "IMASDKTask")

  m.IMASDKTask.streamParameters = m.testPodservingStream
  m.IMASDKTask.videoNode = m.video

  m.IMASDKTask.observeField("IMASDKInitialized", "handleIMASDKInitialized")
  m.IMASDKTask.observeField("errors", "handleIMASDKErrors")
  m.IMASDKTask.observeField("urlData", "loadAdStitchedStream")

  ' Start the task thread.
  m.IMASDKTask.control = "RUN"
end sub

sub loadAdStitchedStream(message as object)
  print "Ad pod stream information ";message
  adPodStreamInfo = message.getData()
  manifest = m.testPodservingStream.manifest.Replace("[[STREAMID]]", adPodStreamInfo.streamId)
  playStream(manifest, adPodStreamInfo.format)
end sub

sub playStream(url as string, format as string)
  vidContent = createObject("RoSGNode", "ContentNode")
  vidContent.url = url
  vidContent.title = m.testPodservingStream.title
  vidContent.streamformat = format
  m.video.content = vidContent
  m.video.setFocus(true)
  m.video.visible = true
  m.video.control = "play"
  m.video.EnableCookies()
end sub

sub handleIMASDKInitialized()
  ' Follow your manifest manipulator (VTP) documentation to register a user
  ' streaming session if needed.
end sub

sub handleIMASDKErrors(message as object)
  print "------ IMA SDK failed  ------"
  if message <> invalid and message.getData() <> invalid
    print "IMA SDK Error ";message.getData()
  end if
end sub
