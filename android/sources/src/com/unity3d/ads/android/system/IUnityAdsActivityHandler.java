package com.unity3d.ads.android.system;

import android.app.Activity;

public interface IUnityAdsActivityHandler {
	public void init(Activity activity);
	public void changeActivity(Activity activity);
	public Activity getCurrentActivity();
}