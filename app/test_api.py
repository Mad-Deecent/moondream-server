#!/usr/bin/env python3
"""
Test script for Moondream FastAPI service
"""

import requests
import json
from PIL import Image
import io
import time

# Test configuration
BASE_URL = "http://localhost:8080"
TEST_IMAGE_URL = "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=400"  # Dog image

def create_test_image():
    """Download and prepare the test image"""
    try:
        # Download the test image from URL
        response = requests.get(TEST_IMAGE_URL)
        response.raise_for_status()
        
        # Open the image and convert to bytes
        img = Image.open(io.BytesIO(response.content))
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        return img_bytes
    except Exception as e:
        print(f"Failed to download test image: {e}")
        # Fallback to a simple colored rectangle
        img = Image.new('RGB', (200, 200), color='red')
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        return img_bytes

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_caption():
    """Test caption endpoint"""
    print("\nTesting caption endpoint...")
    try:
        img_bytes = create_test_image()
        files = {"image": ("test.jpg", img_bytes, "image/jpeg")}
        data = {"length": "short"}
        
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/v1/caption", files=files, data=data)
        end_time = time.time()
        
        print(f"Status: {response.status_code}")
        print(f"Inference time: {end_time - start_time:.2f}s")
        if response.status_code == 200:
            print(f"Caption: {response.json()['caption']}")
        else:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Caption test failed: {e}")
        return False

def test_query():
    """Test query endpoint"""
    print("\nTesting query endpoint...")
    try:
        img_bytes = create_test_image()
        files = {"image": ("test.jpg", img_bytes, "image/jpeg")}
        data = {"question": "This is an animal named Gerty. Describe Gerty and what it might be feeling."}
        
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/v1/query", files=files, data=data)
        end_time = time.time()
        
        print(f"Status: {response.status_code}")
        print(f"Inference time: {end_time - start_time:.2f}s")
        if response.status_code == 200:
            print(f"Answer: {response.json()['answer']}")
        else:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Query test failed: {e}")
        return False

def test_detect():
    """Test detect endpoint"""
    print("\nTesting detect endpoint...")
    try:
        img_bytes = create_test_image()
        files = {"image": ("test.jpg", img_bytes, "image/jpeg")}
        data = {"object_name": "dog"}
        
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/v1/detect", files=files, data=data)
        end_time = time.time()
        
        print(f"Status: {response.status_code}")
        print(f"Inference time: {end_time - start_time:.2f}s")
        if response.status_code == 200:
            print(f"Objects: {response.json()['objects']}")
        else:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Detect test failed: {e}")
        return False

def test_point():
    """Test point endpoint"""
    print("\nTesting point endpoint...")
    try:
        img_bytes = create_test_image()
        files = {"image": ("test.jpg", img_bytes, "image/jpeg")}
        data = {"object_name": "rectangle"}
        
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/v1/point", files=files, data=data)
        end_time = time.time()
        
        print(f"Status: {response.status_code}")
        print(f"Inference time: {end_time - start_time:.2f}s")
        if response.status_code == 200:
            print(f"Points: {response.json()['points']}")
        else:
            print(f"Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Point test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("Moondream FastAPI Test Suite")
    print("=" * 40)
    
    tests = [
        ("Health Check", test_health),
        ("Caption", test_caption),
        ("Query", test_query),
        ("Detect", test_detect),
        ("Point", test_point),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"{test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    print("\n" + "=" * 40)
    print("Test Results:")
    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"{test_name}: {status}")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    print(f"\nOverall: {passed}/{total} tests passed")

if __name__ == "__main__":
    main()


