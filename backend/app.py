import os
import io
import numpy as np
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

# Initialize FastAPI app
app = FastAPI(
    title="Cabbage Doctor AI Model API",
    description="FastAPI service for cabbage disease classification using TFLite Float32 model",
    version="1.0.0"
)

# Enable CORS for Flutter Web or external clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Try importing tflite_runtime first, fallback to tensorflow
try:
    import tflite_runtime.interpreter as tflite
except ImportError:
    try:
        import tensorflow.lite as tflite
    except ImportError:
        tflite = None

# Path configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "cabbage_float32.tflite")
LABELS_PATH = os.path.join(BASE_DIR, "cabbage_labels.txt")

# Load labels
if os.path.exists(LABELS_PATH):
    with open(LABELS_PATH, "r") as f:
        LABELS = [line.strip() for line in f if line.strip()]
else:
    LABELS = [
        "Alternaria Leaf Spot",
        "Bacterial Soft Rot",
        "Black Rot",
        "Cabbage Aphid Infestation",
        "Downy Mildew",
        "Healthy",
        "Not a Cabbage Leaf",
        "Club Root",
        "Ring Spot"
    ]

# Initialize TFLite Interpreter
interpreter = None
input_details = None
output_details = None

def load_interpreter():
    global interpreter, input_details, output_details
    if interpreter is None:
        if tflite is None:
            raise RuntimeError("Neither tflite_runtime nor tensorflow is installed on this environment.")
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model file not found at {MODEL_PATH}")
        interpreter = tflite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

@app.on_event("startup")
def startup_event():
    try:
        load_interpreter()
    except Exception as e:
        print(f"Warning: Could not load interpreter on startup: {e}")

@app.get("/")
def root():
    return {
        "status": "ok",
        "service": "Cabbage Doctor AI Model API",
        "labels": LABELS,
        "model_loaded": interpreter is not None
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # Ensure interpreter is loaded
        load_interpreter()

        # Load image bytes
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        # Model specification: Input shape 299x299 NHWC RGB
        input_shape = input_details[0]["shape"] if input_details else [1, 299, 299, 3]
        target_height = input_shape[1]
        target_width = input_shape[2]

        image = image.resize((target_width, target_height), Image.Resampling.BILINEAR)

        # Convert image to Float32 array (0.0 - 255.0 floats, normalization baked into model)
        input_data = np.array(image, dtype=np.float32)
        input_data = np.expand_dims(input_data, axis=0)

        # Run inference
        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()

        output_data = interpreter.get_tensor(output_details[0]["index"])
        probabilities = output_data[0].tolist()

        # Calculate max prediction
        max_idx = int(np.argmax(probabilities))
        max_score = float(probabilities[max_idx])
        predicted_label = LABELS[max_idx] if max_idx < len(LABELS) else "Unidentified"

        # Model spec confidence threshold = 0.891
        confidence_threshold = 0.891
        is_leaf = (max_score >= confidence_threshold) and (predicted_label not in ["Not a Cabbage Leaf", "Not cabbage"])

        all_scores = {LABELS[i]: round(float(probabilities[i]), 4) for i in range(min(len(LABELS), len(probabilities)))}

        return {
            "disease": predicted_label if is_leaf else "Not a Cabbage Leaf",
            "label": predicted_label,
            "confidence": round(max_score, 4),
            "is_leaf": is_leaf,
            "all_scores": all_scores
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
