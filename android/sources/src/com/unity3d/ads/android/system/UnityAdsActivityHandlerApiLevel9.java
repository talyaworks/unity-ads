package com.unity3d.ads.android.system;

import java.lang.ref.WeakReference;

import android.app.Activity;

// Android activity tracking for Android 2.x and 3.x, implemented with manual changeActivity calls

public class UnityAdsActivityHandlerApiLevel9 implements IUnityAdsActivityHandler {
	WeakReference<Activity> currentActivity = null;

	@Override
	public void init(Activity activity) {
		if(activity != null) {
			currentActivity = new WeakReference<Activity>(activity);
		}
	}

	@Override
	public void changeActivity(Activity activity) {
		if(activity != null && activity != currentActivity.get()) {
			currentActivity = new WeakReference<Activity>(activity);
		}
	}

	@Override
	public Activity getCurrentActivity() {
		return currentActivity.get();
	}
}