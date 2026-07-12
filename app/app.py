#!/usr/bin/env python3
"""
Moondream FastAPI Service
A lightweight wrapper around Moondream transformers implementation
"""

import inspect
import logging
import os
from typing import List, Dict, Any
from contextlib import asynccontextmanager

import moondream as md
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import io

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global model instance
model = None

class CaptionRequest(BaseModel):
    length: str = "normal"  # "short" or "normal"
    stream: bool = False

class QueryRequest(BaseModel):
    question: str
    stream: bool = False

class DetectRequest(BaseModel):
    object_name: str

class PointRequest(BaseModel):
    object_name: str

class CaptionResponse(BaseModel):
    caption: str

class QueryResponse(BaseModel):
    answer: str

class DetectResponse(BaseModel):
    objects: List[Dict[str, Any]]

class PointResponse(BaseModel):
    points: List[Dict[str, Any]]

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup"""
    global model
    # Photon takes a model name, not an HF repo id; accept MODEL_REPO_ID for
    # backward compatibility by stripping the org prefix.
    model_name = os.getenv("MODEL_NAME") or os.getenv(
        "MODEL_REPO_ID", "moondream/moondream3.1-9B-A2B"
    ).split("/")[-1]
    api_key = os.getenv("MOONDREAM_API_KEY")
    try:
        logger.info("Loading Moondream model...")
        logger.info("Model: %s (local via Photon)", model_name)

        load_kwargs = {"local": True, "model": model_name}
        if api_key:
            # Only required for finetunes; base models run without a key
            load_kwargs["api_key"] = api_key

        model = md.vl(**load_kwargs)
        logger.info("Model loaded successfully")
        yield
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise
    finally:
        logger.info("Shutting down...")

app = FastAPI(
    title="Moondream API",
    description="FastAPI wrapper for Moondream vision-language model",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def load_image_from_bytes(image_bytes: bytes) -> Image.Image:
    """Load PIL Image from bytes"""
    try:
        return Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image format: {e}")


def invoke_model(skill_name: str, *args, **kwargs):
    """Call a model skill, filtering kwargs based on the available signature."""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    skill = getattr(model, skill_name, None)
    if not callable(skill):
        raise HTTPException(status_code=500, detail=f"Model does not support '{skill_name}'")

    try:
        signature = inspect.signature(skill)
        accepts_kwargs = any(param.kind == inspect.Parameter.VAR_KEYWORD for param in signature.parameters.values())
        if not accepts_kwargs:
            filtered_kwargs = {k: v for k, v in kwargs.items() if k in signature.parameters}
        else:
            filtered_kwargs = kwargs
    except (TypeError, ValueError):
        filtered_kwargs = kwargs

    return skill(*args, **filtered_kwargs)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "model_loaded": model is not None}

@app.get("/v1")
async def root():
    """Root endpoint for compatibility"""
    return {"message": "Moondream API", "version": "1.0.0"}

@app.post("/v1/caption", response_model=CaptionResponse)
async def caption_image(
    image: UploadFile = File(...),
    length: str = Form("normal"),
    stream: bool = Form(False),
    reasoning: bool = Form(False)
):
    """Generate caption for an image"""
    if length not in ["short", "normal"]:
        raise HTTPException(status_code=400, detail="Length must be 'short' or 'normal'")
    
    try:
        image_bytes = await image.read()
        pil_image = load_image_from_bytes(image_bytes)
        
        result = invoke_model(
            "caption",
            pil_image,
            length=length,
            stream=stream,
            reasoning=reasoning,
        )
        return CaptionResponse(caption=result["caption"])
    
    except Exception as e:
        logger.error(f"Caption error: {e}")
        raise HTTPException(status_code=500, detail=f"Caption generation failed: {e}")

@app.post("/v1/query", response_model=QueryResponse)
async def query_image(
    image: UploadFile = File(...),
    question: str = Form(...),
    stream: bool = Form(False),
    reasoning: bool = Form(False)
):
    """Answer a question about an image"""
    if not question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty")
    
    try:
        image_bytes = await image.read()
        pil_image = load_image_from_bytes(image_bytes)
        
        result = invoke_model(
            "query",
            pil_image,
            question,
            stream=stream,
            reasoning=reasoning,
        )
        return QueryResponse(answer=result["answer"])
    
    except Exception as e:
        logger.error(f"Query error: {e}")
        raise HTTPException(status_code=500, detail=f"Query failed: {e}")

@app.post("/v1/detect", response_model=DetectResponse)
async def detect_objects(
    image: UploadFile = File(...),
    object_name: str = Form(...),
    reasoning: bool = Form(False)
):
    """Detect objects in an image"""
    if not object_name.strip():
        raise HTTPException(status_code=400, detail="Object name cannot be empty")
    
    try:
        image_bytes = await image.read()
        pil_image = load_image_from_bytes(image_bytes)
        
        result = invoke_model(
            "detect",
            pil_image,
            object_name,
            reasoning=reasoning,
        )
        return DetectResponse(objects=result["objects"])
    
    except Exception as e:
        logger.error(f"Detection error: {e}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {e}")

@app.post("/v1/point", response_model=PointResponse)
async def point_objects(
    image: UploadFile = File(...),
    object_name: str = Form(...),
    reasoning: bool = Form(False)
):
    """Locate objects in an image"""
    if not object_name.strip():
        raise HTTPException(status_code=400, detail="Object name cannot be empty")
    
    try:
        image_bytes = await image.read()
        pil_image = load_image_from_bytes(image_bytes)
        
        result = invoke_model(
            "point",
            pil_image,
            object_name,
            reasoning=reasoning,
        )
        return PointResponse(points=result["points"])
    
    except Exception as e:
        logger.error(f"Pointing error: {e}")
        raise HTTPException(status_code=500, detail=f"Pointing failed: {e}")

if __name__ == "__main__":
    import uvicorn
    # Enable hot reloading in development (disable in production)
    reload = os.getenv("RELOAD", "true").lower() == "true"
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8080)),
        reload=reload
    )
