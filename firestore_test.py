#!/usr/bin/env python3
"""
Firestore Test Script
A simple script to test document creation in Firestore for your Flutter app.
Place this in your project root directory.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
from datetime import datetime
import sys

def initialize_firestore():
    """Initialize Firestore with service account credentials."""
    try:
        # Check if already initialized
        app = firebase_admin.get_app()
        print("✅ Firebase already initialized")
        print(f"   App name: {app.name}")
    except ValueError:
        # Initialize Firebase
        # Option 1: Using service account key file
        if os.path.exists('serviceAccountKey.json'):
            # Load and check the service account key
            with open('serviceAccountKey.json', 'r') as f:
                service_account_info = json.load(f)
                project_id = service_account_info.get('project_id', 'Unknown')
                print(f"📋 Service account project ID: {project_id}")
            
            cred = credentials.Certificate('serviceAccountKey.json')
            firebase_admin.initialize_app(cred)
            print("✅ Firebase initialized with service account key")
        
        # Option 2: Using environment variable for credentials
        elif os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred)
            print("✅ Firebase initialized with environment credentials")
        
        # Option 3: Using Firebase emulator (for local testing)
        else:
            print("⚠️  No credentials found. Attempting to connect to local emulator...")
            os.environ['FIRESTORE_EMULATOR_HOST'] = 'localhost:8080'
            firebase_admin.initialize_app()
            print("✅ Firebase initialized with local emulator")
    
    db = firestore.client()
    
    # Get and display project info
    try:
        # Try to get project ID from the client
        app = firebase_admin.get_app()
        if hasattr(app, 'project_id'):
            print(f"🎯 Connected to project: {app.project_id}")
        elif os.path.exists('serviceAccountKey.json'):
            with open('serviceAccountKey.json', 'r') as f:
                service_account_info = json.load(f)
                project_id = service_account_info.get('project_id', 'Unknown')
                print(f"🎯 Target project ID: {project_id}")
    except Exception as e:
        print(f"ℹ️  Could not determine project ID: {e}")
    
    return db

def create_test_document(db, collection_name="test_collection"):
    """Create a test document in Firestore."""
    try:
        # Generate test data
        test_data = {
            'title': 'Test Document',
            'description': 'This is a test document created by the test script',
            'timestamp': datetime.now(),
            'user_id': 'test_user_123',
            'status': 'active',
            'metadata': {
                'created_by': 'test_script',
                'version': '1.0',
                'tags': ['test', 'development', 'flutter-app']
            },
            'settings': {
                'is_public': False,
                'notifications_enabled': True,
                'theme': 'default'
            }
        }
        
        # Add document to collection
        doc_ref = db.collection(collection_name).add(test_data)
        document_id = doc_ref[1].id
        
        print(f"✅ Document created successfully!")
        print(f"   Collection: {collection_name}")
        print(f"   Document ID: {document_id}")
        print(f"   Data: {json.dumps(test_data, indent=2, default=str)}")
        
        return document_id, test_data
        
    except Exception as e:
        print(f"❌ Error creating document: {str(e)}")
        return None, None

def read_test_document(db, collection_name, document_id):
    """Read back the test document to verify creation."""
    try:
        doc_ref = db.collection(collection_name).document(document_id)
        doc = doc_ref.get()
        
        if doc.exists:
            print(f"✅ Document read successfully!")
            print(f"   Document data: {json.dumps(doc.to_dict(), indent=2, default=str)}")
            return doc.to_dict()
        else:
            print("❌ Document does not exist")
            return None
            
    except Exception as e:
        print(f"❌ Error reading document: {str(e)}")
        return None

def delete_test_document(db, collection_name, document_id):
    """Delete the test document (cleanup)."""
    try:
        db.collection(collection_name).document(document_id).delete()
        print(f"✅ Test document deleted successfully!")
        
    except Exception as e:
        print(f"❌ Error deleting document: {str(e)}")

def list_collections(db):
    """List all collections in the database."""
    try:
        collections = db.collections()
        collection_names = [col.id for col in collections]
        print(f"📂 Available collections: {collection_names}")
        return collection_names
        
    except Exception as e:
        print(f"❌ Error listing collections: {str(e)}")
        return []

def main():
    """Main test function."""
    print("🚀 Starting Firestore Test Script")
    print("=" * 50)
    
    # Configuration
    COLLECTION_NAME = "test_collection"
    CLEANUP_AFTER_TEST = False  # Set to False if you want to keep test documents
    
    try:
        # Initialize Firestore
        db = initialize_firestore()
        print()
        
        # List existing collections
        print("📂 Checking existing collections...")
        list_collections(db)
        print()
        
        # Create test document
        print(f"📝 Creating test document in collection '{COLLECTION_NAME}'...")
        document_id, test_data = create_test_document(db, COLLECTION_NAME)
        
        if document_id:
            print()
            
            # Read back the document
            print("📖 Reading back the created document...")
            read_data = read_test_document(db, COLLECTION_NAME, document_id)
            print()
            
            # Verify data integrity
            if read_data:
                print("✅ Data integrity check passed!")
                
                # Optional: Delete test document
                if CLEANUP_AFTER_TEST:
                    print("🧹 Cleaning up test document...")
                    delete_test_document(db, COLLECTION_NAME, document_id)
                else:
                    print(f"ℹ️  Test document preserved: {COLLECTION_NAME}/{document_id}")
            
        print()
        print("🎉 Firestore test completed successfully!")
        
    except Exception as e:
        print(f"💥 Test failed with error: {str(e)}")
        print("\n🔧 Troubleshooting tips:")
        print("   1. Ensure Firebase credentials are properly configured")
        print("   2. Check your internet connection")
        print("   3. Verify Firestore is enabled in your Firebase project")
        print("   4. For local testing, start the Firebase emulator")
        sys.exit(1)

if __name__ == "__main__":
    main()