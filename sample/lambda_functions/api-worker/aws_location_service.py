import os
import math
import boto3
from botocore.exceptions import ClientError
import time
import pickle
import json
import pandas as pd
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# ==============================
# CONFIGURATION
# ==============================
REGION = os.environ['REGION']
PLACE_INDEX_NAME = os.environ['PLACE_INDEX_NAME']
DATASOURCE = os.environ['DATASOURCE']

client = boto3.client("location", region_name=REGION)

dict_categories = {'Airport': [{'category': 'airport_cargo', 'dieukien': 'THUANLOI'},
  {'category': 'airport_terminal', 'dieukien': 'THUANLOI'},
  {'category': 'airport', 'dieukien': 'THUANLOI'}],
 'ATM': [{'category': 'atm', 'dieukien': 'THUANLOI'}],
 'Sports Complex-Stadium': [{'category': 'badminton', 'dieukien': 'THUANLOI'},
  {'category': 'golf_course', 'dieukien': 'THUANLOI'},
  {'category': 'indoor_sports', 'dieukien': 'THUANLOI'},
  {'category': 'soccer_club', 'dieukien': 'THUANLOI'},
  {'category': 'swimming_pool', 'dieukien': 'THUANLOI'},
  {'category': 'tennis_court', 'dieukien': 'THUANLOI'},
  {'category': 'sports_complex-stadium', 'dieukien': 'THUANLOI'}],
 'Bank': [{'category': 'bank', 'dieukien': 'THUANLOI'}],
 'F&B': [{'category': 'banquet_hall', 'dieukien': 'THUANLOI'},
  {'category': 'bar_or_pub', 'dieukien': 'THUANLOI'},
  {'category': 'bistro', 'dieukien': 'THUANLOI'},
  {'category': 'cafeteria', 'dieukien': 'THUANLOI'},
  {'category': 'casual_dining', 'dieukien': 'THUANLOI'},
  {'category': 'coffee_shop', 'dieukien': 'THUANLOI'},
  {'category': 'coffee-tea', 'dieukien': 'THUANLOI'},
  {'category': 'deli', 'dieukien': 'THUANLOI'},
  {'category': 'restaurant', 'dieukien': 'THUANLOI'},
  {'category': 'tea_house', 'dieukien': 'THUANLOI'}],
 'Giải trí, sức khỏe': [{'category': 'barber', 'dieukien': 'THUANLOI'},
  {'category': 'campground', 'dieukien': 'THUANLOI'},
  {'category': 'campsite', 'dieukien': 'THUANLOI'},
  {'category': 'cinema', 'dieukien': 'THUANLOI'},
  {'category': 'hair_and_beauty', 'dieukien': 'THUANLOI'},
  {'category': 'karaoke', 'dieukien': 'THUANLOI'},
  {'category': 'fitness-health_club', 'dieukien': 'THUANLOI'}],
 'Bãi biển': [{'category': 'beach', 'dieukien': 'THUANLOI'}],
 'Hotel': [{'category': 'bed_and_breakfast', 'dieukien': 'THUANLOI'},
  {'category': 'guest_house', 'dieukien': 'THUANLOI'},
  {'category': 'hotel', 'dieukien': 'THUANLOI'}],
 'bookstore': [{'category': 'bookstore', 'dieukien': 'THUANLOI'}],
 'bus_station': [{'category': 'bus_station', 'dieukien': 'THUANLOI'},
  {'category': 'bus_rapid_transit', 'dieukien': 'THUANLOI'},
  {'category': 'bus_station', 'dieukien': 'THUANLOI'},
  {'category': 'bus_stop', 'dieukien': 'THUANLOI'}],
 'Cemetery': [{'category': 'cemetery', 'dieukien': 'BATLOI'},
  {'category': 'crematorium', 'dieukien': 'BATLOI'}],
 'Cửa hàng tiện ích/TT bách hóa': [{'category': 'convenience_store',
   'dieukien': 'THUANLOI'},
  {'category': 'department_store', 'dieukien': 'THUANLOI'},
  {'category': 'grocery', 'dieukien': 'THUANLOI'},
  {'category': 'variety_store', 'dieukien': 'THUANLOI'}],
 'Hospital': [{'category': 'dentist-dental_office', 'dieukien': 'THUANLOI'},
  {'category': 'hospital', 'dieukien': 'THUANLOI'}],
 'School': [{'category': 'education_facility', 'dieukien': 'THUANLOI'},
  {'category': 'school', 'dieukien': 'THUANLOI'}],
 'Energy': [{'category': 'fueling_station', 'dieukien': 'THUANLOI'},
  {'category': 'petrol-gasoline_station', 'dieukien': 'THUANLOI'},
  {'category': 'electrical', 'dieukien': 'THUANLOI'},
  {'category': 'petrol-gasoline_station', 'dieukien': 'THUANLOI'},
  {'category': 'ev_charging_station', 'dieukien': 'THUANLOI'}],
 'Funeral Director': [{'category': 'funeral_director', 'dieukien': 'BATLOI'}],
 'Furniture Store': [{'category': 'furniture_store', 'dieukien': 'THUANLOI'}],
 'Thư viện': [{'category': 'library', 'dieukien': 'THUANLOI'}],
 'parking': [{'category': 'parking', 'dieukien': 'THUANLOI'}],
 'Drugstore': [{'category': 'pharmacy', 'dieukien': 'THUANLOI'},
  {'category': 'drugstore', 'dieukien': 'THUANLOI'},
  {'category': 'drugstore_or_pharmacy', 'dieukien': 'THUANLOI'}],
 'Public Administration': [{'category': 'police_station',
   'dieukien': 'THUANLOI'},
  {'category': 'military_base', 'dieukien': 'THUANLOI'},
  {'category': 'public_administration', 'dieukien': 'THUANLOI'},
  {'category': 'police_box', 'dieukien': 'THUANLOI'},
  {'category': 'police_services-security', 'dieukien': 'THUANLOI'},
  {'category': 'police_station', 'dieukien': 'THUANLOI'},
  {'category': 'courthouse', 'dieukien': 'THUANLOI'}],
 'Cơ sở tôn giáo tín ngưỡng': [{'category': 'religious_place',
   'dieukien': 'BATLOI'},
  {'category': 'church', 'dieukien': 'BATLOI'},
  {'category': 'pagoda', 'dieukien': 'BATLOI'}],
 'Supermaket': [{'category': 'shopping_mall', 'dieukien': 'THUANLOI'},
  {'category': 'supermarket', 'dieukien': 'THUANLOI'}],
 'train_station': [{'category': 'train_station', 'dieukien': 'THUANLOI'},
  {'category': 'commuter_rail_station', 'dieukien': 'THUANLOI'},
  {'category': 'commuter_train', 'dieukien': 'THUANLOI'},
  {'category': 'train_station', 'dieukien': 'THUANLOI'}],
 'zoo': [{'category': 'zoo', 'dieukien': 'THUANLOI'}],
 'Cảng': [{'category': 'bay-harbor', 'dieukien': 'THUANLOI'},
  {'category': 'seaport-harbour', 'dieukien': 'THUANLOI'}],
 'Park': [{'category': 'amusement_park', 'dieukien': 'THUANLOI'},
  {'category': 'park-recreation_area', 'dieukien': 'THUANLOI'},
  {'category': 'amusement_park', 'dieukien': 'THUANLOI'},
  {'category': 'animal_park', 'dieukien': 'THUANLOI'},
  {'category': 'bike_park', 'dieukien': 'THUANLOI'},
  {'category': 'holiday_park', 'dieukien': 'THUANLOI'},
  {'category': 'park-recreation_area', 'dieukien': 'THUANLOI'},
  {'category': 'water_park', 'dieukien': 'THUANLOI'},
  {'category': 'wild_animal_park', 'dieukien': 'THUANLOI'}],
 'Recreation': [{'category': 'entertainment_and_recreation',
   'dieukien': 'THUANLOI'},
  {'category': 'live_entertainment-music', 'dieukien': 'THUANLOI'},
  {'category': 'nightlife-entertainment', 'dieukien': 'THUANLOI'},
  {'category': 'outdoor-recreation', 'dieukien': 'THUANLOI'},
  {'category': 'recreation_center', 'dieukien': 'THUANLOI'}],
 'Bãi rác': [{'category': 'recycling_center', 'dieukien': 'BATLOI'},
  {'category': 'waste_and_sanitary', 'dieukien': 'BATLOI'}],
 'Tàu điện ngầm': [{'category': 'underground_train-subway',
   'dieukien': 'THUANLOI'}],
 'Post Office': [{'category': 'post_office', 'dieukien': 'THUANLOI'}]}

