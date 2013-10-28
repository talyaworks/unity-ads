package com.unity3d.ads.android.webapp;

import org.json.JSONObject;

import android.content.Intent;
import android.net.Uri;
import android.webkit.JavascriptInterface;

import com.unity3d.ads.android.UnityAdsUtils;
import com.unity3d.ads.android.properties.UnityAdsConstants;
import com.unity3d.ads.android.properties.UnityAdsProperties;

public class UnityAdsWebBridge {
	private enum UnityAdsWebEvent { PlayVideo, PauseVideo, CloseView, InitComplete, PlayStore, NavigateTo;
		@Override
		public String toString () {
			String retVal = null;
			switch (this) {
				case PlayVideo:
					retVal = UnityAdsConstants.UNITY_ADS_WEBVIEW_API_PLAYVIDEO;
					break;
				case PauseVideo:
					retVal = "pauseVideo";
					break;
				case CloseView:
					retVal = UnityAdsConstants.UNITY_ADS_WEBVIEW_API_CLOSE;
					break;
				case InitComplete:
					retVal = UnityAdsConstants.UNITY_ADS_WEBVIEW_API_INITCOMPLETE;
					break;
				case PlayStore:
					retVal = UnityAdsConstants.UNITY_ADS_WEBVIEW_API_PLAYSTORE;
					break;
				case NavigateTo:
					retVal = UnityAdsConstants.UNITY_ADS_WEBVIEW_API_NAVIGATETO;
					break;
			}
			return retVal;
		}
	}
	
	private IUnityAdsWebBridgeListener _listener = null;
	
	private UnityAdsWebEvent getEventType (String event) {
		for (UnityAdsWebEvent evt : UnityAdsWebEvent.values()) {
			if (evt.toString().equals(event))
				return evt;
		}
		
		return null;
	}
	
	public UnityAdsWebBridge (IUnityAdsWebBridgeListener listener) {
		_listener = listener;
	}
	
	@JavascriptInterface
	public boolean handleWebEvent (String type, String data) {
		UnityAdsUtils.Log("handleWebEvent: "+ type + ", " + data, this);

		if (_listener == null || data == null) return false;
		
		JSONObject jsonData = null;
		JSONObject parameters = null;
		String event = type;
		
		try {
			jsonData = new JSONObject(data);
			parameters = jsonData.getJSONObject("data");
		}
		catch (Exception e) {
			UnityAdsUtils.Log("Error while parsing parameters: " + e.getMessage(), this);
		}
		
		if (jsonData == null || event == null) return false;
		
		UnityAdsWebEvent eventType = getEventType(event);
		
		if (eventType == null) return false;
		
		switch (eventType) {
			case PlayVideo:
				_listener.onPlayVideo(parameters);
				break;
			case PauseVideo:
				_listener.onPauseVideo(parameters);
				break;
			case CloseView:
				_listener.onCloseAdsView(parameters);
				break;
			case InitComplete:
				_listener.onWebAppInitComplete(parameters);
				break;
			case PlayStore:
				_listener.onOpenPlayStore(parameters);
				break;
			case NavigateTo:
				if (parameters.has(UnityAdsConstants.UNITY_ADS_WEBVIEW_EVENTDATA_CLICKURL_KEY)) {
					String clickUrl = null;
					
					try {
						clickUrl = parameters.getString(UnityAdsConstants.UNITY_ADS_WEBVIEW_EVENTDATA_CLICKURL_KEY);
					}
					catch (Exception e) {
						UnityAdsUtils.Log("Error fetching clickUrl", this);
						return false;
					}
					
					if (clickUrl != null) {
						try {
							Intent i = new Intent(Intent.ACTION_VIEW);
							i.setData(Uri.parse(clickUrl));
							UnityAdsProperties.getCurrentActivity().startActivity(i);
						}
						catch (Exception e) {
							UnityAdsUtils.Log("Could not start activity for opening URL: " + clickUrl + ", maybe malformed URL?", this);
						}
					}
				}
				
				break;
		}
		
		return true;
	}
}
