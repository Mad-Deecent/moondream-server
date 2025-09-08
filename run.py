#!/usr/bin/env python3
"""
Convenience script to run the Moondream FastAPI application
"""

import subprocess
import sys
import os

def main():
    """Run the FastAPI application"""
    # Change to the app directory
    app_dir = os.path.join(os.path.dirname(__file__), 'app')
    
    # Run the app module
    cmd = [sys.executable, '-m', 'app.app']
    
    print("Starting Moondream FastAPI service...")
    print(f"Command: {' '.join(cmd)}")
    print("Press Ctrl+C to stop")
    
    try:
        subprocess.run(cmd, cwd=os.path.dirname(__file__))
    except KeyboardInterrupt:
        print("\nShutting down...")

if __name__ == "__main__":
    main()
