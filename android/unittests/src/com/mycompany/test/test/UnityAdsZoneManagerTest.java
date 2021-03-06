package com.mycompany.test.test;

import java.util.Arrays;
import java.util.HashMap;

import org.json.JSONArray;
import org.json.JSONObject;

import com.unity3d.ads.android.zone.UnityAdsZone;
import com.unity3d.ads.android.zone.UnityAdsZoneManager;
import com.mycompany.test.UnityAdsTestStartActivity;

import android.test.ActivityInstrumentationTestCase2;

public class UnityAdsZoneManagerTest extends ActivityInstrumentationTestCase2<UnityAdsTestStartActivity> {

	private JSONObject nonIncentivizedZone, incentivizedZone, rewardItem1;
	private UnityAdsZoneManager zoneManager;
	
	public UnityAdsZoneManagerTest() {
		super(UnityAdsTestStartActivity.class);
	}
	
	@Override
	@SuppressWarnings("serial")
	public void setUp() throws Exception {
		super.setUp();
		
		nonIncentivizedZone = new JSONObject(new HashMap<String, Object>(){{
			put("id", "testZoneId1");
			put("name", "testZoneName1");
			put("incentivised", false);
			put("default", true);
		}});
		
		rewardItem1 = new JSONObject(new HashMap<String, Object>(){{
			put("key", "itemKey1");
			put("name", "itemName1");
			put("picture", "http://invalid.url.com");
		}});
		
		incentivizedZone = new JSONObject(new HashMap<String, Object>(){{
			put("id", "testZoneId2");
			put("name", "testZoneName2");
			put("incentivised", true);
			put("default", false);
			put("defaultRewardItem", rewardItem1);
			put("rewardItems", new JSONArray(Arrays.asList(
				rewardItem1
			)));
		}});
		
		zoneManager = null;
	}
	
	public void testZoneManagerNonIncentivizedZone() {		
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			nonIncentivizedZone
		)));
		
		assertTrue(zoneManager.zoneCount() == 1);
		
		UnityAdsZone currentZone = zoneManager.getCurrentZone();
		
		assertTrue(currentZone != null);
		assertTrue(currentZone.getZoneId().equals("testZoneId1"));
		assertTrue(currentZone.isDefault());
		assertTrue(!currentZone.isIncentivized());
	}
	
	public void testZoneManagerIncentivizedZone() {
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			nonIncentivizedZone,
			incentivizedZone
		)));
		
		assertTrue(zoneManager.zoneCount() == 2);
		assertTrue(zoneManager.setCurrentZone("testZoneId2"));
		
		UnityAdsZone currentZone = zoneManager.getCurrentZone();
		
		assertTrue(currentZone != null);
		assertTrue(currentZone.getZoneId().equals("testZoneId2"));
		assertFalse(currentZone.isDefault());
		assertTrue(currentZone.isIncentivized());
	}
	
	public void testZoneManagerMultipleZones() {
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			nonIncentivizedZone,
			incentivizedZone
		)));
		
		assertTrue(zoneManager.zoneCount() == 2);
		
		UnityAdsZone currentZone = zoneManager.getCurrentZone();
		
		assertTrue(currentZone.getZoneId().equals("testZoneId1"));
		assertTrue(zoneManager.getZone("testZoneId2") != null);
	}
	
	public void testZoneManagerDuplicateZones() {
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			nonIncentivizedZone,
			incentivizedZone,
			incentivizedZone
		)));
		
		assertTrue(zoneManager.zoneCount() == 2);
	}
	
	public void testZoneManagerClearZones() {
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			nonIncentivizedZone,
			incentivizedZone
		)));
		
		assertTrue(zoneManager.zoneCount() == 2);
		zoneManager.clear();
		assertTrue(zoneManager.zoneCount() == 0);
	}
	
	public void testZoneManagerSetInvalidZone() {
		zoneManager = new UnityAdsZoneManager(new JSONArray(Arrays.asList(
			incentivizedZone,
			nonIncentivizedZone
		)));
		
		assertFalse(zoneManager.setCurrentZone("invalidZoneId"));
		assertTrue(zoneManager.getCurrentZone() == null);
		
	}
}