def ensure_place_index(name):
    """Ensure a place index exists; create if not."""
    try:
        indexes = client.list_place_indexes()["Entries"]
        if not any(idx["IndexName"] == name for idx in indexes):
            print(f"Creating Place Index '{name}' ...")
            client.create_place_index(
                IndexName=name,
                DataSource=DATASOURCE,
                PricingPlan="RequestBasedUsage",
                Description="Auto-created place index for geocoding and POI search"
            )
            print(f"Place Index '{name}' created successfully!")
        else:
            print(f"Place Index '{name}' already exists.")
    except ClientError as e:
        print("Error creating place index:", e)

def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculate distance in km between two coordinates."""
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    return 2 * R * math.asin(math.sqrt(a))

# ==============================
# NEW: SEARCH FOR POI NEARBY
# ==============================
def search_poi(SOTOTRINH, keywords, lat, lon, radius_km, max_results):
    """Search for POIs (restaurants, schools, parks, etc.) around a given location."""
    pois = []
    for group, categories in keywords.items():
        # print(group, categories)
        query = " ".join(categories)
        # print(query)
        try:
            response = client.search_place_index_for_text(
                IndexName=PLACE_INDEX_NAME,
                Text=query,
                BiasPosition=[lon, lat],  # Center the search here
                MaxResults=max_results,
                FilterCountries=["VNM"],
            )

            # print(f"\nFound {len(response['Results'])} '{keyword}' near ({lat}, {lon}):\n")
            # print(response['Results'])
            for i, r in enumerate(response["Results"], 1):
                place = r["Place"]
                label = place.get("Label", "Unknown")
                coords = place["Geometry"]["Point"]
                # dist = r['Distance'] / 1000
                dist = haversine_distance(lat, lon, coords[1], coords[0])
                if dist <= radius_km:
                    # print(f" {i}. {label} → 🧭 {coords} | 📏 {dist:.2f} km")
                    pois.append(
                        {
                            "sototrinh": SOTOTRINH,
                            "group": group,
                            "category": query,
                            "label": label,
                            "lat": coords[1],
                            "lon": coords[0],
                            "distance": round(dist, 2),
                        }
                    )

        except Exception as e:
            print("POI search failed:", e)

    return pois


def search_one_group(group, categories, lat, lon, radius_km, max_results):
    pois = []

    # tách category list và mapping DIEUKIEN
    category_ids = [c["category"] for c in categories]
    dieukien_map = {c["category"]: c["dieukien"] for c in categories}

    query = " ".join(category_ids)


    try:
        response = client.search_place_index_for_text(
            IndexName=PLACE_INDEX_NAME,
            Text=query,
            BiasPosition=[lon, lat],
            MaxResults=max_results,
            FilterCountries=["VNM"],
        )

        for r in response["Results"]:
            place = r["Place"]
            label = place.get("Label", "Unknown")
            coords = place["Geometry"]["Point"]

            dist = haversine_distance(lat, lon, coords[1], coords[0])
            if dist <= radius_km:
                matched_category = None
                for cat in category_ids:
                    matched_category = cat
                        
                pois.append(
                    {
                        "group": group,
                        "category": query,
                        "dieukien": dieukien_map.get(matched_category),
                        "label": label,
                        "lat": coords[1],
                        "lon": coords[0],
                        "distance": round(dist, 2),
                        
                    }
                )

    except Exception as e:
        print(f"POI search failed for group {group}:", e)

    return pois

def search_poi_parallel(lat, lon, keywords = dict_categories, radius_km=5, max_results=50, max_workers=10):
    all_pois = []

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [
            executor.submit(
                search_one_group,
                group,
                categories,
                lat,
                lon,
                radius_km,
                max_results,
            )
            for group, categories in keywords.items()
        ]

        for future in as_completed(futures):
            result = future.result()
            if result:
                all_pois.extend(result)

    return all_pois

def compute_poi_features(lat, long):

    all_pois = search_poi_parallel(lat, long)
    df = pd.DataFrame(all_pois)

    # Bucket distance → km (1–5)
    bins = [0, 1, 2, 3, 4, 5]
    labels = [1, 2, 3, 4, 5]

    df["km"] = pd.cut(
        df["distance"],
        bins=bins,
        labels=labels,
        include_lowest=True
    )

    # features
    result = {}

    for km in range(1, 6):
        subset = df[df["km"] <= km]

        label_counts = (
            subset
            .groupby("dieukien")["label"]
            .nunique()
        )

        for cond in ["THUANLOI", "BATLOI"]:
            result[f"AWS_LOCATION__NUMBER_{cond}_WITHIN_{km}KM"] = (
                label_counts.get(cond, None)
            )

    for km in range(1, 6):
        subset = df[df["km"] <= km]
    
        group_counts = (
            subset
            .groupby("dieukien")["group"]
            .nunique()
        )

        for cond in ["THUANLOI", "BATLOI"]:
            result[f"AWS_LOCATION__NUMBER_LOAI_{cond}_WITHIN_{km}KM"] = (
                group_counts.get(cond, None)
            )

    return result
