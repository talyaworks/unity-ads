package com.unity3d.ads.android.system;

import java.lang.ref.WeakReference;

import com.unity3d.ads.android.UnityAdsDeviceLog;

import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Application;
import android.os.Build;
import android.os.Bundle;

// Android activity tracking for Android 4.0 and later, implemented with application lifecycle callbacks

@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
public class UnityAdsActivityHandlerApiLevel14 implements IUnityAdsActivityHandler, Application.ActivityLifecycleCallbacks {
	WeakReference<Activity> currentActivity = null;

	@Override
	public void init(Activity activity) {
		if(activity != null) {
			currentActivity = new WeakReference<Activity>(activity);
			activity.getApplication().registerActivityLifecycleCallbacks(this);
		} else {
			UnityAdsDeviceLog.error("Activity handling initialized with null activity");
		}
	}

	@Override
	public void changeActivity(Activity activity) {
		// changeActivity calls are ignored, use only activity lifecycle callbacks
		return;
	}

	@Override
	public Activity getCurrentActivity() {
		return currentActivity.get();
	}

	@Override
	public void onActivityCreated(Activity activity, Bundle savedInstanceState) { }

	@Override
	public void onActivityStarted(Activity activity) { }

	@Override
	public void onActivityResumed(Activity activity) {
		currentActivity = new WeakReference<Activity>(activity);
	}

	@Override
	public void onActivityPaused(Activity activity) { }

	@Override
	public void onActivityStopped(Activity activity) { }

	@Override
	public void onActivitySaveInstanceState(Activity activity, Bundle outState) { }

	@Override
	public void onActivityDestroyed(Activity activity) { }
}