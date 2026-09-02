# Cabbage Doctor AI - Render Backend Service

FastAPI Python web service to host and run inference for `cabbage_float32.tflite` model on Render.

## Files Included
- `app.py`: FastAPI server with `/predict` endpoint, image resizing (299x299 RGB), and TFLite model inference.
- `cabbage_float32.tflite`: 85MB Float32 TFLite model file.
- `cabbage_labels.txt`: 9 classification disease labels.
- `requirements.txt`: Python dependencies (`fastapi`, `uvicorn`, `tensorflow-cpu`, `pillow`, `numpy`).
- `Dockerfile`: Docker build configuration for Render container deployment.

---

## Local Testing

1. Create a virtual environment and install dependencies:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. Start local server:
   ```bash
   uvicorn app:app --reload --port 8000
   ```

3. Test Health Check:
   Open browser at `http://localhost:8000/` or `http://localhost:8000/health`.

---

## Deployment to Render.com

1. Push your repository to GitHub.
2. Go to [Render Dashboard](https://dashboard.render.com/) and click **New +** -> **Web Service**.
3. Select your repository (`CABBAGE_DISEASE_CLASSIFICATION_USING_TRANSFERE_LEARNING`).
4. Configure Deployment Settings:
   - **Root Directory**: `backend`
   - **Environment**: `Docker` or `Python 3`
   - **Build Command**: `pip install -r requirements.txt` (if using Native Python environment)
   - **Start Command**: `uvicorn app:app --host 0.0.0.0 --port $PORT`
5. Click **Create Web Service**.
6. Once deployed, copy your Render web service URL (e.g. `https://your-cabbage-api.onrender.com`).
7. Update `RENDER_API_URL` in `assets/cab.env` or `lib/services/tflite_service_web.dart` with your live URL!
