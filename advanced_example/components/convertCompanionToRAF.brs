' Converts the companion data from VAST ad to a RAF style ad.
Function convertToRaf(adInfo as Object, currentTime as Integer) as Object
  adPods = []
  adPod = buildAdPod(adInfo, currentTime)
  adPods.push(adPod)
  return adPods
End Function

' Builds a single ad pod.
Function buildAdPod(adInfo as Object, currentTime as Integer) as Object
  print "building ad pod from ";adInfo;" " ; currentTime
  adPod = {}

  adPod["viewed"] = False
  adPod["renderSequence"] = "midroll"
  adPod["duration"] = adInfo.duration
  adPod["renderTime"] = currentTime
  adPod["backfilled"] = False
  adPod["ads"] = []
  adPod["ads"].push(buildAd(adInfo))
  return adPod
End Function

' Builds a single ad within a pod.
Function buildAd(adInfo as Object) as Object
  ad = {}

  ' Streams is a copy of the companion data.
  stream = {}
  stream["url"] = ""
  stream["mimetype"] = "application/json"

  ad["duration"] = adInfo.duration
  ad["streamFormat"] = getStreamFormat(adInfo)
  ad["adServer"] = adInfo.adSystem
  ad["adId"] = adInfo.adId
  ad["adTitle"] = adInfo.adTitle
  ad["creativeId"] = adInfo.adId
  ad["streams"] = []
  ad["streams"].push(stream)
  ad["tracking"] = []
  ad["companionAds"] = buildCompanions(adInfo)
  return ad
End Function

' Builds the RAF companion from the companion creative.
Function buildCompanions(adInfo as Object) as Object
  companions = []
  for Each vastCompanion in adInfo.companions
    ' Non json companions are not rendered by RAF.
    If vastCompanion.creativeType = "application/json"
      companion = {}
      companion["url"] = vastCompanion.url
      companion["width"] = vastCompanion.width
      companion["height"] = vastCompanion.height
      companion["mimeType"] = vastCompanion.creativeType
      companion["tracking"] = []
      companion["provider"] = vastCompanion.apiFramework
      companions.push(companion)
    End If
  End For
  return companions
End Function


' Returns the stream format needed by RAF.
Function getStreamFormat(vastAd as Object) as String
  ' It is possible that there could be unique api frameworks for each companion.
  For Each companion in vastAd.companions
    If companion.apiFramework <> Invalid And companion.apiFramework <> ""
      ' brightline_RSG is brightline stream format.
      If companion.apiFramework = "brightline_RSG"
        return "brightline"
      End If
      return companion.apiFramework
    End If
  End For
  return ""
End Function


' Formats and prints an entire Object along with sub objects.
' This can help debug what is sent into RAF and can be used.
Function logStructure(structure as Object, indent As String) as Void
  If type(structure) = "roArray"
    print indent + "["
     For Each val in structure
       If type(val) = "roArray" or type(val) = "roAssociativeArray"
         logStructure(val, indent + "  ")
       Else
         print indent + str(val)
       End If
     End For
     print indent + "]"
   Else If type(structure) = "roAssociativeArray"
     print indent + "{"
     For Each key in structure
       val = structure[key]
       If type(val) = "roArray" or type(val) = "roAssociativeArray"
         print indent + key + ": "
         logStructure(val, indent + "  ")
       Else
         keyStr = indent + key + ": "
         print keyStr; val
       End If
     End For
     print indent + "}"
   Else
     print "could not parse ";type(structure)
   End If
 End Function